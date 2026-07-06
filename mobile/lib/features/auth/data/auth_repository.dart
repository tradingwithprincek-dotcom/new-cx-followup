import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

enum UserRole { salesExec, storeManager, admin }

UserRole roleFromString(String raw) {
  switch (raw) {
    case 'SALES_EXEC':
      return UserRole.salesExec;
    case 'STORE_MANAGER':
      return UserRole.storeManager;
    case 'ADMIN':
      return UserRole.admin;
    default:
      throw ArgumentError('Unknown role: $raw');
  }
}

class AuthRepository {
  AuthRepository(this._apiClient);
  final ApiClient _apiClient;
  final _tokenStorage = TokenStorage();

  /// One login call for all three portals — the backend returns the user's
  /// role, and the app routes to the matching shell. There's no separate
  /// "manager password check" vs "exec password check"; the role itself
  /// determines which screens are even reachable afterward.
  Future<UserRole> login({required String email, required String password}) async {
    final response = await _apiClient.dio.post(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data;
    await _tokenStorage.saveSession(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
      role: data['user']['role'],
    );
    return roleFromString(data['user']['role'] as String);
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken != null) {
      try {
        await _apiClient.dio.post('/api/v1/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // best-effort; clear local session regardless
      }
    }
    await _tokenStorage.clear();
  }
}
