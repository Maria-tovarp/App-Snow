class Proyecto {
  final String id;
  final String titulo;
  final String? descripcion;
  final String? materiaId;
  final String? materiaNombre;
  final String? fechaInicio;
  final String? fechaFin;
  final int avancePorcentual;
  final String userId;

  Proyecto({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.materiaId,
    this.materiaNombre,
    this.fechaInicio,
    this.fechaFin,
    required this.avancePorcentual,
    required this.userId,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    final materia = json['materias'];

    return Proyecto(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      materiaId: json['materia_id'] as String?,
      materiaNombre:
          materia is Map<String, dynamic> ? materia['nombre'] as String? : null,
      fechaInicio: json['fecha_inicio']?.toString(),
      fechaFin: json['fecha_fin']?.toString(),
      avancePorcentual: (json['avance_porcentual'] ?? 0) as int,
      userId: json['user_id'] as String,
    );
  }
}
