import '../entities/tarea.dart';

abstract class TareaRepositoryPort {
  /// Obtener todas las tareas del usuario
  Future<List<Tarea>> getTareas();

  /// Crear una nueva tarea
  Future<void> createTarea({
    required String titulo,
    String? descripcion,
    required String fechaVencimiento,
    required int duracionEstimada,
    required String tipo,
    required String prioridad,
    required String dificultad,
    required String estado,
    String? materiaId,
  });

  /// Actualizar una tarea existente
  Future<void> updateTarea({
    required String id,
    required String titulo,
    String? descripcion,
    required String fechaVencimiento,
    required int duracionEstimada,
    required String tipo,
    required String prioridad,
    required String dificultad,
    String? materiaId,
  });

  /// Eliminar una tarea
  Future<void> deleteTarea(String id);

  /// Actualizar únicamente el estado
  Future<void> updateEstado({
    required String id,
    required String estado,
  });
}
