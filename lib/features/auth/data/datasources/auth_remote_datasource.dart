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
  }) async {
    // Crear usuario en Supabase Auth
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nombre': nombre,
      },
    );

    final user = response.user;

    // Si el usuario fue creado, guardar su perfil
    if (user != null) {
      await client.from('profiles').insert({
        'id': user.id,
        'nombre': nombre,
        'identificacion': int.parse(identificacion),
        'correo_electronico': email,
        'carrera': carrera,
        'semestre': int.parse(semestre),
        'universidad': universidad,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}