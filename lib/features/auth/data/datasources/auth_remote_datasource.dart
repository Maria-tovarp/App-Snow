import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient client;

  const AuthRemoteDataSource(this.client);

  Future<AuthResponse> signUp({
    required String nombre,
    required String identificacion,
    required String email,
    required String password,
    required String carrera,
    required String semestre,
    required String universidad,
  }) {
    return client.auth.signUp(
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
  }

  Future<AuthResponse> signIn(
      {required String email, required String password}) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) {
    return client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => client.auth.signOut();
}
