import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:helloworld/core/services/local_data_store.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  final _store = LocalDataStore.instance;

  List<Map<String, dynamic>> eventos = [];
  bool loading = true;

  DateTime visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  static const Color primary = Color(0xFF5B4CF0);
  static const Color textDark = Color(0xFF20202A);
  static const Color textMuted = Color(0xFF7C7C90);
  static const Color border = Color(0xFFE4E4EC);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _store.initialize();

    final tareas = await _store.getTareas();
    final proyectos = await _store.getProyectos();

    final data = <Map<String, dynamic>>[];

    for (final t in tareas) {
      final fecha = t['fecha_vencimiento'];

      if (fecha != null && fecha.toString().isNotEmpty) {
        data.add({
          'tipo': 'Tarea',
          'titulo': t['titulo'] ?? 'Sin título',
          'materia': t['materia_nombre'] ?? 'Sin materia',
          'fecha': fecha,
        });
      }
    }

    for (final p in proyectos) {
      final fecha = p['fecha_fin'];

      if (fecha != null && fecha.toString().isNotEmpty) {
        data.add({
          'tipo': 'Proyecto',
          'titulo': p['titulo'] ?? 'Sin título',
          'materia': 'Proyecto',
          'fecha': fecha,
        });
      }
    }

    data.sort(
      (a, b) => (a['fecha'] ?? '')
          .toString()
          .compareTo((b['fecha'] ?? '').toString()),
    );

    if (!mounted) return;

    setState(() {
      eventos = data;
      loading = false;
    });
  }

  List<Map<String, dynamic>> get _eventos30Dias {
    final hoy = DateTime.now();
    final limite = hoy.add(const Duration(days: 30));

    return eventos.where((e) {
      final fecha = DateTime.tryParse((e['fecha'] ?? '').toString());
      if (fecha == null) return false;

      final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);

      return !fecha.isBefore(hoySolo) && !fecha.isAfter(limite);
    }).toList();
  }

  String _formatFechaCorta(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';

    final date = DateTime.tryParse(fecha);
    if (date == null) return fecha;

    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${dias[date.weekday - 1]}, ${date.day} ${meses[date.month - 1]}';
  }

  void _prevMonth() {
    setState(() {
      visibleMonth = DateTime(
        visibleMonth.year,
        visibleMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      visibleMonth = DateTime(
        visibleMonth.year,
        visibleMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _HeaderCalendario(onBack: () => context.go('/home')),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        _CalendarMonth(
                          month: visibleMonth,
                          eventos: eventos,
                          onPrevious: _prevMonth,
                          onNext: _nextMonth,
                        ),
                        const SizedBox(height: 18),
                        if (loading)
                          const SizedBox(height: 120)
                        else
                          _UpcomingEventsCard(
                            eventos: _eventos30Dias,
                            formatFecha: _formatFechaCorta,
                          ),
                        const SizedBox(height: 18),
                        const _LegendCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeaderCalendario extends StatelessWidget {
  final VoidCallback onBack;

  const _HeaderCalendario({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
      decoration: const BoxDecoration(
        color: _CalendarioPageState.primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(30),
            child: const Padding(
              padding: EdgeInsets.only(top: 4, right: 12),
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
                  'Calendario Académico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Visualiza tus fechas importantes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
}

class _CalendarMonth extends StatelessWidget {
  final DateTime month;
  final List<Map<String, dynamic>> eventos;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _CalendarMonth({
    required this.month,
    required this.eventos,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final previousMonthLastDay = DateTime(month.year, month.month, 0);

    final startWeekday = firstDay.weekday;
    final totalDays = lastDay.day;
    final today = DateTime.now();

    final eventDays = eventos.map((e) {
      final date = DateTime.tryParse((e['fecha'] ?? '').toString());
      if (date == null) return -1;

      if (date.year == month.year && date.month == month.month) {
        return date.day;
      }

      return -1;
    }).toSet();

    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CalendarioPageState.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left, size: 28),
              ),
              Expanded(
                child: Text(
                  '${_monthName(month.month)} De ${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _CalendarioPageState.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: weekdays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: _CalendarioPageState.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (startWeekday - 1);

              late final int day;
              late final bool isCurrentMonth;

              if (dayOffset < 0) {
                day = previousMonthLastDay.day + dayOffset + 1;
                isCurrentMonth = false;
              } else if (dayOffset >= totalDays) {
                day = dayOffset - totalDays + 1;
                isCurrentMonth = false;
              } else {
                day = dayOffset + 1;
                isCurrentMonth = true;
              }

              final isToday = isCurrentMonth &&
                  today.year == month.year &&
                  today.month == month.month &&
                  today.day == day;

              final hasEvent = isCurrentMonth && eventDays.contains(day);

              return Container(
                decoration: BoxDecoration(
                  color: isToday ? _CalendarioPageState.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasEvent || isToday
                        ? const Color(0xFFA699FF)
                        : const Color(0xFFE4E4EC),
                    width: hasEvent || isToday ? 1.3 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: !isCurrentMonth
                            ? const Color(0xFFB9B9C3)
                            : isToday
                                ? Colors.white
                                : Colors.black,
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    if (hasEvent && !isToday)
                      const Positioned(
                        bottom: 2,
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            height: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return months[month - 1];
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  final List<Map<String, dynamic>> eventos;
  final String Function(String?) formatFecha;

  const _UpcomingEventsCard({
    required this.eventos,
    required this.formatFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CalendarioPageState.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 23),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Próximos eventos',
                  style: TextStyle(
                    color: _CalendarioPageState.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (eventos.isEmpty)
            const Text(
              'No hay eventos próximos',
              style: TextStyle(
                color: _CalendarioPageState.textMuted,
                fontSize: 14,
              ),
            )
          else
            ...eventos.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(
                  titulo: (e['titulo'] ?? '').toString(),
                  materia: (e['materia'] ?? 'Sin materia').toString(),
                  tipo: (e['tipo'] ?? '').toString(),
                  fecha: formatFecha((e['fecha'] ?? '').toString()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String titulo;
  final String materia;
  final String tipo;
  final String fecha;

  const _EventCard({
    required this.titulo,
    required this.materia,
    required this.tipo,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _CalendarioPageState.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: _CalendarioPageState.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            materia,
            style: const TextStyle(
              color: _CalendarioPageState.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _CalendarioPageState.border),
                ),
                child: Text(
                  tipo,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                fecha,
                style: const TextStyle(
                  color: _CalendarioPageState.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CalendarioPageState.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(
            color: _CalendarioPageState.primary,
            text: 'Día actual',
            filled: true,
          ),
          SizedBox(height: 14),
          _LegendItem(
            color: _CalendarioPageState.primary,
            text: 'Días con eventos',
            filled: false,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final bool filled;

  const _LegendItem({
    required this.color,
    required this.text,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: filled ? color : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1.4),
          ),
          child: filled
              ? null
              : const Center(
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1,
                      color: Colors.black,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            color: _CalendarioPageState.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
