import '../entities/materia.dart';
import '../repositories/materia_repository_port.dart';

class GetMaterias {
  final MateriaRepositoryPort repository;

  const GetMaterias(this.repository);

  Future<List<Materia>> call() => repository.getMaterias();
}
