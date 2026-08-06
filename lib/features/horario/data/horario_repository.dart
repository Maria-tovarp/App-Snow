import 'package:supabase_flutter/supabase_flutter.dart';

import 'horario_model.dart';

class HorarioRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HorarioModel>> getHorarios() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('horarios')
        .select('''
          id, materia_id, profesor, salon, dia_semana, hora_inicio, hora_fin,
          materias(nombre, profesor, color)
        ''')
        .eq('user_id', user.id)
        .order('dia_semana')
        .order('hora_inicio');

    return List<Map<String, dynamic>>.from(response)
        .map(HorarioModel.fromJson)
        .toList();
  }

  Future<void> createHorario({
    required String materiaId,
    required String profesor,
    required String salon,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    await _client.from('horarios').insert({
      'user_id': user.id,
      'materia_id': materiaId,
      'profesor': profesor,
      'salon': salon,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    });
  }

  Future<void> updateHorario({
    required String id,
    required String materiaId,
    required String profesor,
    required String salon,
    required int diaSemana,
    required String horaInicio,
    required String horaFin,
  }) async {
    await _client.from('horarios').update({
      'materia_id': materiaId,
      'profesor': profesor,
      'salon': salon,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
    }).eq('id', id);
  }

  Future<void> deleteHorario(String id) async {
    await _client.from('horarios').delete().eq('id', id);
  }
}
