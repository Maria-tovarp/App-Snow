import '../entities/meta.dart';

abstract class MetaRepositoryPort {
  Future<List<Meta>> getMetas();
  Future<void> createMeta({String? descripcion, String? periodo, required String titulo});
  Future<void> completarMeta(String id);
  Future<void> deleteMeta(String id);
}
