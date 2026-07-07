import '../entities/meta.dart';
import '../repositories/meta_repository_port.dart';

class GetMetas {
  final MetaRepositoryPort repository;

  const GetMetas(this.repository);

  Future<List<Meta>> call() => repository.getMetas();
}
