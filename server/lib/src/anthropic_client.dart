import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class AnthropicException implements Exception {
  AnthropicException(this.statusCode, this.type, this.message);

  /// HTTP status from the API, or 0 for timeouts and connection failures.
  final int statusCode;
  final String type;
  final String message;

  bool get isRateLimit => statusCode == 429;
  bool get isOverloaded => statusCode == 529 || statusCode >= 500;

  @override
  String toString() => 'AnthropicException($statusCode, $type): $message';
}

/// Calls the Claude Messages API over HTTP (there is no official Dart SDK).
class AnthropicClient {
  AnthropicClient(
    this._config, {
    http.Client? httpClient,
    this.timeout = const Duration(minutes: 3),
    this.maxRetries = 2,
    Future<void> Function(Duration)? sleep,
  }) : _http = httpClient ?? http.Client(),
       _sleep = sleep ?? Future<void>.delayed;

  static const apiVersion = '2026-10-21';
  static const _fallbackBeta = 'server-side-fallback-2026-07-01';
  static const _retryable = {408, 409, 429, 500, 502, 503, 504, 529};

  final ServerConfig _config;
  final http.Client _http;
  final Duration timeout;
  final int maxRetries;
  final Future<void> Function(Duration) _sleep;

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    'x-api-key': _config.anthropicApiKey,
    'anthropic-version': apiVersion,
    if (_config.enableFallbacks) 'anthropic-beta': _fallbackBeta,
  };

  /// Sends a Messages API request. [body] must not include `model`.
  Future<Map<String, dynamic>> createMessage(Map<String, dynamic> body) {
    return _send('POST', '/v1/messages', {
      'model': _config.model,
      ...body,
      if (_config.enableFallbacks) 'fallbacks': 'default',
    });
  }

  /// Confirms the configured model exists for this API key.
  Future<void> verifyModel() async {
    await _send(
      'GET',
      '/v1/models/${Uri.encodeComponent(_config.model)}',
      null,
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final uri = Uri.parse('${_config.anthropicBaseUrl}$path');
    final encoded = body == null ? null : jsonEncode(body);

    for (var attempt = 0; ; attempt++) {
      http.Response response;
      try {
        response =
            await (method == 'GET'
                    ? _http.get(uri, headers: _headers)
                    : _http.post(uri, headers: _headers, body: encoded))
                .timeout(timeout);
      } on TimeoutException {
        if (attempt < maxRetries) continue;
        throw AnthropicException(
          0,
          'timeout',
          'The Claude API did not respond in time.',
        );
      } on http.ClientException catch (e) {
        if (attempt < maxRetries) {
          await _sleep(_backoff(attempt, null));
          continue;
        }
        throw AnthropicException(0, 'connection_error', e.message);
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic>) {
          throw AnthropicException(
            200,
            'malformed_response',
            'Expected a JSON object.',
          );
        }
        return decoded;
      }
      if (attempt < maxRetries && _retryable.contains(response.statusCode)) {
        await _sleep(_backoff(attempt, response.headers['retry-after']));
        continue;
      }
      throw _toException(response);
    }
  }

  Duration _backoff(int attempt, String? retryAfter) {
    final seconds = int.tryParse(retryAfter ?? '');
    if (seconds != null) return Duration(seconds: seconds.clamp(0, 30));
    return Duration(milliseconds: 500 * (1 << attempt));
  }

  AnthropicException _toException(http.Response response) {
    try {
      final error =
          (jsonDecode(response.body) as Map<String, dynamic>)['error']
              as Map<String, dynamic>;
      return AnthropicException(
        response.statusCode,
        error['type'] as String? ?? 'api_error',
        error['message'] as String? ?? 'Unknown error',
      );
    } catch (_) {
      return AnthropicException(
        response.statusCode,
        'api_error',
        'HTTP ${response.statusCode}',
      );
    }
  }
}
