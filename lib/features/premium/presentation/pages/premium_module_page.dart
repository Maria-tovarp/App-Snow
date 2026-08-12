import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snow/core/services/local_data_store.dart';
import 'package:snow/core/widgets/app_drawer.dart';
import 'package:snow/core/widgets/app_section_header.dart';
import 'package:snow/features/horario/data/horario_model.dart';
import 'package:snow/features/horario/data/horario_repository.dart';
import '../../data/premium_service.dart';

enum PremiumModule { insights, grades, planner, assistant }

class PremiumModulePage extends StatefulWidget {
  const PremiumModulePage({super.key, required this.module});
  final PremiumModule module;

  @override
  State<PremiumModulePage> createState() => _PremiumModulePageState();
}

class _PremiumModulePageState extends State<PremiumModulePage> {
  final store = LocalDataStore.instance;
  bool loading = true;
  bool premium = false;
  List<Map<String, dynamic>> tareas = [];
  List<Map<String, dynamic>> materias = [];
  List<Map<String, dynamic>> proyectos = [];
  List<Map<String, dynamic>> grades = [];
  List<HorarioModel> horarios = [];
  List<HorarioModel> lastReferencedClasses = [];
  Map<String, int> pomodoro = {};
  String userName = 'Usuario';
  final List<_AssistantMessage> assistantMessages = [];
  final assistantCtrl = TextEditingController();
  final assistantScrollCtrl = ScrollController();

  String get route => switch (widget.module) {
        PremiumModule.insights => '/premium/insights',
        PremiumModule.grades => '/premium/grades',
        PremiumModule.planner => '/premium/planner',
        PremiumModule.assistant => '/premium/assistant',
      };

  String get title => switch (widget.module) {
        PremiumModule.insights => 'Snow Insights',
        PremiumModule.grades => 'Mis notas',
        PremiumModule.planner => 'Planificador inteligente',
        PremiumModule.assistant => 'Snow Assistant',
      };

  String get subtitle => switch (widget.module) {
        PremiumModule.insights => 'Analiza tu rendimiento académico',
        PremiumModule.grades => 'Promedios y proyecciones',
        PremiumModule.planner => 'Prioriza tus próximas entregas',
        PremiumModule.assistant => 'Recomendaciones basadas en tus tareas',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    assistantCtrl.dispose();
    assistantScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await PremiumService.instance.initialize();
    await store.initialize();
    final registeredName = '${store.profile['nombre'] ?? ''}'.trim();
    if (registeredName.isNotEmpty && registeredName != 'Usuario') {
      userName = registeredName.split(RegExp(r'\s+')).first;
    }
    if (widget.module == PremiumModule.assistant && assistantMessages.isEmpty) {
      assistantMessages.add(_AssistantMessage(
        '¡Hola, $userName! 👋 Soy Snow, tu asistente académico. Estoy listo para ayudarte a organizar tu día. ¿Qué quieres consultar?',
        false,
      ));
    }
    premium = PremiumService.instance.isPremium;
    if (premium) {
      final results = await Future.wait([
        store.getTareas(),
        store.getMaterias(),
        store.getProyectos(),
        store.getTodayPomodoroStats(),
        HorarioRepository().getHorarios(),
      ]);
      tareas = results[0] as List<Map<String, dynamic>>;
      materias = results[1] as List<Map<String, dynamic>>;
      proyectos = results[2] as List<Map<String, dynamic>>;
      pomodoro = results[3] as Map<String, int>;
      horarios = results[4] as List<HorarioModel>;
      if (widget.module == PremiumModule.grades ||
          widget.module == PremiumModule.assistant) {
        try {
          grades = await store.getGrades();
        } catch (_) {
          grades = [];
        }
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: AppDrawer(currentRoute: route),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(children: [
          AppSectionHeader(title: title, subtitle: subtitle),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : premium
                    ? widget.module == PremiumModule.assistant
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            child: _assistant(),
                          )
                        : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [_content()],
                        ),
                      )
                    : _locked(),
          ),
        ]),
      );

  Widget _locked() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 58, color: Color(0xFFE6AD17)),
            const SizedBox(height: 16),
            Text('$title es una función Premium',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Activa tu prueba o suscripción para continuar.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: () => context.go('/premium'),
                child: const Text('Ver Snow Premium')),
          ]),
        ),
      );

  Widget _content() => switch (widget.module) {
        PremiumModule.insights => _insights(),
        PremiumModule.grades => _grades(),
        PremiumModule.planner => _planner(),
        PremiumModule.assistant => _assistant(),
      };

  Widget _insights() {
    final done = tareas.where((t) => t['estado'] == 'completada').length;
    final pending = tareas.length - done;
    final progress = tareas.isEmpty ? 0 : ((done / tareas.length) * 100).round();
    final activeProjects = proyectos
        .where((p) => (num.tryParse('${p['avance_porcentual']}') ?? 0) < 100)
        .length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF211B52), Color(0xFF5B4CF0)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tu progreso académico', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$progress% completado', style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress / 100, minHeight: 10, color: const Color(0xFFFFD76A), backgroundColor: Colors.white24, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          Text(done == 0 ? 'Completa tu primera tarea para comenzar tu progreso.' : 'Has completado $done de ${tareas.length} tareas.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 20),
      _sectionTitle('Resumen de productividad', Icons.insights_rounded),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
        children: [
          _metric('$pending', 'Tareas pendientes', Icons.pending_actions_rounded, const Color(0xFFFF8A65)),
          _metric('${pomodoro['minutosEstudio'] ?? 0} min', 'Tiempo estudiado hoy', Icons.timer_rounded, const Color(0xFF26A69A)),
          _metric('$activeProjects', 'Proyectos activos', Icons.folder_rounded, const Color(0xFF42A5F5)),
          _metric('${pomodoro['sesionesEstudio'] ?? 0}', 'Sesiones completadas', Icons.local_fire_department_rounded, const Color(0xFFEF5350)),
        ],
      ),
      const SizedBox(height: 20),
      _card('Carga académica', Icons.school_outlined, [
        Text('${materias.length} materias activas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Mantén tus tareas distribuidas para evitar sobrecarga.', style: TextStyle(fontSize: 12)),
      ]),
    ]);
  }

  Widget _grades() {
    final weighted = grades.fold<double>(0, (sum, g) {
      final grade = double.tryParse('${g['calificacion']}') ?? 0;
      final weight = double.tryParse('${g['porcentaje']}') ?? 0;
      return sum + grade * weight / 100;
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF5B4CF0), borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const CircleAvatar(radius: 27, backgroundColor: Colors.white24, child: Icon(Icons.school_rounded, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Promedio ponderado', style: TextStyle(color: Colors.white70)), Text(weighted.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900))])),
          Text('${grades.length} notas', style: const TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7165FF), Color(0xFF5546EA)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B4CF0).withValues(alpha: .28),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _addGrade,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                const Text(
                  'Registrar nueva nota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (grades.isEmpty)
        const _Empty('Todavía no has registrado notas.')
      else
        ...grades.map((g) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                title: Text('${g['nombre']}'),
                subtitle: Text(
                    '${g['materia_nombre'] ?? 'Sin materia'} · ${g['porcentaje']}%'),
                leading: CircleAvatar(backgroundColor: const Color(0xFF5B4CF0).withValues(alpha: .12), child: Text('${g['calificacion']}', style: const TextStyle(color: Color(0xFF5B4CF0), fontWeight: FontWeight.w900))),
                onTap: () => _addGrade(g),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar nota',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _addGrade(g),
                    ),
                    IconButton(
                      tooltip: 'Eliminar nota',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await store.deleteGrade('${g['id']}');
                        await _load();
                      },
                    ),
                  ],
                ),
              ),
            )),
    ]);
  }

  Widget _planner() {
    final pending = tareas.where((t) => t['estado'] != 'completada').toList()
      ..sort((a, b) => '${a['fecha_vencimiento']}'
          .compareTo('${b['fecha_vencimiento']}'));
    if (pending.isEmpty) return const _Empty('No tienes entregas pendientes.');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF5B4CF0).withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFF5B4CF0), child: Icon(Icons.auto_awesome, color: Colors.white)),
          const SizedBox(width: 13),
          Expanded(child: Text('Snow organizó ${pending.length} ${pending.length == 1 ? 'entrega' : 'entregas'} según fecha y prioridad.', style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35))),
        ]),
      ),
      const SizedBox(height: 18),
      ...pending.take(12).toList().asMap().entries.map((entry) {
        final t = entry.value;
        final priority = '${t['prioridad'] ?? 'media'}';
        final priorityColor = priority.toLowerCase() == 'alta' ? const Color(0xFFEF5350) : priority.toLowerCase() == 'baja' ? const Color(0xFF26A69A) : const Color(0xFFFFA726);
        return Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
          child: Row(children: [
            Column(children: [CircleAvatar(radius: 17, backgroundColor: const Color(0xFF5B4CF0).withValues(alpha: .12), child: Text('${entry.key + 1}', style: const TextStyle(color: Color(0xFF5B4CF0), fontWeight: FontWeight.w900))), Container(width: 2, height: 28, color: const Color(0xFF5B4CF0).withValues(alpha: .18))]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${t['titulo']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), Row(children: [const Icon(Icons.calendar_today_outlined, size: 14), const SizedBox(width: 5), Expanded(child: Text(_friendlyDate(t['fecha_vencimiento']), style: const TextStyle(fontSize: 12)))])])),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: priorityColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w800))),
          ]),
        );
      }),
    ]);
  }

  Widget _assistant() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const CircleAvatar(radius: 19, backgroundColor: Color(0xFF5B4CF0), child: Text('🐰')),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Snow Assistant', style: TextStyle(fontWeight: FontWeight.w900)), Row(children: [Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF36C76C), shape: BoxShape.circle)), const SizedBox(width: 5), const Text('En línea · Responde con tus datos académicos', style: TextStyle(fontSize: 10))])])),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
            child: ListView.builder(
              controller: assistantScrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: assistantMessages.length,
              itemBuilder: (context, index) => _ChatBubble(message: assistantMessages[index]),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: ['Clases de hoy', 'Organiza mi semana', '¿Qué hago primero?', 'Mi promedio'].map((text) {
            final question = switch (text) {
              'Clases de hoy' => '¿Qué clases tengo hoy?',
              'Mi promedio' => '¿Cuál es mi promedio?',
              _ => text,
            };
            return ActionChip(
              visualDensity: VisualDensity.compact,
              labelStyle: const TextStyle(fontSize: 11),
              avatar: const Icon(Icons.auto_awesome, size: 14),
              label: Text(text),
              onPressed: () { assistantCtrl.text = question; _generateAdvice(); },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(
            controller: assistantCtrl,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _generateAdvice(),
            decoration: InputDecoration(
              hintText: 'Pregúntale algo a Snow…',
              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide.none),
            ),
          )),
          const SizedBox(width: 9),
          SizedBox(width: 50, height: 50, child: FilledButton(onPressed: _generateAdvice, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5B4CF0), padding: EdgeInsets.zero, shape: const CircleBorder()), child: const Icon(Icons.send_rounded))),
        ]),
      ]);

  String _friendlyDate(dynamic value) {
    final date = DateTime.tryParse('${value ?? ''}');
    if (date == null) return 'Sin fecha de entrega';
    return DateFormat('dd/MM/yyyy · HH:mm').format(date.toLocal());
  }

  Widget _card(String title, IconData icon, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, color: const Color(0xFF5B4CF0)), const SizedBox(width: 9), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: children),
          ]),
        ),
      );

  Widget _metric(String value, String label, IconData icon, Color accent) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: accent, size: 21),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      );

  Widget _sectionTitle(String text, IconData icon) => Row(children: [
        Icon(icon, color: const Color(0xFF5B4CF0), size: 21),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ]);

  void _generateAdvice() {
    final question = assistantCtrl.text.trim();
    if (question.isEmpty) {
      return;
    }
    final normalized = _normalize(question);
    final pending = tareas.where((t) => t['estado'] != 'completada').toList();
    final urgent = pending.where((t) => '${t['prioridad']}'.toLowerCase() == 'alta').toList();
    final first = urgent.isNotEmpty ? urgent.first : (pending.isNotEmpty ? pending.first : null);
    late String answer;
      if (_isGreeting(normalized)) {
        answer = '¡Hola de nuevo, $userName! 😊 Podemos revisar tus clases de hoy, tareas pendientes, proyectos, notas o tiempo de estudio. ¿Por dónde empezamos?';
      } else if (_asksAboutClasses(normalized) && normalized.contains('hoy')) {
        answer = _classesForDay(DateTime.now().weekday, 'hoy', normalized);
      } else if (_asksAboutClasses(normalized) && normalized.contains('manana')) {
        final tomorrow = DateTime.now().add(const Duration(days: 1)).weekday;
        answer = _classesForDay(tomorrow, 'mañana', normalized);
      } else if (normalized.contains('horario')) {
        answer = _weeklyScheduleAnswer();
      } else if (normalized.contains('profesor') ||
          normalized.contains('docente') ||
          normalized.contains('quien da')) {
        answer = _teacherAnswer(normalized);
      } else if (normalized.contains('materias') || normalized.contains('asignaturas')) {
        answer = materias.isEmpty
            ? 'No tienes materias registradas.'
            : 'Tienes ${materias.length} materias: ${materias.map((m) => m['nombre']).join(', ')}.';
      } else if (normalized.contains('tareas') || normalized.contains('pendientes')) {
        answer = _tasksAnswer(normalized, pending);
      } else if (normalized.contains('proyectos')) {
        final active = proyectos.where((p) => (num.tryParse('${p['avance_porcentual']}') ?? 0) < 100).toList();
        answer = active.isEmpty
            ? 'No tienes proyectos activos.'
            : 'Tienes ${active.length} proyectos activos: ${active.map((p) => p['titulo']).join(', ')}.';
      } else if (normalized.contains('notas') || normalized.contains('promedio')) {
        answer = _gradesAnswer();
      } else if (normalized.contains('pomodoro') || normalized.contains('estudiado') || normalized.contains('estudio hoy')) {
        answer = 'Hoy registras ${pomodoro['sesionesEstudio'] ?? 0} sesiones Pomodoro y ${pomodoro['minutosEstudio'] ?? 0} minutos de estudio.';
      } else {
        answer = first == null
            ? 'No tienes tareas pendientes. Puedes dedicar hoy a repasar la materia que más te cueste.'
            : _priorityAdvice(first, pending.length - 1);
      }
    assistantCtrl.clear();
    setState(() {
      assistantMessages.add(_AssistantMessage(question, true));
      assistantMessages.add(_AssistantMessage(answer, false));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (assistantScrollCtrl.hasClients) {
        assistantScrollCtrl.animateTo(
          assistantScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _priorityAdvice(Map<String, dynamic> task, int remaining) {
    final title = '${task['titulo'] ?? 'Tarea pendiente'}';
    final subject = '${task['materia_nombre'] ?? ''}'.trim();
    final priority = '${task['prioridad'] ?? 'media'}';
    final priorityLabel = priority.isEmpty
        ? 'Media'
        : '${priority[0].toUpperCase()}${priority.substring(1)}';
    final dueDate = _friendlyDate(task['fecha_vencimiento']);
    final rest = remaining <= 0
        ? 'Al terminarla, habrás completado todos tus pendientes.'
        : remaining == 1
            ? 'Después quedará 1 tarea pendiente.'
            : 'Después quedarán $remaining tareas; continúa con la fecha de entrega más cercana.';

    return '🎯 Empieza por esta tarea:\n\n'
        '$title${subject.isEmpty ? '' : '\n$subject'}\n\n'
        '📌 Prioridad: $priorityLabel\n'
        '📅 Entrega: $dueDate\n\n'
        'Plan recomendado:\n'
        '1. Trabaja durante 25 minutos sin distracciones.\n'
        '2. Descansa 5 minutos.\n'
        '3. Revisa y termina los detalles pendientes.\n\n'
        '$rest';
  }

  String _classesForDay(int weekday, String label, [String? question]) {
    final mentionedSubject = question == null
        ? null
        : _findMentionedSubject(question);
    final classes = horarios.where((h) {
      if (h.diaSemana != weekday) return false;
      if (mentionedSubject == null) return true;
      return h.materiaId == '${mentionedSubject['id']}' ||
          _normalize(h.materiaNombre) ==
              _normalize('${mentionedSubject['nombre']}');
    }).toList()
      ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    if (classes.isEmpty) {
      return mentionedSubject == null
          ? 'No tienes clases registradas para $label.'
          : '✅ No tienes clase de ${mentionedSubject['nombre']} $label.';
    }
    lastReferencedClasses = List<HorarioModel>.from(classes);
    final details = classes.map((h) {
      final room = h.salon.trim().isEmpty
          ? ''
          : '\n   📍 Salón ${h.salon.trim()}';
      return '• ${h.materiaNombre}\n'
          '   🕒 ${_formatClassTime(h.horaInicio)} – ${_formatClassTime(h.horaFin)}$room';
    }).join('\n\n');
    final dayLabel = label == 'hoy' ? 'Hoy' : 'Mañana';
    return '📚 $dayLabel tienes ${classes.length} '
        '${classes.length == 1 ? 'clase' : 'clases'}:\n\n$details';
  }

  bool _asksAboutClasses(String question) {
    return question.contains('clase') ||
        question.contains('horario') ||
        question.contains('materia tengo');
  }

  Map<String, dynamic>? _findMentionedSubject(String question) {
    const ignoredWords = {
      'tengo', 'clase', 'clases', 'materia', 'hoy', 'manana',
      'profesor', 'docente', 'tarea', 'tareas', 'pendientes',
    };
    for (final subject in materias) {
      final normalizedName = _normalize('${subject['nombre'] ?? ''}');
      if (normalizedName.isEmpty) continue;
      if (question.contains(normalizedName)) return subject;
      final meaningfulWords = normalizedName
          .split(RegExp(r'\s+'))
          .where((word) => word.length >= 5 && !ignoredWords.contains(word));
      if (meaningfulWords.any(question.contains)) return subject;
    }
    return null;
  }

  String _teacherAnswer(String question) {
    final explicitlyMentioned = horarios.where((h) {
      final subject = _normalize(h.materiaNombre);
      return subject.isNotEmpty && question.contains(subject);
    }).toList();
    final references = explicitlyMentioned.isNotEmpty
        ? explicitlyMentioned
        : lastReferencedClasses;

    if (references.isEmpty) {
      return '¿De cuál clase quieres conocer el docente? Puedes escribir el nombre de la materia o preguntar primero por tus clases de hoy.';
    }

    final unique = <String, HorarioModel>{};
    for (final item in references) {
      unique[item.materiaId] = item;
    }
    final details = unique.values.map((item) {
      final teacher = item.profesor.trim();
      return teacher.isEmpty
          ? '• ${item.materiaNombre}: no tiene docente registrado.'
          : '• ${item.materiaNombre}: $teacher.';
    }).join('\n');
    return unique.length == 1
        ? '👩‍🏫 El docente registrado es:\n\n$details'
        : '👩‍🏫 Estos son los docentes de las clases consultadas:\n\n$details';
  }

  String _tasksAnswer(
      String question, List<Map<String, dynamic>> pendingTasks) {
    var scopedTasks = List<Map<String, dynamic>>.from(pendingTasks);
    String? periodLabel;
    final now = DateTime.now();
    if (question.contains('hoy')) {
      periodLabel = 'para hoy';
      scopedTasks = scopedTasks
          .where((task) => _isSameDay(_taskDate(task), now))
          .toList();
    } else if (question.contains('manana')) {
      periodLabel = 'para mañana';
      final tomorrow = now.add(const Duration(days: 1));
      scopedTasks = scopedTasks
          .where((task) => _isSameDay(_taskDate(task), tomorrow))
          .toList();
    } else if (question.contains('semana')) {
      periodLabel = 'para esta semana';
      final end = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 7));
      scopedTasks = scopedTasks.where((task) {
        final date = _taskDate(task);
        return date != null && !date.isBefore(now) && date.isBefore(end);
      }).toList();
    }
    Map<String, dynamic>? referencedSubject;

    for (final subject in materias) {
      final subjectName = _normalize('${subject['nombre'] ?? ''}');
      if (subjectName.isNotEmpty && question.contains(subjectName)) {
        referencedSubject = subject;
        break;
      }
    }

    final usesContext = question.contains('esa materia') ||
        question.contains('esa clase') ||
        question.contains('de ahi');
    if (referencedSubject == null &&
        usesContext &&
        lastReferencedClasses.isNotEmpty) {
      final lastClass = lastReferencedClasses.first;
      referencedSubject = materias.cast<Map<String, dynamic>?>().firstWhere(
            (subject) => '${subject?['id']}' == lastClass.materiaId,
            orElse: () => {
              'id': lastClass.materiaId,
              'nombre': lastClass.materiaNombre,
            },
          );
    }

    if (referencedSubject == null) {
      if (scopedTasks.isEmpty) {
        return periodLabel == null
            ? 'No tienes tareas pendientes. ¡Vas al día!'
            : '✅ No tienes tareas pendientes $periodLabel.';
      }
      final description = periodLabel ?? 'pendientes';
      return 'Tienes ${scopedTasks.length} ${scopedTasks.length == 1 ? 'tarea' : 'tareas'} $description:\n\n${scopedTasks.take(5).map((task) => '• ${task['titulo']}\n  Entrega: ${_friendlyDate(task['fecha_vencimiento'])}').join('\n\n')}';
    }

    final subjectId = '${referencedSubject['id']}';
    final subjectName = '${referencedSubject['nombre']}';
    final subjectTasks = scopedTasks.where((task) {
      final sameId = '${task['materia_id']}' == subjectId;
      final sameName = _normalize('${task['materia_nombre'] ?? ''}') ==
          _normalize(subjectName);
      return sameId || sameName;
    }).toList();

    if (subjectTasks.isEmpty) {
      return periodLabel == null
          ? '✅ No tienes tareas pendientes de $subjectName.'
          : '✅ No tienes tareas de $subjectName $periodLabel.';
    }
    return '📚 De $subjectName tienes ${subjectTasks.length} '
        '${subjectTasks.length == 1 ? 'tarea pendiente' : 'tareas pendientes'}:\n\n'
        '${subjectTasks.take(5).map((task) => '• ${task['titulo']}\n  Entrega: ${_friendlyDate(task['fecha_vencimiento'])}').join('\n\n')}';
  }

  DateTime? _taskDate(Map<String, dynamic> task) {
    return DateTime.tryParse('${task['fecha_vencimiento'] ?? ''}')?.toLocal();
  }

  bool _isSameDay(DateTime? first, DateTime second) {
    return first != null &&
        first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatClassTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return value;
    final suffix = hour >= 12 ? 'p. m.' : 'a. m.';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${parts[1]} $suffix';
  }

  String _weeklyScheduleAnswer() {
    if (horarios.isEmpty) return 'No tienes clases registradas en el horario.';
    const days = ['', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return horarios.take(10).map((h) => '${days[h.diaSemana]}: ${h.materiaNombre} ${h.horaInicio}-${h.horaFin}').join('; ');
  }

  String _gradesAnswer() {
    if (grades.isEmpty) return 'Aún no tienes notas registradas en Mis notas.';
    final totalWeight = grades.fold<double>(0, (sum, g) => sum + (double.tryParse('${g['porcentaje']}') ?? 0));
    final weighted = grades.fold<double>(0, (sum, g) => sum + (double.tryParse('${g['calificacion']}') ?? 0) * (double.tryParse('${g['porcentaje']}') ?? 0) / 100);
    return 'Tu promedio ponderado registrado es ${weighted.toStringAsFixed(2)} con $totalWeight% evaluado.';
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  bool _isGreeting(String value) {
    final greeting = value.trim();
    return greeting == 'hola' ||
        greeting == 'buenos dias' ||
        greeting == 'buenas tardes' ||
        greeting == 'buenas noches' ||
        greeting == 'hey';
  }

  Future<void> _addGrade([Map<String, dynamic>? existing]) async {
    final isEditing = existing != null;
    final name = TextEditingController(text: '${existing?['nombre'] ?? ''}');
    final grade = TextEditingController(
        text: isEditing ? '${existing['calificacion'] ?? ''}' : '');
    final weight = TextEditingController(
        text: isEditing ? '${existing['porcentaje'] ?? ''}' : '');
    String? materiaId = existing?['materia_id']?.toString();
    String? validationError;
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModal) {
          final colors = Theme.of(dialogContext).colorScheme;
          InputDecoration fieldDecoration(
            String label,
            IconData icon, {
            String? suffix,
          }) =>
              InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, size: 21),
                suffixText: suffix,
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
              );

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              MediaQuery.viewInsetsOf(dialogContext).bottom + 24,
            ),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B4CF0).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Color(0xFF5B4CF0)),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Registrar nota',
                                  style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900)),
                              SizedBox(height: 3),
                              Text('Agrega una evaluación a tu promedio',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.pop(dialogContext, false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ]),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<String>(
                        initialValue: materiaId,
                        isExpanded: true,
                        decoration: fieldDecoration(
                            'Selecciona una materia', Icons.menu_book_rounded),
                        items: materias
                            .map((m) => DropdownMenuItem(
                                  value: '${m['id']}',
                                  child: Text('${m['nombre']}',
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setModal(() => materiaId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: fieldDecoration(
                            'Nombre de la actividad', Icons.assignment_outlined),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: grade,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: fieldDecoration(
                                'Nota', Icons.star_outline_rounded,
                                suffix: '/ 5.0'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weight,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: fieldDecoration(
                                'Porcentaje', Icons.percent_rounded,
                                suffix: '%'),
                          ),
                        ),
                      ]),
                      if (validationError != null) ...[
                        const SizedBox(height: 12),
                        Text(validationError!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12)),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4CF0),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final value = double.tryParse(
                              grade.text.replaceAll(',', '.'));
                          final percentage = double.tryParse(
                              weight.text.replaceAll(',', '.'));
                          if (materiaId == null ||
                              name.text.trim().isEmpty ||
                              value == null ||
                              value < 0 ||
                              value > 5 ||
                              percentage == null ||
                              percentage <= 0 ||
                              percentage > 100) {
                            setModal(() => validationError =
                                'Completa todos los campos con valores válidos.');
                            return;
                          }
                          Navigator.pop(dialogContext, true);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Guardar nota'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (saved != true) {
      name.dispose();
      grade.dispose();
      weight.dispose();
      return;
    }
    final value = double.tryParse(grade.text.replaceAll(',', '.'));
    final percentage = double.tryParse(weight.text.replaceAll(',', '.'));
    if (isEditing) {
      await store.updateGrade(
        id: '${existing['id']}',
        nombre: name.text.trim(),
        calificacion: value!,
        porcentaje: percentage!,
        materiaId: materiaId,
      );
    } else {
      await store.createGrade(
        nombre: name.text.trim(),
        calificacion: value!,
        porcentaje: percentage!,
        materiaId: materiaId,
      );
    }
    name.dispose();
    grade.dispose();
    weight.dispose();
    await _load();
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(30),
      child: Center(child: Text(text, textAlign: TextAlign.center)));
}

class _AssistantMessage {
  const _AssistantMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.fromUser
              ? const Color(0xFF5B4CF0)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.fromUser ? 18 : 4),
            bottomRight: Radius.circular(message.fromUser ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? Colors.white : colors.onSurface,
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
