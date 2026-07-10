import 'package:flutter/foundation.dart';

class AppEnv {
  AppEnv._();

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl.endsWith('/')
          ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1)
          : _apiBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5003';
    }
    return 'http://localhost:5003';
  }

  /// Public GitHub `owner/repo` used to check releases for in-app updates.
  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: 'solendav/PurchaseJournal-apk',
  );
}
