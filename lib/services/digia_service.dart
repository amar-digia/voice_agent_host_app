import 'package:digia_engage/digia_engage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/app_message.dart';

/// Screen names reported to Digia, matched by screen-targeted campaigns.
class ScreenIds {
  ScreenIds._();

  static const home = 'home';
  static const markets = 'markets';
  static const portfolio = 'portfolio';
  static const orders = 'orders';
  static const account = 'account';
  static const kyc = 'kyc';
}

/// Shared by [MaterialApp] and [DigiaHost] so campaign actions can reach
/// the app's navigator.
final navigatorKey = GlobalKey<NavigatorState>();

/// Boots Digia Engage. Call [initialize] once in `main` before `runApp`.
///
/// No CEP plugin is registered, so only Digia rule campaigns show.
/// Override the key with `--dart-define=DIGIA_API_KEY=...` and
/// `--dart-define=DIGIA_ENVIRONMENT=production`.
class DigiaService {
  DigiaService._();

  // Defaults to medihub's Digia project (see medihub's cep_secrets.g.dart).
  static const _apiKey = String.fromEnvironment(
    'DIGIA_API_KEY',
    defaultValue: 'digia_b7d05bea973d4e138fd513ff5a081d46',
  );
  static const _environment = String.fromEnvironment(
    'DIGIA_ENVIRONMENT',
    defaultValue: 'sandbox',
  );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_apiKey.isEmpty) {
      debugPrint('[DigiaService] DIGIA_API_KEY not set; campaigns disabled');
    }

    await Digia.initialize(
      DigiaConfig(
        apiKey: _apiKey,
        logLevel: kDebugMode ? DigiaLogLevel.debug : DigiaLogLevel.error,
        environment: _environment == 'sandbox'
            ? DigiaEnvironment.sandbox
            : DigiaEnvironment.production,
        actionHandlers: DigiaActionHandlers(
          deepLink: (url) => _showMessage('Open $url'),
          openURL: (url) => _showMessage('Open $url'),
          customKV: (payload) async {
            final message =
                payload['toast'] ??
                payload['message'] ??
                payload.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            _showMessage(message);
          },
        ),
      ),
    );
  }

  static void _showMessage(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) showAppMessage(context, message);
  }
}
