import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:helloworld/core/services/auth_session_service.dart';
import 'package:helloworld/core/services/local_data_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = LocalDataStore.instance;
  final _auth = AuthSessionService.instance;

  bool isLoading = true;
  int materiasActivas = 0;
  int tareasPendientes = 0;
  int tareasCompletadas = 0;
  int proyectosActivos = 0;
  int metasCompletadas = 0;
  int metasTotales = 0;
  List<Map<String, dynamic>> proximasEntregas = [];
  List<int> tareasPorDia = List.filled(7, 0);

  static const Color _primary = Color(0xFF5546E8);
  static const Color _textMuted = Color(0xFF7E8093);
  static const Color _border = Color(0xFFE7E7EC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _store.initialize();

    final tareas = await _store.getTareas();
    final proyectos = await _store.getProyectos();
    final metas = await _store.getMetas();
    final materias = await _store.getMaterias();

    final pendientes = tareas
        .where((t) => (t['estado'] ?? 'pendiente') != 'completada')
        .toList();

    final completadas =
        tareas.where((t) => (t['estado'] ?? '') == 'completada').length;

    final activos = proyectos
        .where((p) => ((p['avance_porcentual'] ?? 0) as int) < 100)
        .length;

    final metasDone =
        metas.where((m) => (m['estado'] ?? '') == 'completada').length;

    final entregas = <Map<String, dynamic>>[];
    final weekCounts = List<int>.filled(7, 0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDays = today.add(const Duration(days: 7));

    for (final t in pendientes) {
      final fechaTexto = (t['fecha_vencimiento'] ?? '').toString();
      final fecha = DateTime.tryParse(fechaTexto);

      if (fecha != null) {
        final index = fecha.weekday - 1;

        if (index >= 0 && index < 7) {
          weekCounts[index]++;
        }

        if (!fecha.isBefore(today) && !fecha.isAfter(sevenDays)) {
          entregas.add({
            'tipo': 'Tarea',
            'titulo': t['titulo'],
            'fecha': fechaTexto,
            'fechaDate': fecha,
          });
        }
      }
    }

    for (final p in proyectos) {
      final fechaTexto = (p['fecha_fin'] ?? '').toString();
      final fecha = DateTime.tryParse(fechaTexto);

      if (fecha != null && ((p['avance_porcentual'] ?? 0) as int) < 100) {
        if (!fecha.isBefore(today) && !fecha.isAfter(sevenDays)) {
          entregas.add({
            'tipo': 'Proyecto',
            'titulo': p['titulo'],
            'fecha': fechaTexto,
            'fechaDate': fecha,
          });
        }
      }
    }

    entregas.sort(
      (a, b) => (a['fecha'] ?? '')
          .toString()
          .compareTo((b['fecha'] ?? '').toString()),
    );

    if (!mounted) return;

    setState(() {
      materiasActivas = materias.length;
      tareasPendientes = pendientes.length;
      tareasCompletadas = completadas;
      proyectosActivos = activos;
      metasCompletadas = metasDone;
      metasTotales = metas.length;
      proximasEntregas = entregas.take(5).toList();
      tareasPorDia = weekCounts;
      isLoading = false;
    });
  }

  String _friendlyName(String rawName) {
    final clean = rawName.trim();

    if (clean.toLowerCase().contains('maria')) return 'María';
    if (clean.isEmpty) return 'María';

    final first = clean.split(' ').first;

    return first[0].toUpperCase() + first.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = _auth.currentUser?.nombre ?? 'María';
    final primerNombre = _friendlyName(nombreCompleto);
    final totalTareas = tareasPendientes + tareasCompletadas;
    final progreso = totalTareas == 0 ? 0.0 : tareasCompletadas / totalTareas;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                nombre: primerNombre,
                onProfile: () => context.go('/perfil'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StatsGrid(
                    materiasActivas: materiasActivas,
                    tareasPendientes: tareasPendientes,
                    proyectosActivos: proyectosActivos,
                    metasCompletadas: metasCompletadas,
                    metasTotales: metasTotales,
                  ),
                  const SizedBox(height: 18),
                  _ProgressCard(
                    completadas: tareasCompletadas,
                    total: totalTareas,
                    progreso: progreso,
                  ),
                  const SizedBox(height: 18),
                  _WeeklyLoadCard(values: tareasPorDia),
                  const SizedBox(height: 18),
                  if (isLoading)
                    const SizedBox(height: 0)
                  else
                    _DeliveriesCard(entregas: proximasEntregas),
                  const SizedBox(height: 18),
                  _ShortcutsGrid(
                    onTap: (route) => context.go(route),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.nombre,
    required this.onProfile,
  });

  final String nombre;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 38, 20, 24),
      decoration: const BoxDecoration(
        color: _HomePageState._primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola $nombre ! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Organiza tu semestre universitario',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ir a perfil',
            onPressed: onProfile,
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.materiasActivas,
    required this.tareasPendientes,
    required this.proyectosActivos,
    required this.metasCompletadas,
    required this.metasTotales,
  });

  final int materiasActivas;
  final int tareasPendientes;
  final int proyectosActivos;
  final int metasCompletadas;
  final int metasTotales;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 0,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Materias\nActivas',
          value: '$materiasActivas',
        ),
        _StatCard(
          title: 'Tareas\nPendientes',
          value: '$tareasPendientes',
        ),
        _StatCard(
          title: 'Proyectos\nActivos',
          value: '$proyectosActivos',
        ),
        _StatCard(
          title: 'Metas del\nSemestre',
          value: '$metasCompletadas/$metasTotales',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _HomePageState._border,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _HomePageState._textMuted,
              fontSize: 15,
              height: 1.12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completadas,
    required this.total,
    required this.progreso,
  });

  final int completadas;
  final int total;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    final porcentaje = (progreso * 100).round();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso de Tareas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 12,
              backgroundColor: const Color(0xFFE0DBFF),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _HomePageState._primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$completadas de $total tareas completadas ($porcentaje%)',
            style: const TextStyle(
              color: _HomePageState._textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyLoadCard extends StatelessWidget {
  const _WeeklyLoadCard({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carga Académica Semanal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tareas pendientes por día',
            style: TextStyle(
              color: _HomePageState._textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _WeeklyPainter(values),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPainter extends CustomPainter {
  _WeeklyPainter(this.values);

  final List<int> values;
  final labels = const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDCDCE2)
      ..strokeWidth = 1.2;

    final barPaint = Paint()
      ..color = _HomePageState._primary
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final axisText = const TextStyle(
      color: Colors.grey,
      fontSize: 14,
    );

    final maxValue = [4, ...values].reduce((a, b) => a > b ? a : b);

    const left = 30.0;
    const bottom = 38.0;

    final chartWidth = size.width - left - 8;
    final chartHeight = size.height - bottom - 8;

    for (var i = 0; i <= 4; i++) {
      final value = maxValue * (4 - i) / 4;
      final y = 8 + chartHeight * i / 4;

      _drawDashedLine(
        canvas,
        Offset(left, y),
        Offset(size.width, y),
        gridPaint,
      );

      _drawText(
        canvas,
        value.round().toString(),
        Offset(0, y - 10),
        axisText,
      );
    }

    final gap = chartWidth / labels.length;

    for (var i = 0; i < labels.length; i++) {
      final x = left + gap * i + gap / 2;

      _drawText(
        canvas,
        labels[i],
        Offset(x - 16, size.height - 26),
        axisText,
      );

      final value = values.length > i ? values[i] : 0;

      if (value > 0) {
        final y = 8 + chartHeight - (value / maxValue) * chartHeight;
        canvas.drawLine(
          Offset(x, 8 + chartHeight),
          Offset(x, y),
          barPaint,
        );
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dash = 7.0;
    const space = 5.0;

    var x = start.dx;

    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(((x + dash).clamp(start.dx, end.dx)).toDouble(), end.dy),
        paint,
      );

      x += dash + space;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _DeliveriesCard extends StatelessWidget {
  const _DeliveriesCard({required this.entregas});

  final List<Map<String, dynamic>> entregas;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Próximas Entregas (7 días)',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (entregas.isEmpty)
            const Text(
              'No tiene entregas pendientes',
              style: TextStyle(
                color: _HomePageState._textMuted,
                fontSize: 15,
              ),
            )
          else
            ...entregas.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '• ${e['titulo']} · ${_formatDate(e['fechaDate'])}',
                  style: const TextStyle(
                    color: _HomePageState._textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic fecha) {
    if (fecha is DateTime) {
      return DateFormat('dd/MM/yyyy').format(fecha);
    }

    return 'Sin fecha';
  }
}

class _ShortcutsGrid extends StatelessWidget {
  const _ShortcutsGrid({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _ShortcutItem(
        Icons.menu_book_outlined,
        'Materias',
        '/materias',
      ),
      _ShortcutItem(
        Icons.checklist_outlined,
        'Tareas',
        '/tareas',
      ),
      _ShortcutItem(
        Icons.trending_up,
        'Proyectos',
        '/proyectos',
      ),
      _ShortcutItem(
        Icons.timer_outlined,
        'Pomodoro',
        '/pomodoro',
      ),
      _ShortcutItem(
        Icons.calendar_month_outlined,
        'Calendario',
        '/calendario',
      ),
      _ShortcutItem(
        Icons.adjust,
        'Metas',
        '/metas',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 0,
      mainAxisSpacing: 12,
      childAspectRatio: 2.15,
      children: items
          .map(
            (item) => _ShortcutCard(
              item: item,
              onTap: onTap,
            ),
          )
          .toList(),
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem(
    this.icon,
    this.label,
    this.route,
  );

  final IconData icon;
  final String label;
  final String route;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.item,
    required this.onTap,
  });

  final _ShortcutItem item;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onTap(item.route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _HomePageState._border,
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 26),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _HomePageState._border,
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}
