import '../repositories/auth_repository_port.dart';

class SignOutUser {
  final AuthRepositoryPort repository;

  const SignOutUser(this.repository);

  Future<void> call() => repository.signOut();
}
