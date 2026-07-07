import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepositoryPort {
  Future<AuthResponse> signUp({
    required String nombre,
    required String identificacion,
    required String email,
    required String password,
    required String carrera,
    required String semestre,
    required String universidad,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<bool> hasStoredSession();
}
