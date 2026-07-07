abstract class SessionStorage {
  Future<void> saveSession({required String userId, String? accessToken});
  Future<bool> hasSession();
  Future<String?> getUserId();
  Future<String?> getAccessToken();
  Future<void> clearSession();
}
