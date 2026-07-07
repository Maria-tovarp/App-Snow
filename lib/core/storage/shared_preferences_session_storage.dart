import 'package:shared_preferences/shared_preferences.dart';

import 'session_storage.dart';

class SharedPreferencesSessionStorage implements SessionStorage {
  static const _isLoggedInKey = 'is_logged_in';
  static const _userIdKey = 'user_id';
  static const _accessTokenKey = 'access_token';

  const SharedPreferencesSessionStorage();

  @override
  Future<void> saveSession(
      {required String userId, String? accessToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, userId);
    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString(_accessTokenKey, accessToken);
    }
  }

  @override
  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  @override
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_accessTokenKey);
  }
}
