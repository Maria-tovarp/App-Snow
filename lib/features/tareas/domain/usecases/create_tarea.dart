import '../repositories/tarea_repository_port.dart';

class CreateTarea {
  final TareaRepositoryPort repository;

  const CreateTarea(this.repository);

  Future<void> call({
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
  }) {
    return repository.createTarea(
      titulo: titulo,
      descripcion: descripcion,
      fechaAsignacion: fechaAsignacion,
      fechaVencimiento: fechaVencimiento,
      duracionEstimada: duracionEstimada,
      tipo: tipo,
      prioridad: prioridad,
      dificultad: dificultad,
      estado: estado,
      materiaId: materiaId,
    );
  }
}
