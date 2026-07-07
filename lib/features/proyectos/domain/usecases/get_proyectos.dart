import '../entities/proyecto.dart';
import '../repositories/proyecto_repository_port.dart';

class GetProyectos {
  final ProyectoRepositoryPort repository;

  const GetProyectos(this.repository);

  Future<List<Proyecto>> call() => repository.getProyectos();
}
