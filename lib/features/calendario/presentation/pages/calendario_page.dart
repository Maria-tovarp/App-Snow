import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snow/core/widgets/app_drawer.dart';
import 'package:snow/core/widgets/app_section_header.dart';

import 'package:snow/core/services/local_data_store.dart';

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
  DateTime selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  static const Color primary = Color(0xFF5B4CF0);
  static const Color textDark = Color(0xFF20202A);
  static const Color textMuted = Color(0xFF7C7C90);
  static const Color border = Color(0xFFE4E4EC);

  @override
  void initState() {
    super.initState();
    if (_store.hasCached('tareas') || _store.hasCached('proyectos')) {
      eventos = _buildEvents(
        _store.cached('tareas'),
        _store.cached('proyectos'),
      );
      loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _store.getTareas(),
      _store.getProyectos(),
    ]);
    final data = _buildEvents(results[0], results[1]);

    if (!mounted) return;

    setState(() {
      eventos = data;
      loading = false;
    });
  }

  List<Map<String, dynamic>> _buildEvents(
    List<Map<String, dynamic>> tareas,
    List<Map<String, dynamic>> proyectos,
  ) {
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

    return data;
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

  List<Map<String, dynamic>> get _eventosDelDia {
    return eventos.where((e) {
      final fecha = DateTime.tryParse(
        (e['fecha'] ?? '').toString(),
      );

      if (fecha == null) return false;

      return fecha.year == selectedDay!.year &&
          fecha.month == selectedDay!.month &&
          fecha.day == selectedDay!.day;
    }).toList();
  }

  String get _tituloEventos {
    if (selectedDay == null) {
      return 'Próximos eventos';
    }

    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final fecha = selectedDay!;

    return 'Eventos del ${dias[fecha.weekday - 1]} ${fecha.day} de ${meses[fecha.month - 1]}';
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

      final hoy = DateTime.now();

      if (visibleMonth.year == hoy.year && visibleMonth.month == hoy.month) {
        selectedDay = DateTime(
          hoy.year,
          hoy.month,
          hoy.day,
        );
      } else {
        selectedDay = DateTime(
          visibleMonth.year,
          visibleMonth.month,
          1,
        );
      }
    });
  }

  void _nextMonth() {
    setState(() {
      visibleMonth = DateTime(
        visibleMonth.year,
        visibleMonth.month + 1,
      );

      final hoy = DateTime.now();

      if (visibleMonth.year == hoy.year && visibleMonth.month == hoy.month) {
        selectedDay = DateTime(
          hoy.year,
          hoy.month,
          hoy.day,
        );
      } else {
        selectedDay = DateTime(
          visibleMonth.year,
          visibleMonth.month,
          1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRoute: '/calendario'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HeaderCalendario(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  const _LegendCard(),
                  const SizedBox(height: 14),
                  _CalendarMonth(
                    month: visibleMonth,
                    eventos: eventos,
                    selectedDay: selectedDay,
                    onPrevious: _prevMonth,
                    onNext: _nextMonth,
                    onDaySelected: (day) {
                      setState(() {
                        final hoy = DateTime.now();

                        final mismaFecha = selectedDay.year == day.year &&
                            selectedDay.month == day.month &&
                            selectedDay.day == day.day;

                        if (mismaFecha) {
                          if (visibleMonth.year == hoy.year &&
                              visibleMonth.month == hoy.month) {
                            selectedDay = DateTime(
                              hoy.year,
                              hoy.month,
                              hoy.day,
                            );
                          } else {
                            selectedDay = DateTime(
                              visibleMonth.year,
                              visibleMonth.month,
                              1,
                            );
                          }
                        } else {
                          selectedDay = day;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (loading)
                    const SizedBox(height: 120)
                  else
                    _UpcomingEventsCard(
                      titulo: _tituloEventos,
                      mensajeVacio: 'No hay eventos para este día.',
                      eventos: _eventosDelDia,
                      formatFecha: _formatFechaCorta,
                      animationKey: ValueKey(
                        '${selectedDay.year}-${selectedDay.month}-${selectedDay.day}',
                      ),
                    ),
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
  const _HeaderCalendario();

  @override
  Widget build(BuildContext context) {
    return const AppSectionHeader(
      title: 'Calendario Académico',
      subtitle: 'Visualiza tus fechas importantes',
    );
  }
}

class _CalendarMonth extends StatelessWidget {
  final DateTime month;
  final List<Map<String, dynamic>> eventos;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDaySelected;
  final DateTime? selectedDay;

  const _CalendarMonth({
    required this.month,
    required this.eventos,
    required this.onPrevious,
    required this.onNext,
    required this.onDaySelected,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF393947) : _CalendarioPageState.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F0FF),
                  foregroundColor: _CalendarioPageState.primary,
                ),
                icon: const Icon(Icons.chevron_left, size: 24),
              ),
              Expanded(
                child: Text(
                  '${_monthName(month.month)} de ${month.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F0FF),
                  foregroundColor: _CalendarioPageState.primary,
                ),
                icon: const Icon(Icons.chevron_right, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 18),
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

              final isSelected = selectedDay != null &&
                  isCurrentMonth &&
                  selectedDay!.year == month.year &&
                  selectedDay!.month == month.month &&
                  selectedDay!.day == day;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: isCurrentMonth
                    ? () => onDaySelected(
                          DateTime(month.year, month.month, day),
                        )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _CalendarioPageState.primary
                        : isToday
                            ? (isDark
                                ? const Color(0xFF302B5E)
                                : const Color(0xFFF3F0FF))
                            : (isDark
                                ? const Color(0xFF242534)
                                : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? _CalendarioPageState.primary
                          : isToday
                              ? _CalendarioPageState.primary
                              : hasEvent
                                  ? const Color(0xFFA699FF)
                                  : (isDark
                                      ? const Color(0xFF414154)
                                      : const Color(0xFFE4E4EC)),
                      width: isToday || isSelected || hasEvent ? 1.5 : 1,
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
                              : isSelected
                                  ? Colors.white
                                  : colors.onSurface,
                          fontSize: 13,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      if (hasEvent && !isToday)
                        const Positioned(
                          bottom: 2,
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: _CalendarioPageState.primary,
                          ),
                        ),
                    ],
                  ),
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
  final String titulo;
  final String mensajeVacio;
  final Key animationKey;

  const _UpcomingEventsCard({
    required this.eventos,
    required this.formatFecha,
    required this.titulo,
    required this.mensajeVacio,
    required this.animationKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF393947) : _CalendarioPageState.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: eventos.isEmpty
                ? Container(
                    key: const ValueKey('sin_eventos'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF292934)
                          : const Color(0xFFF7F6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAE7FF),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.event_available_outlined,
                            color: _CalendarioPageState.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            mensajeVacio,
                            style: const TextStyle(
                              color: _CalendarioPageState.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: animationKey,
                    children: eventos
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              titulo: (e['titulo'] ?? '').toString(),
                              materia:
                                  (e['materia'] ?? 'Sin materia').toString(),
                              tipo: (e['tipo'] ?? '').toString(),
                              fecha: formatFecha((e['fecha'] ?? '').toString()),
                            ),
                          ),
                        )
                        .toList(),
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF393947) : _CalendarioPageState.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: colors.onSurface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF393947)
              : _CalendarioPageState.border,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _LegendItem(
              color: _CalendarioPageState.primary,
              text: 'Día actual',
              filled: true,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _LegendItem(
              color: _CalendarioPageState.primary,
              text: 'Días con eventos',
              filled: false,
            ),
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: filled
                  ? color
                  : (isDark ? const Color(0xFF292934) : Colors.white),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color, width: 1.4),
            ),
            child: filled
                ? null
                : const Center(
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: _CalendarioPageState.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
