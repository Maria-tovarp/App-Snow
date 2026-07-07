import '../repositories/pomodoro_repository_port.dart';

class GetTodayPomodoroStats {
  final PomodoroRepositoryPort repository;

  const GetTodayPomodoroStats(this.repository);

  Future<Map<String, int>> call() => repository.getTodayStats();
}
