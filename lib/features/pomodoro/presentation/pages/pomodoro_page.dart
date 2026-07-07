import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:helloworld/core/services/local_data_store.dart';
import '../../data/pomodoro_repository.dart';

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

  int completedSessionsToday = 0;
  int studiedMinutesToday = 0;

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

  int get totalSeconds => isBreakMode ? 5 * 60 : 25 * 60;

  @override
  void initState() {
    super.initState();
    _loadStats();
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

    setState(() => isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 1) {
        timer.cancel();
        _finishTimer();
        return;
      }

      if (!mounted) return;
      setState(() => remainingSeconds--);
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
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasBreakMode
                ? 'Descanso terminado.'
                : 'Sesión de estudio terminada.',
          ),
        ),
      );

    setState(() {
      remainingSeconds = totalSeconds;
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
                    _howToCard(),
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
              text: 'Trabajo',
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
    final color = isBreakMode ? green : primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: isBreakMode ? const Color(0xFFEFF1F6) : primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isBreakMode ? 'Modo Descanso' : 'Modo Estudio',
              style: TextStyle(
                color: isBreakMode ? textDark : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            '$min:$sec',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 30),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2DCFF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    isRunning ? 'Activo' : 'Iniciar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 58,
                height: 54,
                child: OutlinedButton(
                  onPressed: isRunning ? _pause : _reset,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    isRunning ? Icons.pause : Icons.refresh,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionsCard() {
    final value = (completedSessionsToday / 4).clamp(0.0, 1.0);

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
          const Text(
            'Sesiones de Estudio Hoy',
            style: TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8E8EE),
              valueColor: const AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$completedSessionsToday/4 sesiones completadas',
            style: const TextStyle(
              color: textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$studiedMinutesToday minutos estudiados hoy',
            style: const TextStyle(
              color: textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cómo usar',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 28),
          Text(
            '1. Selecciona una materia (opcional)',
            style: _PomodoroPageState.helpStyle,
          ),
          SizedBox(height: 12),
          Text(
            '2. Presiona "Iniciar" para comenzar 25 minutos de estudio',
            style: _PomodoroPageState.helpStyle,
          ),
          SizedBox(height: 12),
          Text(
            '3. Al terminar, toma un descanso de 5 minutos',
            style: _PomodoroPageState.helpStyle,
          ),
          SizedBox(height: 12),
          Text(
            '4. Después de 4 sesiones, descansa 15 minutos',
            style: _PomodoroPageState.helpStyle,
          ),
          SizedBox(height: 12),
          Text(
            '5. Elimina distracciones y concéntrate en una sola tarea',
            style: _PomodoroPageState.helpStyle,
          ),
        ],
      ),
    );
  }
}
