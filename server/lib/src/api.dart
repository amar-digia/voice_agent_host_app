import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'conversation_service.dart';

const _userKey = 'agent_server.user_id';
const maxBodyBytes = 256 * 1024;

/// Builds the HTTP handler: CORS, logging, auth, rate limits, then routes.
Handler buildHandler(
  ServerConfig config,
  ConversationService service, {
  DateTime Function()? clock,
  void Function(String line)? log,
}) {
  final now = clock ?? DateTime.now;
  final router = Router()
    ..get('/healthz', (Request _) => _json(200, {'status': 'ok'}))
    ..post('/v1/conversations', (Request request) {
      final id = service.create(_user(request));
      return _json(201, {'conversation_id': id});
    })
    ..post('/v1/conversations/<id>/messages', (
      Request request,
      String id,
    ) async {
      final body = await _readJson(request);
      final user = _user(request);
      final AgentStep step;
      switch (body['type']) {
        case 'user_text':
          final text = body['text'];
          if (text is! String) {
            throw ServiceException(
              400,
              'invalid_text',
              '"text" must be a string.',
            );
          }
          step = await service.sendUserText(user, id, text, body['screen']);
        case 'tool_results':
          step = await service.sendToolResults(user, id, body['results']);
        default:
          throw ServiceException(
            400,
            'invalid_type',
            '"type" must be user_text or tool_results.',
          );
      }
      return _json(200, step.toJson());
    })
    ..post('/v1/conversations/<id>/cancel', (Request request, String id) {
      service.cancel(_user(request), id);
      return _json(200, {'status': 'cancelled'});
    });

  return const Pipeline()
      .addMiddleware(_cors(config.allowedOrigins))
      .addMiddleware(_logRequests(now, log ?? print))
      .addMiddleware(_errors())
      .addMiddleware(_authenticate(config.userTokens))
      .addMiddleware(_rateLimit(config.requestsPerMinute, now))
      .addHandler(router.call);
}

String _user(Request request) => request.context[_userKey] as String;

Response _json(int status, Object body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

Future<Map<String, dynamic>> _readJson(Request request) async {
  final length = request.contentLength;
  if (length != null && length > maxBodyBytes) {
    throw ServiceException(413, 'body_too_large', 'Request body is too large.');
  }
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > maxBodyBytes) {
      throw ServiceException(
        413,
        'body_too_large',
        'Request body is too large.',
      );
    }
  }
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    // Falls through to the error below.
  }
  throw ServiceException(400, 'invalid_json', 'Body must be a JSON object.');
}

Middleware _errors() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on ServiceException catch (e) {
        return _json(e.statusCode, {
          'error': {'code': e.code, 'message': e.message},
        });
      }
    };

/// Development auth: static bearer tokens from APP_USER_TOKENS.
/// Replace with your identity provider's token verification in production.
Middleware _authenticate(Map<String, String> tokens) =>
    (inner) => (request) {
      if (request.url.path == 'healthz') return inner(request);
      final header = request.headers['authorization'] ?? '';
      final token = header.startsWith('Bearer ') ? header.substring(7) : '';
      String? user;
      for (final entry in tokens.entries) {
        if (_constantTimeEquals(entry.key, token)) user = entry.value;
      }
      if (user == null) {
        return _json(401, {
          'error': {
            'code': 'unauthorized',
            'message': 'Missing or invalid token.',
          },
        });
      }
      return inner(request.change(context: {_userKey: user}));
    };

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// A fixed one-minute window per user.
Middleware _rateLimit(int perMinute, DateTime Function() now) {
  final windows = <String, ({DateTime start, int count})>{};
  return (inner) => (request) {
    final user = request.context[_userKey] as String?;
    if (user == null) return inner(request);
    final current = now();
    var window = windows[user];
    if (window == null || current.difference(window.start).inSeconds >= 60) {
      window = (start: current, count: 0);
    }
    if (window.count >= perMinute) {
      return _json(429, {
        'error': {
          'code': 'rate_limited',
          'message': 'Too many requests. Slow down.',
        },
      });
    }
    windows[user] = (start: window.start, count: window.count + 1);
    return inner(request);
  };
}

Middleware _cors(List<String> allowedOrigins) {
  Map<String, String> headersFor(String? origin) {
    final allowAll = allowedOrigins.contains('*');
    if (origin == null || (!allowAll && !allowedOrigins.contains(origin))) {
      return {};
    }
    return {
      'access-control-allow-origin': allowAll ? '*' : origin,
      'access-control-allow-methods': 'GET, POST, OPTIONS',
      'access-control-allow-headers': 'authorization, content-type',
      'access-control-max-age': '600',
      'vary': 'origin',
    };
  }

  return (inner) => (request) async {
    final headers = headersFor(request.headers['origin']);
    if (request.method == 'OPTIONS') return Response(204, headers: headers);
    final response = await inner(request);
    return response.change(headers: headers);
  };
}

/// Logs method, path, status, user and latency. Never bodies or headers,
/// which carry tokens and personal details.
Middleware _logRequests(DateTime Function() now, void Function(String) log) =>
    (inner) => (request) async {
      final started = now();
      final response = await inner(request);
      final path = request.url.path.replaceAll(
        RegExp(r'conversations/[^/]+'),
        'conversations/:id',
      );
      log(
        '${request.method} /$path ${response.statusCode} '
        '${now().difference(started).inMilliseconds}ms',
      );
      return response;
    };
