class HorarioModel {
  const HorarioModel({
    required this.id,
    required this.materiaId,
    required this.materiaNombre,
    required this.profesor,
    required this.color,
    required this.salon,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
  });

  final String id;
  final String materiaId;
  final String materiaNombre;
  final String profesor;
  final int color;
  final String salon;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;

  factory HorarioModel.fromJson(Map<String, dynamic> json) {
    final materia = json['materias'];
    return HorarioModel(
      id: json['id'].toString(),
      materiaId: json['materia_id'].toString(),
      materiaNombre: materia is Map
          ? (materia['nombre'] ?? 'Sin materia').toString()
          : 'Sin materia',
      profesor: materia is Map && materia['profesor'] != null
          ? materia['profesor'].toString()
          : (json['profesor'] ?? '').toString(),
      color: _colorValue(
        materia is Map ? materia['color'] : null,
      ),
      salon: (json['salon'] ?? '').toString(),
      diaSemana: (json['dia_semana'] ?? 1) as int,
      horaInicio: _shortTime(json['hora_inicio']),
      horaFin: _shortTime(json['hora_fin']),
    );
  }

  static String _shortTime(dynamic value) {
    final text = (value ?? '').toString();
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  static int _colorValue(dynamic value) {
    if (value is int) return value;
    final text = (value ?? '').toString().trim();
    if (text.startsWith('#')) {
      return int.tryParse('FF${text.substring(1)}', radix: 16) ?? 0xFF5B4CF0;
    }
    return int.tryParse(text) ?? 0xFF5B4CF0;
  }
}
