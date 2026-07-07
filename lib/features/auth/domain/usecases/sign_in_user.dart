import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository_port.dart';

class SignInUser {
  final AuthRepositoryPort repository;

  const SignInUser(this.repository);

  Future<AuthResponse> call({required String email, required String password}) {
    return repository.signIn(email: email, password: password);
  }
}
