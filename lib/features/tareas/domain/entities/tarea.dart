class Tarea {
  final String id;
  final String titulo;
  final String? descripcion;
  final String? fechaVencimiento;
  final int duracionEstimada;
  final String tipo;
  final String prioridad;
  final String dificultad;
  final String estado;
  final String? materiaId;
  final String? materiaNombre;
  final String userId;

  Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.fechaVencimiento,
    required this.duracionEstimada,
    required this.tipo,
    required this.prioridad,
    required this.dificultad,
    required this.estado,
    this.materiaId,
    this.materiaNombre,
    required this.userId,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    final materia = json['materias'];

    return Tarea(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      fechaVencimiento: json['fecha_vencimiento']?.toString(),
      duracionEstimada: (json['duracion_estimada'] as num?)?.toInt() ?? 60,
      tipo: (json['tipo'] ?? 'tarea') as String,
      prioridad: (json['prioridad'] ?? 'media') as String,
      dificultad: (json['dificultad'] ?? 'media') as String,
      estado: (json['estado'] ?? 'pendiente') as String,
      materiaId: json['materia_id'] as String?,
      materiaNombre:
          materia is Map<String, dynamic> ? materia['nombre'] as String? : null,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_vencimiento': fechaVencimiento,
      'duracion_estimada': duracionEstimada,
      'tipo': tipo,
      'prioridad': prioridad,
      'dificultad': dificultad,
      'estado': estado,
      'materia_id': materiaId,
      'user_id': userId,
    };
  }

  Tarea copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? fechaVencimiento,
    int? duracionEstimada,
    String? tipo,
    String? prioridad,
    String? dificultad,
    String? estado,
    String? materiaId,
    String? materiaNombre,
    String? userId,
  }) {
    return Tarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      duracionEstimada: duracionEstimada ?? this.duracionEstimada,
      tipo: tipo ?? this.tipo,
      prioridad: prioridad ?? this.prioridad,
      dificultad: dificultad ?? this.dificultad,
      estado: estado ?? this.estado,
      materiaId: materiaId ?? this.materiaId,
      materiaNombre: materiaNombre ?? this.materiaNombre,
      userId: userId ?? this.userId,
    );
  }
}
