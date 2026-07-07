import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:helloworld/features/materias/data/materia_model.dart';

import 'package:helloworld/features/materias/domain/repositories/materia_repository_port.dart';
class MateriaRepository implements MateriaRepositoryPort {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MateriaModel>> getMaterias() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('materias')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => MateriaModel.fromJson(e)).toList();
  }

  Future<void> createMateria({
    required String nombre,
    required String profesor,
    required int creditos,
    required String color,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client.from('materias').insert({
      'nombre': nombre,
      'profesor': profesor,
      'creditos': creditos,
      'color': color,
      'user_id': user.id,
    });
  }

  Future<void> deleteMateria(String id) async {
    await _client.from('materias').delete().eq('id', id);
  }
}
