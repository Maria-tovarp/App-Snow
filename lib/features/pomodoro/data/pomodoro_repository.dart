import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:helloworld/features/pomodoro/domain/repositories/pomodoro_repository_port.dart';

class PomodoroRepository implements PomodoroRepositoryPort {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveSession({
    required String tipo,
    required int duracionMinutos,
    String? materiaId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _client.from('pomodoro_sessions').insert({
      'user_id': user.id,
      'materia_id': materiaId,
      'tipo': tipo,
      'duracion_minutos': duracionMinutos,
      'completada': true,
    });
  }

  Future<Map<String, int>> getTodayStats() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {
        'sesionesEstudio': 0,
        'minutosEstudio': 0,
      };
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end =
        DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final response = await _client
        .from('pomodoro_sessions')
        .select('tipo, duracion_minutos')
        .eq('user_id', user.id)
        .gte('created_at', start)
        .lte('created_at', end);

    final rows = List<Map<String, dynamic>>.from(response);

    int sesionesEstudio = 0;
    int minutosEstudio = 0;

    for (final row in rows) {
      final tipo = (row['tipo'] ?? '').toString();
      final minutos = (row['duracion_minutos'] ?? 0) as int;

      if (tipo == 'estudio') {
        sesionesEstudio++;
        minutosEstudio += minutos;
      }
    }

    return {
      'sesionesEstudio': sesionesEstudio,
      'minutosEstudio': minutosEstudio,
    };
  }

  Future<Map<String, int>> getWeekStats() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {};
    }

    final now = DateTime.now();

    // Lunes de la semana actual
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final response = await _client
        .from('pomodoro_sessions')
        .select('created_at, tipo, duracion_minutos')
        .eq('user_id', user.id)
        .gte('created_at', startOfWeek.toIso8601String());

    final rows = List<Map<String, dynamic>>.from(response);

    final Map<String, int> week = {
      'Lun': 0,
      'Mar': 0,
      'Mié': 0,
      'Jue': 0,
      'Vie': 0,
      'Sáb': 0,
      'Dom': 0,
    };

    for (final row in rows) {
      if (row['tipo'] != 'estudio') continue;

      final fecha = DateTime.parse(row['created_at']);
      final minutos = (row['duracion_minutos'] ?? 0) as int;

      switch (fecha.weekday) {
        case DateTime.monday:
          week['Lun'] = week['Lun']! + minutos;
          break;
        case DateTime.tuesday:
          week['Mar'] = week['Mar']! + minutos;
          break;
        case DateTime.wednesday:
          week['Mié'] = week['Mié']! + minutos;
          break;
        case DateTime.thursday:
          week['Jue'] = week['Jue']! + minutos;
          break;
        case DateTime.friday:
          week['Vie'] = week['Vie']! + minutos;
          break;
        case DateTime.saturday:
          week['Sáb'] = week['Sáb']! + minutos;
          break;
        case DateTime.sunday:
          week['Dom'] = week['Dom']! + minutos;
          break;
      }
    }

    return week;
  }
}
