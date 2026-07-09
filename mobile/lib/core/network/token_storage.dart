import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> getToken() async => _prefs.getString(_accessKey);

  Future<String?> getRefreshToken() async => _prefs.getString(_refreshKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessKey, accessToken);
    await _prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}
