import '../repositories/tarea_repository_port.dart';

class CreateTarea {
  final TareaRepositoryPort repository;

  CreateTarea(this.repository);

  Future<void> call({
    required String titulo,
    String? descripcion,
    String? fechaVencimiento,
    required String tipo,
    required String prioridad,
    required String dificultad,
    required String estado,
    String? materiaId,
  }) {
    return repository.createTarea(
      titulo: titulo,
      descripcion: descripcion,
      fechaVencimiento: fechaVencimiento,
      tipo: tipo,
      prioridad: prioridad,
      dificultad: dificultad,
      estado: estado,
      materiaId: materiaId,
    );
  }
}
