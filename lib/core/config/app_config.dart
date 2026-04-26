import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _baseUrlFromEnv = String.fromEnvironment('BASE_URL');

  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) {
      return _baseUrlFromEnv;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'https://reader-api.fevirtus.dev';
    }

    return 'http://localhost:8000';
  }

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
