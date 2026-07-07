import '../entities/tarea.dart';

abstract class TareaRepositoryPort {
  Future<List<Tarea>> getTareas();
  Future<void> createTarea({
    required String titulo,
    String? descripcion,
    required String fechaAsignacion,
    String? fechaVencimiento,
    required int duracionEstimada,
    required String tipo,
    required String prioridad,
    required String dificultad,
    required String estado,
    String? materiaId,
  });
  Future<void> updateTarea({
    required String id,
    required String titulo,
    String? descripcion,
    String? fechaVencimiento,
    required String tipo,
    required String prioridad,
    required String dificultad,
    String? materiaId,
  });
  Future<void> deleteTarea(String id);
  Future<void> updateEstado({required String id, required String estado});
}
