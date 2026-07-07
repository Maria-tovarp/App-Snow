import 'package:supabase_flutter/supabase_flutter.dart';

import 'proyecto_model.dart';

import 'package:helloworld/features/proyectos/domain/repositories/proyecto_repository_port.dart';

class ProyectoRepository implements ProyectoRepositoryPort {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProyectoModel>> getProyectos() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client.from('proyectos').select('''
          id,
          titulo,
          descripcion,
          materia_id,
          fecha_inicio,
          fecha_fin,
          avance_porcentual,
          user_id,
          materias(nombre)
        ''').eq('user_id', user.id).order('created_at', ascending: false);

    return (response as List).map((e) => ProyectoModel.fromJson(e)).toList();
  }

  Future<void> createProyecto({
    required String titulo,
    String? descripcion,
    String? materiaId,
    String? fechaInicio,
    String? fechaFin,
    required int avancePorcentual,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client.from('proyectos').insert({
      'titulo': titulo,
      'descripcion': descripcion,
      'materia_id': materiaId,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'avance_porcentual': avancePorcentual,
      'user_id': user.id,
    });
  }

  Future<void> updateProyecto({
    required String id,
    required String titulo,
    String? descripcion,
    String? materiaId,
    String? fechaInicio,
    String? fechaFin,
    required int avancePorcentual,
  }) async {
    await _client.from('proyectos').update({
      'titulo': titulo,
      'descripcion': descripcion,
      'materia_id': materiaId,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'avance_porcentual': avancePorcentual,
    }).eq('id', id);
  }

  Future<void> updateAvance({
    required String id,
    required int avancePorcentual,
  }) async {
    await _client.from('proyectos').update({
      'avance_porcentual': avancePorcentual,
    }).eq('id', id);
  }

  Future<void> deleteProyecto(String id) async {
    await _client.from('proyectos').delete().eq('id', id);
  }
}
