abstract class PomodoroRepositoryPort {
  Future<void> saveSession({
    required String tipo,
    required int duracionMinutos,
    String? materiaId,
  });
  Future<Map<String, int>> getTodayStats();
}
