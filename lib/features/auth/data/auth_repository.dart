import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:helloworld/core/network/supabase_client_provider.dart';
import 'package:helloworld/core/storage/session_storage.dart';
import 'package:helloworld/core/storage/shared_preferences_session_storage.dart';
import 'package:helloworld/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:helloworld/features/auth/domain/repositories/auth_repository_port.dart';

class AuthRepository implements AuthRepositoryPort {
  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    SessionStorage? sessionStorage,
  })  : _remoteDataSource = remoteDataSource ??
            AuthRemoteDataSource(SupabaseClientProvider.client),
        _sessionStorage =
            sessionStorage ?? const SharedPreferencesSessionStorage();

  @override
  Future<AuthResponse> signUp({
    required String nombre,
    required String identificacion,
    required String email,
    required String password,
    required String carrera,
    required String semestre,
    required String universidad,
  }) async {
    final response = await _remoteDataSource.signUp(
      nombre: nombre,
      identificacion: identificacion,
      email: email,
      password: password,
      carrera: carrera,
      semestre: semestre,
      universidad: universidad,
    );

    final session = response.session;
    final user = response.user;
    if (session != null && user != null) {
      await _sessionStorage.saveSession(
        userId: user.id,
        accessToken: session.accessToken,
      );
    }

    return response;
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response =
        await _remoteDataSource.signIn(email: email, password: password);
    final session = response.session;
    final user = response.user;
    if (session != null && user != null) {
      await _sessionStorage.saveSession(
        userId: user.id,
        accessToken: session.accessToken,
      );
    }
    return response;
  }

  @override
  Future<void> resetPassword(String email) {
    return _remoteDataSource.resetPassword(email);
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    await _sessionStorage.clearSession();
  }

  @override
  Future<bool> hasStoredSession() => _sessionStorage.hasSession();
}
