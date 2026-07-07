class Materia {
  final String id;
  final String nombre;
  final String? profesor;
  final int? creditos;
  final String? color;
  final String userId;

  Materia({
    required this.id,
    required this.nombre,
    required this.userId,
    this.profesor,
    this.creditos,
    this.color,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      profesor: json['profesor'] as String?,
      creditos: json['creditos'] as int?,
      color: json['color'] as String?,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'profesor': profesor,
      'creditos': creditos,
      'color': color,
      'user_id': userId,
    };
  }
}
