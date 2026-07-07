class Meta {
  final String id;
  final String titulo;
  final String? descripcion;
  final String? periodo;
  final String estado;
  final String userId;

  Meta({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.periodo,
    required this.estado,
    required this.userId,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      periodo: json['periodo'],
      estado: json['estado'] ?? 'pendiente',
      userId: json['user_id'],
    );
  }
}
