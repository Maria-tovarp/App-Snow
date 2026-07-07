import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;

import 'package:helloworld/core/storage/shared_preferences_session_storage.dart';

class LocalUser {
  final String id;
  final String email;
  final String nombre;

  const LocalUser(
      {required this.id, required this.email, required this.nombre});
}

class AuthResponse {
  final LocalUser? user;
  final LocalUser? session;

  const AuthResponse({this.user, this.session});
}

class AuthSessionService {
  AuthSessionService._();
  static final AuthSessionService instance = AuthSessionService._();

  final ValueNotifier<LocalUser?> sessionNotifier =
      ValueNotifier<LocalUser?>(null);
  final _sessionStorage = const SharedPreferencesSessionStorage();

  LocalUser? get currentUser =>
      sessionNotifier.value ??
      _fromSupabaseUser(Supabase.instance.client.auth.currentUser);
  bool get isLoggedIn => currentUser != null;

  LocalUser? _fromSupabaseUser(User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? <String, dynamic>{};
    return LocalUser(
      id: user.id,
      email: user.email ?? '',
      nombre: (meta['nombre'] ?? user.email ?? 'Usuario').toString(),
    );
  }

  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    final response = await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);
    final user = _fromSupabaseUser(response.user);
    if (response.session != null && response.user != null) {
      await _sessionStorage.saveSession(
          userId: response.user!.id,
          accessToken: response.session!.accessToken);
    }
    sessionNotifier.value = user;
    return AuthResponse(user: user, session: user);
  }

  Future<AuthResponse> signUp({
    required String nombre,
    required String identificacion,
    required String email,
    required String password,
    required String carrera,
    required String semestre,
    required String universidad,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nombre': nombre,
        'identificacion': identificacion,
        'carrera': carrera,
        'semestre': semestre,
        'universidad': universidad,
      },
    );
    final user = _fromSupabaseUser(response.user);
    if (response.session != null && response.user != null) {
      await _sessionStorage.saveSession(
          userId: response.user!.id,
          accessToken: response.session!.accessToken);
    }
    sessionNotifier.value = user;
    return AuthResponse(user: user, session: user);
  }

  Future<String> resetPassword(
      {required String email, required String identificacion}) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
    return 'Se envió un enlace de recuperación a $email';
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    await _sessionStorage.clearSession();
    sessionNotifier.value = null;
  }
}
