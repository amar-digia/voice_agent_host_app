class ConfigException implements Exception {
  ConfigException(this.message);
  final String message;

  @override
  String toString() => 'Configuration error: $message';
}

/// Server settings, read from environment variables (see `.env.example`).
class ServerConfig {
  ServerConfig({
    required this.anthropicApiKey,
    this.anthropicBaseUrl = 'https://api.anthropic.com',
    this.model = 'claude-opus-5-5',
    this.effort = 'low',
    this.enableFallbacks = true,
    this.maxToolIterations = 20,
    this.host = '127.0.0.1',
    this.port = 8080,
    required this.userTokens,
    this.allowedOrigins = const ['*'],
    this.conversationTtl = const Duration(minutes: 30),
    this.requestsPerMinute = 60,
  });

  factory ServerConfig.fromEnvironment(Map<String, String> env) {
    String? read(String key) {
      final value = env[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    int readInt(String key, int fallback) {
      final raw = read(key);
      if (raw == null) return fallback;
      final value = int.tryParse(raw);
      if (value == null || value <= 0) {
        throw ConfigException('$key must be a positive integer.');
      }
      return value;
    }

    final apiKey = read('ANTHROPIC_API_KEY');
    if (apiKey == null) {
      throw ConfigException(
        'ANTHROPIC_API_KEY is not set. Create a key in the Claude Console '
        '(platform.claude.com) and export it before starting the server.',
      );
    }

    final effort = read('CLAUDE_EFFORT') ?? 'low';
    const efforts = {'low', 'medium', 'high', 'xhigh', 'max'};
    if (!efforts.contains(effort)) {
      throw ConfigException(
        'CLAUDE_EFFORT must be one of ${efforts.join(', ')}.',
      );
    }

    return ServerConfig(
      anthropicApiKey: apiKey,
      anthropicBaseUrl:
          read('ANTHROPIC_BASE_URL') ?? 'https://api.anthropic.com',
      model: read('CLAUDE_MODEL') ?? 'claude-opus-5-5',
      effort: effort,
      enableFallbacks: read('CLAUDE_ENABLE_FALLBACKS') != 'false',
      maxToolIterations: readInt('MAX_TOOL_ITERATIONS', 20),
      host: read('HOST') ?? '127.0.0.1',
      port: readInt('PORT', 8080),
      userTokens: parseUserTokens(read('APP_USER_TOKENS')),
      allowedOrigins: (read('CORS_ALLOWED_ORIGINS') ?? '*')
          .split(',')
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList(),
      conversationTtl: Duration(
        minutes: readInt('CONVERSATION_TTL_MINUTES', 30),
      ),
      requestsPerMinute: readInt('REQUESTS_PER_MINUTE', 60),
    );
  }

  /// Parses `user1:token1,user2:token2` into a token -> user id map.
  static Map<String, String> parseUserTokens(String? raw) {
    if (raw == null) {
      throw ConfigException(
        'APP_USER_TOKENS is not set. For development use e.g. '
        'APP_USER_TOKENS=demo-user:<a long random string>.',
      );
    }
    final tokens = <String, String>{};
    for (final pair in raw.split(',')) {
      final parts = pair.trim().split(':');
      if (parts.length != 2 || parts[0].isEmpty || parts[1].length < 16) {
        throw ConfigException(
          'APP_USER_TOKENS entries must look like user:token, with tokens of '
          'at least 16 characters.',
        );
      }
      tokens[parts[1]] = parts[0];
    }
    return tokens;
  }

  final String anthropicApiKey;
  final String anthropicBaseUrl;
  final String model;
  final String effort;
  final bool enableFallbacks;
  final int maxToolIterations;
  final String host;
  final int port;
  final Map<String, String> userTokens;
  final List<String> allowedOrigins;
  final Duration conversationTtl;
  final int requestsPerMinute;
}
