import 'package:supabase_flutter/supabase_flutter.dart';

class LocalDataStore {
  LocalDataStore._();
  static final LocalDataStore instance = LocalDataStore._();

  final SupabaseClient _client = Supabase.instance.client;

  final Map<String, dynamic> profile = {
    'nombre': 'Usuario',
    'identificacion': '',
    'carrera': '',
    'semestre': '',
    'universidad': '',
    'email': '',
  };

  Future<void> initialize() async {
    await _loadProfile();
  }

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    profile['email'] = user.email ?? '';
    final metadata = user.userMetadata ?? <String, dynamic>{};
    profile['nombre'] = (metadata['nombre'] ?? profile['nombre']).toString();
    profile['identificacion'] = (metadata['identificacion'] ?? profile['identificacion']).toString();
    profile['carrera'] = (metadata['carrera'] ?? profile['carrera']).toString();
    profile['semestre'] = (metadata['semestre'] ?? profile['semestre']).toString();
    profile['universidad'] = (metadata['universidad'] ?? profile['universidad']).toString();

    try {
      final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (row != null) {
        profile
          ..['nombre'] = (row['nombre'] ?? profile['nombre']).toString()
          ..['identificacion'] = (row['identificacion'] ?? profile['identificacion']).toString()
          ..['carrera'] = (row['carrera'] ?? profile['carrera']).toString()
          ..['semestre'] = (row['semestre'] ?? profile['semestre']).toString()
          ..['universidad'] = (row['universidad'] ?? profile['universidad']).toString()
          ..['email'] = (row['email'] ?? profile['email']).toString();
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _rows(dynamic response) => List<Map<String, dynamic>>.from(response as List);

  Future<List<Map<String, dynamic>>> getMaterias() async {
    final userId = _userId;
    if (userId == null) return [];
    final response = await _client.from('materias').select().eq('user_id', userId).order('created_at', ascending: false);
    return _rows(response);
  }

  Future<void> createMateria({required String nombre, required String profesor, required int creditos, required String color}) async {
    final userId = _userId;
    if (userId == null) throw Exception('No hay usuario autenticado');
    await _client.from('materias').insert({'nombre': nombre, 'profesor': profesor, 'creditos': creditos, 'color': color, 'user_id': userId});
  }

  Future<void> updateMateria(String id, Map<String, dynamic> data) async {
    await _client.from('materias').update(data).eq('id', id);
  }

  Future<void> deleteMateria(String id) async {
    await _client.from('tareas').update({'materia_id': null}).eq('materia_id', id);
    await _client.from('proyectos').update({'materia_id': null}).eq('materia_id', id);
    await _client.from('materias').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getTareas() async {
    final userId = _userId;
    if (userId == null) return [];
    final response = await _client.from('tareas').select('''
      id, titulo, descripcion, fecha_asignacion, fecha_vencimiento,
      duracion_estimada, tipo, prioridad, dificultad, estado,
      materia_id, user_id, materias(nombre)
    ''').eq('user_id', userId).order('created_at', ascending: false);
    return _rows(response).map((row) {
      final materia = row['materias'];
      return {...row, 'materia_nombre': materia is Map<String, dynamic> ? materia['nombre'] : null};
    }).toList();
  }

  Future<void> createTarea(Map<String, dynamic> tarea) async {
    final userId = _userId;
    if (userId == null) throw Exception('No hay usuario autenticado');
    await _client.from('tareas').insert({
      'titulo': tarea['titulo'],
      'descripcion': tarea['descripcion'],
      'fecha_vencimiento': tarea['fecha_vencimiento'],
      'duracion_estimada': tarea['duracion_estimada'] ?? 60,
      'tipo': tarea['tipo'] ?? 'tarea',
      'prioridad': tarea['prioridad'] ?? 'media',
      'dificultad': tarea['dificultad'] ?? 'media',
      'estado': tarea['estado'] ?? 'pendiente',
      'materia_id': tarea['materia_id'],
      'user_id': userId,
    });
  }

  Future<void> updateTarea(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)..remove('materia_nombre')..remove('materias');
    await _client.from('tareas').update(payload).eq('id', id);
  }

  Future<void> deleteTarea(String id) async {
    await _client.from('tareas').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getMetas() async {
    final userId = _userId;
    if (userId == null) return [];
    final response = await _client.from('metas').select().eq('user_id', userId).order('created_at', ascending: false);
    return _rows(response);
  }

  Future<void> createMeta({required String titulo, String? descripcion, String? periodo}) async {
    final userId = _userId;
    if (userId == null) throw Exception('No hay usuario autenticado');
    await _client.from('metas').insert({'titulo': titulo, 'descripcion': descripcion, 'periodo': periodo, 'estado': 'pendiente', 'user_id': userId});
  }

  Future<void> updateMeta(String id, Map<String, dynamic> data) async {
    await _client.from('metas').update(data).eq('id', id);
  }

  Future<void> deleteMeta(String id) async {
    await _client.from('metas').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getProyectos() async {
    final userId = _userId;
    if (userId == null) return [];
    final response = await _client.from('proyectos').select('''
      id, titulo, descripcion, materia_id, fecha_inicio, fecha_fin,
      avance_porcentual, user_id, materias(nombre)
    ''').eq('user_id', userId).order('created_at', ascending: false);
    return _rows(response).map((row) {
      final materia = row['materias'];
      return {...row, 'materia_nombre': materia is Map<String, dynamic> ? materia['nombre'] : null};
    }).toList();
  }

  Future<void> createProyecto(Map<String, dynamic> proyecto) async {
    final userId = _userId;
    if (userId == null) throw Exception('No hay usuario autenticado');
    await _client.from('proyectos').insert({
      'titulo': proyecto['titulo'],
      'descripcion': proyecto['descripcion'],
      'materia_id': proyecto['materia_id'],
      'fecha_inicio': proyecto['fecha_inicio'],
      'fecha_fin': proyecto['fecha_fin'],
      'avance_porcentual': proyecto['avance_porcentual'] ?? 0,
      'user_id': userId,
    });
  }

  Future<void> updateProyecto(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)..remove('materia_nombre')..remove('materias');
    await _client.from('proyectos').update(payload).eq('id', id);
  }

  Future<void> deleteProyecto(String id) async {
    await _client.from('proyectos').delete().eq('id', id);
  }

  Future<void> savePomodoroSession({required String tipo, required int duracionMinutos, String? materiaId}) async {
    final userId = _userId;
    if (userId == null) throw Exception('No hay usuario autenticado');
    await _client.from('pomodoro_sessions').insert({'user_id': userId, 'materia_id': materiaId, 'tipo': tipo, 'duracion_minutos': duracionMinutos, 'completada': true});
  }

  Future<Map<String, int>> getTodayPomodoroStats() async {
    final userId = _userId;
    if (userId == null) return {'sesionesEstudio': 0, 'minutosEstudio': 0};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    final response = await _client.from('pomodoro_sessions').select('tipo, duracion_minutos').eq('user_id', userId).gte('created_at', start).lte('created_at', end);
    int sesiones = 0;
    int minutos = 0;
    for (final row in _rows(response)) {
      if ((row['tipo'] ?? '').toString() == 'estudio') {
        sesiones++;
        minutos += (row['duracion_minutos'] ?? 0) as int;
      }
    }
    return {'sesionesEstudio': sesiones, 'minutosEstudio': minutos};
  }
}
