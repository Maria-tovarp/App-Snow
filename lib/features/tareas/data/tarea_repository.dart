import 'package:supabase_flutter/supabase_flutter.dart';

import 'tarea_model.dart';
import 'package:helloworld/features/tareas/domain/repositories/tarea_repository_port.dart';

class TareaRepository implements TareaRepositoryPort {
  final SupabaseClient _client = Supabase.instance.client;

  /// ==========================================
  /// MATERIAS
  /// ==========================================

  Future<List<Map<String, dynamic>>> getMaterias() async {
    final user = _client.auth.currentUser;

    if (user == null) return [];

    final response = await _client
        .from('materias')
        .select('id,nombre')
        .eq('user_id', user.id)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// ==========================================
  /// TAREAS
  /// ==========================================

  @override
  Future<List<TareaModel>> getTareas() async {
    final user = _client.auth.currentUser;

    if (user == null) return [];

    final response = await _client.from('tareas').select('''
          id,
          titulo,
          descripcion,
          fecha_vencimiento,
          duracion_estimada,
          tipo,
          prioridad,
          dificultad,
          estado,
          materia_id,
          user_id,
          materias!tareas_materia_id_fkey(nombre)
        ''').eq('user_id', user.id).order('created_at', ascending: false);

    return (response as List).map((e) => TareaModel.fromJson(e)).toList();
  }

  @override
  Future<void> createTarea({
    required String titulo,
    String? descripcion,
    required String fechaVencimiento,
    required int duracionEstimada,
    required String tipo,
    required String prioridad,
    required String dificultad,
    required String estado,
    String? materiaId,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client.from('tareas').insert({
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_vencimiento': fechaVencimiento,
      'duracion_estimada': duracionEstimada,
      'tipo': tipo,
      'prioridad': prioridad,
      'dificultad': dificultad,
      'estado': estado,
      'materia_id': materiaId,
      'user_id': user.id,
    });
  }

  @override
  Future<void> updateTarea({
    required String id,
    required String titulo,
    String? descripcion,
    required String fechaVencimiento,
    required int duracionEstimada,
    required String tipo,
    required String prioridad,
    required String dificultad,
    String? materiaId,
  }) async {
    await _client.from('tareas').update({
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_vencimiento': fechaVencimiento,
      'duracion_estimada': duracionEstimada,
      'tipo': tipo,
      'prioridad': prioridad,
      'dificultad': dificultad,
      'materia_id': materiaId,
    }).eq('id', id);
  }

  @override
  Future<void> deleteTarea(String id) async {
    await _client.from('tareas').delete().eq('id', id);
  }

  @override
  Future<void> updateEstado({
    required String id,
    required String estado,
  }) async {
    await _client.from('tareas').update({
      'estado': estado,
    }).eq('id', id);
  }
}
