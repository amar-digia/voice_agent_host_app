import 'dart:io';

import 'package:agent_server/agent_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final ServerConfig config;
  try {
    config = ServerConfig.fromEnvironment(Platform.environment);
  } on ConfigException catch (e) {
    stderr.writeln(e);
    exit(78);
  }

  final claude = AnthropicClient(config);
  try {
    await claude.verifyModel();
  } on AnthropicException catch (e) {
    stderr.writeln(
      'Could not use model "${config.model}" (${e.statusCode} ${e.type}): '
      '${e.message}\nCheck CLAUDE_MODEL and ANTHROPIC_API_KEY.',
    );
    exit(78);
  }

  final handler = buildHandler(config, ConversationService(config, claude));
  final server = await shelf_io.serve(handler, config.host, config.port);
  stdout.writeln(
    'Agent server on http://${server.address.host}:${server.port} '
    'using ${config.model}',
  );
}
