import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'package:helloworld/core/services/local_data_store.dart';
import '../../data/pomodoro_repository.dart';

import 'package:helloworld/core/widgets/app_notification.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  final PomodoroRepository _repo = PomodoroRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;

  int remainingSeconds = 25 * 60;
  bool isRunning = false;
  bool isBreakMode = false;
  int pomodoroCycle = 0;
  bool longBreak = false;

  int completedSessionsToday = 0;
  int studiedMinutesToday = 0;

  Map<String, int> weekStats = {};

  List<Map<String, dynamic>> materias = [];
  String? materiaSeleccionadaId;
  bool loadingMaterias = true;

  static const Color primary = Color(0xFF5B4CF0);
  static const Color green = Color(0xFF22C55E);
  static const Color textDark = Color(0xFF20202A);
  static const Color textMuted = Color(0xFF7C7C90);
  static const Color cardBorder = Color(0xFFE4E4EC);

  static const TextStyle helpStyle = TextStyle(
    color: textMuted,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );
  int get totalSeconds {
    if (!isBreakMode) {
      return 25 * 60;
    }

    return longBreak ? 15 * 60 : 5 * 60;
  }

  @override
  void initState() {
    super.initState();

    _loadStats();
    _loadWeekStats();
    _loadMaterias();
  }

  Future<void> _loadStats() async {
    try {
      final stats =
          await _repo.getTodayStats().timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        completedSessionsToday = stats['sesionesEstudio'] ?? 0;
        studiedMinutesToday = stats['minutosEstudio'] ?? 0;
      });
    } catch (_) {
      // Si Supabase no responde, Pomodoro debe seguir funcionando.
      if (!mounted) return;
      setState(() {
        completedSessionsToday = completedSessionsToday;
        studiedMinutesToday = studiedMinutesToday;
      });
    }
  }

  Future<void> _loadWeekStats() async {
    try {
      final stats = await _repo.getWeekStats();

      if (!mounted) return;

      setState(() {
        weekStats = stats;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        weekStats = {};
      });
    }
  }

  Future<void> _loadMaterias() async {
    await LocalDataStore.instance.initialize();

    final data = await LocalDataStore.instance.getMaterias();

    if (!mounted) return;

    setState(() {
      materias = data;
      loadingMaterias = false;
    });
  }

  Future<void> _showExitBlockedMessage() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'El Pomodoro está activo. Pausa o reinicia el temporizador antes de salir.',
          ),
        ),
      );
  }

  Future<void> _tryLeavePomodoro() async {
    if (isRunning) {
      await _showExitBlockedMessage();
      return;
    }

    if (!mounted) return;
    context.go('/home');
  }

  void _start() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
    });

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        _finishTimer();
      }
    });
  }

  Future<void> _finishTimer() async {
    if (!mounted) return;

    final wasBreakMode = isBreakMode;
    final minutesCompleted = wasBreakMode ? 5 : 25;

    setState(() {
      isRunning = false;
      remainingSeconds = 0;
    });

    try {
      await _audioPlayer
          .play(AssetSource('sounds/ding.mp3'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // En FlutLab web el audio puede fallar si el navegador bloquea el sonido.
      // No debe detener el Pomodoro ni congelar la pantalla.
    }

    if (!wasBreakMode) {
      try {
        await _repo
            .saveSession(
              tipo: 'estudio',
              duracionMinutos: minutesCompleted,
              materiaId: materiaSeleccionadaId,
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Si Supabase tarda o falla, la pantalla no se queda bloqueada.
      }

      await _loadStats();
      if (mounted && !wasBreakMode) {
        setState(() {
          if (pomodoroCycle < 3) {
            pomodoroCycle++;
            longBreak = false;
          } else {
            pomodoroCycle = 0;
            longBreak = true;
          }
        });
      }
    }

    if (!mounted) return;

    AppNotification.success(
      context,
      message: wasBreakMode
          ? 'Descanso terminado. ¡Hora de estudiar!'
          : 'Sesión de estudio completada',
    );

// Espera un segundo para que el usuario vea el cambio de modo
    setState(() {
      // Cambiamos de modo
      isBreakMode = !wasBreakMode;

      // Si acabó un descanso largo, reiniciamos el ciclo
      if (wasBreakMode && longBreak) {
        longBreak = false;
        pomodoroCycle = 0;
      }

      // Asignamos el tiempo según el modo actual
      if (!isBreakMode) {
        remainingSeconds = 25 * 60;
      } else {
        remainingSeconds = longBreak ? 15 * 60 : 5 * 60;
      }

      isRunning = false;
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
      remainingSeconds = totalSeconds;
    });
  }

  void _setMode(bool breakMode) {
    if (isRunning) {
      _showExitBlockedMessage();
      return;
    }

    _timer?.cancel();

    setState(() {
      isBreakMode = breakMode;
      isRunning = false;
      remainingSeconds = breakMode ? 5 * 60 : 25 * 60;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = (1 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0);

    return PopScope(
      canPop: !isRunning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isRunning) {
          _showExitBlockedMessage();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoCard(),
                    const SizedBox(height: 22),
                    const Text(
                      'Materia (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _materiaSelector(),
                    const SizedBox(height: 22),
                    _modeSelector(),
                    const SizedBox(height: 22),
                    _timerCard(min, sec, progress),
                    const SizedBox(height: 22),
                    _sessionsCard(),
                    const SizedBox(height: 22),
                    _weeklyHistoryCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
      decoration: const BoxDecoration(
        color: primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _tryLeavePomodoro,
            borderRadius: BorderRadius.circular(30),
            child: const Padding(
              padding: EdgeInsets.only(top: 4, right: 14),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronómetro Pomodoro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Técnica de estudio enfocado',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método Pomodoro',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '25 min de estudio + 5 min de descanso.\nCada 4 sesiones, descansa 15 minutos.',
            style: TextStyle(
              color: textMuted,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _materiaSelector() {
    if (loadingMaterias) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      value: materiaSeleccionadaId,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F0F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: primary,
            width: 1.2,
          ),
        ),
      ),
      hint: const Text(
        'Sin materia específica',
        style: TextStyle(
          color: textDark,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Sin materia específica'),
        ),
        ...materias.map(
          (m) => DropdownMenuItem<String?>(
            value: m['id']?.toString(),
            child: Text(
              m['nombre']?.toString() ?? 'Materia sin nombre',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          materiaSeleccionadaId = value;
        });
      },
    );
  }

  Widget _modeSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              icon: Icons.menu_book_outlined,
              text: 'Estudio',
              active: !isBreakMode,
              left: true,
              onTap: () => _setMode(false),
            ),
          ),
          Expanded(
            child: _modeButton(
              icon: Icons.coffee_outlined,
              text: 'Descanso',
              active: isBreakMode,
              left: false,
              onTap: () => _setMode(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String text,
    required bool active,
    required bool left,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: active ? primary : Colors.white,
          borderRadius: BorderRadius.horizontal(
            left: left ? const Radius.circular(10) : Radius.zero,
            right: !left ? const Radius.circular(10) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : Colors.black,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerCard(String min, String sec, double progress) {
    final color = isBreakMode
        ? const Color(0xFFA78BFA)
        : isRunning
            ? const Color(0xFF4338CA)
            : primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color.withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBreakMode ? Icons.coffee_rounded : Icons.menu_book_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isBreakMode ? 'Modo Descanso' : 'Modo Estudio',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _PomodoroPainter(
                      progress: progress,
                      color: color,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$min:$sec',
                      style: TextStyle(
                        color: color,
                        fontSize: 68,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isRunning
                              ? 'Tiempo restante'
                              : remainingSeconds == totalSeconds
                                  ? 'Listo para comenzar'
                                  : (isBreakMode
                                      ? 'Descanso pausado'
                                      : 'Estudio pausado'),
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !isBreakMode
                              ? 'Sesión de 25 minutos'
                              : (longBreak
                                  ? 'Descanso largo de 15 minutos'
                                  : 'Descanso de 5 minutos'),
                          style: const TextStyle(
                            color: Color(0xFF9A9AAF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isRunning ? _pause : _start,
                    icon: Icon(
                      isRunning
                          ? Icons.pause_rounded
                          : (isBreakMode
                              ? Icons.coffee_rounded
                              : Icons.play_arrow_rounded),
                      color: Colors.white,
                      size: 22,
                    ),
                    label: Text(
                      isRunning
                          ? (isBreakMode ? 'Pausar descanso' : 'Pausar estudio')
                          : remainingSeconds == totalSeconds
                              ? (isBreakMode
                                  ? 'Iniciar descanso'
                                  : 'Iniciar estudio')
                              : (isBreakMode
                                  ? 'Continuar descanso'
                                  : 'Continuar estudio'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                height: 56,
                child: OutlinedButton(
                  onPressed: isRunning ? _pause : _reset,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: color.withOpacity(0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    isRunning ? Icons.pause_rounded : Icons.refresh_rounded,
                    color: color,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (!isBreakMode)
            Column(
              children: [
                Text(
                  'Sesión ${pomodoroCycle + 1} de 4',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < (pomodoroCycle + 1)
                            ? primary
                            : const Color(0xFFE5E7EB),
                        boxShadow: index < (pomodoroCycle + 1)
                            ? [
                                BoxShadow(
                                  color: primary.withOpacity(0.30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _sessionsCard() {
    final sessionsCompleted = completedSessionsToday.clamp(0, 4);
    final value = sessionsCompleted / 4;
    final currentSession = (sessionsCompleted + 1).clamp(1, 4);
    final cardColor = isBreakMode ? const Color(0xFFA78BFA) : primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: cardColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Progreso de hoy',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$sessionsCompleted/4',
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE8E8EE),
                    valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: cardColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  icon: Icons.schedule_rounded,
                  title: 'Tiempo',
                  value: '$studiedMinutesToday min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  icon: Icons.skip_next_rounded,
                  title: 'Próximo',
                  value: isBreakMode
                      ? 'Estudio'
                      : (pomodoroCycle == 3
                          ? 'Descanso largo'
                          : 'Descanso corto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekDayCard({
    required String day,
    required int minutes,
  }) {
    Color levelColor;

    if (minutes == 0) {
      levelColor = const Color(0xFFE8E8EE);
    } else if (minutes <= 25) {
      levelColor = primary.withOpacity(0.30);
    } else if (minutes <= 50) {
      levelColor = primary.withOpacity(0.50);
    } else if (minutes <= 75) {
      levelColor = primary.withOpacity(0.70);
    } else {
      levelColor = primary;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 80,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 26,
                  height: ((minutes.clamp(0, 120) / 120) * 80).clamp(12, 80),
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$minutes min',
              style: const TextStyle(
                fontSize: 12,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: primary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Historial Semanal',
                style: TextStyle(
                  color: textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _weekDayCard(
                day: 'Lun',
                minutes: weekStats['Lun'] ?? 0,
              ),
              _weekDayCard(
                day: 'Mar',
                minutes: weekStats['Mar'] ?? 0,
              ),
              _weekDayCard(
                day: 'Mié',
                minutes: weekStats['Mié'] ?? 0,
              ),
              _weekDayCard(
                day: 'Jue',
                minutes: weekStats['Jue'] ?? 0,
              ),
              _weekDayCard(
                day: 'Vie',
                minutes: weekStats['Vie'] ?? 0,
              ),
              _weekDayCard(
                day: 'Sáb',
                minutes: weekStats['Sáb'] ?? 0,
              ),
              _weekDayCard(
                day: 'Dom',
                minutes: weekStats['Dom'] ?? 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PomodoroPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _PomodoroPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;

    final center = Offset(size.width / 2, size.height / 2);

    final radius = (size.width - stroke) / 2;

    final background = Paint()
      ..color = const Color(0xFFEAE7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(
      center,
      radius,
      background,
    );

    final foreground = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4338CA),
          Color(0xFF6A5AF9),
          Color(0xFF8B7CFF),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -pi / 2,
      2 * pi * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _PomodoroPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
