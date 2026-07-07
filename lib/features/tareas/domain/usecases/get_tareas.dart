import '../entities/tarea.dart';
import '../repositories/tarea_repository_port.dart';

class GetTareas {
  final TareaRepositoryPort repository;

  const GetTareas(this.repository);

  Future<List<Tarea>> call() => repository.getTareas();
}
