import '../entities/proyecto.dart';

abstract class ProyectoRepositoryPort {
  Future<List<Proyecto>> getProyectos();
  Future<void> createProyecto({
    required String titulo,
    String? descripcion,
    String? materiaId,
    String? fechaInicio,
    String? fechaFin,
    required int avancePorcentual,
  });
  Future<void> updateProyecto({
    required String id,
    required String titulo,
    String? descripcion,
    String? materiaId,
    String? fechaInicio,
    String? fechaFin,
    required int avancePorcentual,
  });
  Future<void> updateAvance({required String id, required int avancePorcentual});
  Future<void> deleteProyecto(String id);
}
