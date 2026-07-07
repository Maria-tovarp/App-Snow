import '../entities/materia.dart';

abstract class MateriaRepositoryPort {
  Future<List<Materia>> getMaterias();
  Future<void> createMateria({
    required String nombre,
    required String profesor,
    required int creditos,
    required String color,
  });
  Future<void> deleteMateria(String id);
}
