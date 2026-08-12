import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:snow/core/widgets/app_drawer.dart';
import 'package:snow/core/widgets/app_section_header.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:snow/core/services/local_data_store.dart';
import 'package:snow/features/horario/data/horario_model.dart';
import 'package:snow/features/horario/data/horario_repository.dart';

class HorarioPage extends StatefulWidget {
  const HorarioPage({super.key});

  @override
  State<HorarioPage> createState() => _HorarioPageState();
}

class _HorarioPageState extends State<HorarioPage> {
  static const _primary = Color(0xFF5B4CF0);
  static const _muted = Color(0xFF7C7C90);
  static const _border = Color(0xFFE4E4EC);
  final _repository = HorarioRepository();
  final _store = LocalDataStore.instance;
  final _scheduleKey = GlobalKey();
  List<HorarioModel> _classes = [];
  List<Map<String, dynamic>> _materias = [];
  bool _loading = true;
  bool _exportingSchedule = false;
  bool _generatingPdf = false;
  double _pdfProgress = 0;

  @override
  void initState() {
    super.initState();
    if (_store.hasCached('materias')) {
      _materias = _store.cached('materias');
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object?>([
        _repository.getHorarios(),
        _store.getMaterias(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = results[0] as List<HorarioModel>;
        _materias = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el horario: $error')),
      );
    }
  }

  Future<void> _openForm([HorarioModel? horario]) async {
    if (_materias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes crear una materia.')),
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _HorarioFormDialog(
        horario: horario,
        materias: _materias,
        repository: _repository,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(HorarioModel horario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text('¿Deseas eliminar ${horario.materiaNombre} del horario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteHorario(horario.id);
    await _load();
  }

  Future<void> _downloadImage() async {
    try {
      if (!mounted) return;
      setState(() => _exportingSchedule = true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await WidgetsBinding.instance.endOfFrame;

      var boundary = _scheduleKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('El horario aún no está listo.');
      for (var attempt = 0;
          boundary!.debugNeedsPaint && attempt < 5;
          attempt++) {
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 20));

        boundary = _scheduleKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) {
          throw Exception('El horario todavía no está listo.');
        }
      }

      if (boundary!.debugNeedsPaint) {
        throw Exception('Espera un momento e intenta descargar nuevamente.');
      }

      final image = await boundary!.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('No se pudo generar la imagen.');
      await FileSaver.instance.saveFile(
        name: 'horario_snow',
        bytes: data.buffer.asUint8List(),
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      _showDownloadMessage('Imagen descargada correctamente.');
    } catch (error) {
      _showDownloadMessage('No se pudo descargar la imagen: $error', true);
    } finally {
      if (mounted) {
        setState(() => _exportingSchedule = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    try {
      if (!mounted) return;
      setState(() {
        _exportingSchedule = true;
        _generatingPdf = true;
        _pdfProgress = 0.08;
      });
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) setState(() => _pdfProgress = 0.22);

      var boundary = _scheduleKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('El horario todavía no está listo.');
      }

      for (var attempt = 0;
          boundary!.debugNeedsPaint && attempt < 5;
          attempt++) {
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        boundary = _scheduleKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) {
          throw Exception('El horario todavía no está listo.');
        }
      }

      if (boundary!.debugNeedsPaint) {
        throw Exception('Espera un momento e intenta descargar nuevamente.');
      }
      if (mounted) setState(() => _pdfProgress = 0.38);

      final renderedImage = await boundary!.toImage(pixelRatio: 1.3);
      if (mounted) setState(() => _pdfProgress = 0.55);
      final imageData =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      if (imageData == null) {
        throw Exception('No se pudo generar la cuadrícula del horario.');
      }

      if (mounted) setState(() => _pdfProgress = 0.68);

      final scheduleImage = pw.MemoryImage(
        imageData.buffer.asUint8List(),
      );
      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Horario semanal · Snow',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xFF5B4CF0),
                    fontSize: 21,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(
                    scheduleImage,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (mounted) setState(() => _pdfProgress = 0.82);
      final pdfBytes = await document.save();
      if (mounted) setState(() => _pdfProgress = 0.94);

      await FileSaver.instance.saveFile(
        name: 'horario_snow',
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (mounted) {
        setState(() => _pdfProgress = 1);
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
      _showDownloadMessage('PDF descargado correctamente.');
    } catch (error) {
      _showDownloadMessage('No se pudo descargar el PDF: $error', true);
    } finally {
      if (mounted) {
        setState(() {
          _exportingSchedule = false;
          _generatingPdf = false;
          _pdfProgress = 0;
        });
      }
    }
  }

  Future<void> _downloadPdfLegacy() async {
    try {
      final document = pw.Document();
      final sorted = [..._classes]..sort((a, b) {
          final day = a.diaSemana.compareTo(b.diaSemana);
          return day != 0 ? day : a.horaInicio.compareTo(b.horaInicio);
        });
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [
            pw.Text(
              'Horario semanal - Snow',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 18),
            pw.Table.fromTextArray(
              headers: const [
                'Día',
                'Materia',
                'Profesor',
                'Salón',
                'Inicio',
                'Fin',
              ],
              data: sorted
                  .map((item) => [
                        _dayName(item.diaSemana),
                        item.materiaNombre,
                        item.profesor,
                        item.salon,
                        item.horaInicio,
                        item.horaFin,
                      ])
                  .toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF5B4CF0),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              cellPadding: const pw.EdgeInsets.all(8),
              border: pw.TableBorder.all(color: PdfColors.grey300),
            ),
          ],
        ),
      );
      await FileSaver.instance.saveFile(
        name: 'horario_snow',
        bytes: await document.save(),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      _showDownloadMessage('PDF descargado correctamente.');
    } catch (error) {
      _showDownloadMessage('No se pudo descargar el PDF: $error', true);
    }
  }

  void _showDownloadMessage(String message, [bool error = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.redAccent : _primary,
      ),
    );
  }

  Future<void> _showDownloadOptions() async {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF5A5A6A)
                        : const Color(0xFFD9D9E3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Descargar horario',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona el formato que deseas guardar',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _DownloadOption(
                icon: Icons.image_outlined,
                title: 'Imagen PNG',
                subtitle: 'Guarda la cuadrícula como imagen',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 260),
                  );
                  if (mounted) await _downloadImage();
                },
              ),
              const SizedBox(height: 10),
              _DownloadOption(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Documento PDF',
                subtitle: 'Guarda la cuadrícula en una página PDF',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 260),
                  );
                  if (mounted) await _downloadPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dayName(int day) => const [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
      ][day - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRoute: '/horario'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Agregar clase'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(36),
                              child: CircularProgressIndicator(color: _primary),
                            ),
                          )
                        else
                          _WeeklyTimetable(
                            classes: _classes,
                            captureKey: _scheduleKey,
                            highlightToday: !_exportingSchedule,
                            onClassTap: _openForm,
                            onClassLongPress: _delete,
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_generatingPdf)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x66000000),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: _pdfProgress,
                          ),
                          duration: const Duration(milliseconds: 350),
                          builder: (context, value, _) => SizedBox(
                            width: 46,
                            height: 46,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  color: _primary,
                                  backgroundColor: const Color(0xFFE7E5FA),
                                  strokeWidth: 4,
                                ),
                                Text(
                                  '${(value * 100).round()}%',
                                  style: const TextStyle(
                                    color: _primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Generando PDF…',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Preparando la cuadrícula completa',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AppSectionHeader(
      title: 'Horario semanal',
      subtitle: 'Organiza tus clases de la semana',
      actions: [
          IconButton(
            tooltip: 'Descargar horario',
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _showDownloadOptions,
          ),
      ],
    );
  }
}

class _DownloadOption extends StatelessWidget {
  const _DownloadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _HorarioPageState._primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _HorarioPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyTimetable extends StatelessWidget {
  const _WeeklyTimetable({
    required this.classes,
    required this.captureKey,
    required this.highlightToday,
    required this.onClassTap,
    required this.onClassLongPress,
  });

  static const _headerHeight = 52.0;
  static const _hourHeight = 56.0;
  static const _timeWidth = 48.0;
  static const _minimumDayWidth = 86.0;
  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  final List<HorarioModel> classes;
  final GlobalKey captureKey;
  final bool highlightToday;
  final ValueChanged<HorarioModel> onClassTap;
  final ValueChanged<HorarioModel> onClassLongPress;

  List<int> get _visibleDays {
    final days = classes
        .map((item) => item.diaSemana)
        .where((day) => day >= 1 && day <= _days.length)
        .toSet()
        .toList()
      ..sort();

    return days.isEmpty ? const [1, 2, 3, 4, 5] : days;
  }

  int get _startHour {
    if (classes.isEmpty) return 7;
    final earliest = classes
        .map((item) => _minutes(item.horaInicio) ~/ 60)
        .reduce((a, b) => a < b ? a : b);
    return (earliest - 1).clamp(5, 20).toInt();
  }

  int get _endHour {
    if (classes.isEmpty) return 19;
    final latest = classes.map((item) {
      final minutes = _minutes(item.horaFin);
      return (minutes / 60).ceil();
    }).reduce((a, b) => a > b ? a : b);
    return (latest + 1).clamp(_startHour + 3, 23).toInt();
  }

  double get _totalHeight =>
      _headerHeight + (_endHour - _startHour) * _hourHeight;

  int _minutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return _startHour * 60;
    return (int.tryParse(parts[0]) ?? _startHour) * 60 +
        (int.tryParse(parts[1]) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableBackground =
        isDark ? const Color(0xFF1C1D2A) : Colors.white;
    final headerBackground =
        isDark ? const Color(0xFF242534) : const Color(0xFFF8F7FF);
    final todayBackground =
        isDark ? const Color(0xFF22233A) : const Color(0xFFFAF9FF);
    final gridColor =
        isDark ? const Color(0xFF343445) : const Color(0xFFECECF2);
    return Container(
      decoration: BoxDecoration(
        color: tableBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _HorarioPageState._border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleDays = _visibleDays;
          final minimumWidth =
              _timeWidth + (_minimumDayWidth * visibleDays.length);
          final tableWidth = constraints.maxWidth < minimumWidth
              ? minimumWidth
              : constraints.maxWidth;
          final dayWidth = (tableWidth - _timeWidth) / visibleDays.length;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: RepaintBoundary(
              key: captureKey,
              child: SizedBox(
                width: tableWidth,
                height: _totalHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: ColoredBox(color: tableBackground)),
                    ...List.generate(visibleDays.length, (index) {
                      final day = visibleDays[index];
                      if (!highlightToday || DateTime.now().weekday != day) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        left: _timeWidth + index * dayWidth,
                        top: _headerHeight,
                        bottom: 0,
                        width: dayWidth,
                        child: ColoredBox(color: todayBackground),
                      );
                    }),
                    ...List.generate(visibleDays.length + 1, (index) {
                      final left = _timeWidth + index * dayWidth;
                      return Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        child:
                            Container(width: 1, color: gridColor),
                      );
                    }),
                    ...List.generate(_endHour - _startHour + 1, (index) {
                      final top = _headerHeight + index * _hourHeight;
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: top,
                        child: Container(height: 1, color: gridColor),
                      );
                    }),
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      height: _headerHeight,
                      child: Container(color: headerBackground),
                    ),
                    ...List.generate(visibleDays.length, (index) {
                      final day = visibleDays[index];
                      final isToday =
                          highlightToday && DateTime.now().weekday == day;
                      return Positioned(
                        left: _timeWidth + index * dayWidth,
                        top: 0,
                        width: dayWidth,
                        height: _headerHeight,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? _HorarioPageState._primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _days[day - 1],
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : _HorarioPageState._muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    ...List.generate(_endHour - _startHour, (index) {
                      final hour = _startHour + index;
                      return Positioned(
                        left: 0,
                        top: _headerHeight + index * _hourHeight - 7,
                        width: _timeWidth - 5,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: _HorarioPageState._muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                    ...classes.where((item) {
                      final start = _minutes(item.horaInicio);
                      return visibleDays.contains(item.diaSemana) &&
                          start < _endHour * 60 &&
                          _minutes(item.horaFin) > _startHour * 60;
                    }).map(
                      (item) => _classBlock(
                        item,
                        dayWidth,
                        visibleDays.indexOf(item.diaSemana),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _classBlock(
    HorarioModel item,
    double dayWidth,
    int columnIndex,
  ) {
    final start = _minutes(item.horaInicio)
        .clamp(
          _startHour * 60,
          _endHour * 60,
        )
        .toInt();
    final end = _minutes(item.horaFin)
        .clamp(
          _startHour * 60,
          _endHour * 60,
        )
        .toInt();
    final top =
        _headerHeight + (start - _startHour * 60) / 60 * _hourHeight + 2;
    final height =
        ((end - start) / 60 * _hourHeight - 4).clamp(42.0, 500.0).toDouble();
    final color = Color(item.color);
    final foreground = Color.lerp(
      color,
      const Color(0xFF34343D),
      0.48,
    )!;
    final cardColor = Color.alphaBlend(
      color.withOpacity(0.58),
      Colors.white,
    );

    return Positioned(
      left: _timeWidth + columnIndex * dayWidth + 4,
      top: top,
      width: dayWidth - 8,
      height: height,
      child: Material(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: color.withOpacity(0.78),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onClassTap(item),
          onLongPress: () => onClassLongPress(item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.materiaNombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (height >= 58) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.salon,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 8.5,
                    ),
                  ),
                ],
                if (height >= 82) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${item.horaInicio}–${item.horaFin}',
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorarioFormDialog extends StatefulWidget {
  const _HorarioFormDialog({
    required this.horario,
    required this.materias,
    required this.repository,
  });

  final HorarioModel? horario;
  final List<Map<String, dynamic>> materias;
  final HorarioRepository repository;

  @override
  State<_HorarioFormDialog> createState() => _HorarioFormDialogState();
}

class _MateriaDetailsCard extends StatelessWidget {
  const _MateriaDetailsCard({
    required this.profesor,
    required this.color,
  });

  final String profesor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconColor = Color.lerp(
      color,
      const Color(0xFF34343D),
      0.48,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profesor de la materia',
                  style: TextStyle(
                    color: _HorarioPageState._muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profesor.trim().isEmpty ? 'Sin profesor' : profesor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _HorarioFormDialogState extends State<_HorarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _salon;
  late String _materiaId;
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.horario;
    _salon = TextEditingController(text: item?.salon ?? '');
    _materiaId = item?.materiaId ?? widget.materias.first['id'].toString();
    _day = item?.diaSemana ?? 1;
    _start =
        _parseTime(item?.horaInicio) ?? const TimeOfDay(hour: 7, minute: 0);
    _end = _parseTime(item?.horaFin) ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _salon.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _databaseTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> get _selectedMateria => widget.materias.firstWhere(
        (item) => item['id'].toString() == _materiaId,
      );

  Color get _selectedMateriaColor {
    final text = (_selectedMateria['color'] ?? '').toString().trim();
    if (text.startsWith('#')) {
      return Color(
        int.tryParse('FF${text.substring(1)}', radix: 16) ?? 0xFF5B4CF0,
      );
    }
    return Color(int.tryParse(text) ?? 0xFF5B4CF0);
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value == null) return;
    setState(() => start ? _start = value : _end = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profesor = (_selectedMateria['profesor'] ?? '').toString().trim();
    if (profesor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La materia seleccionada no tiene profesor. Edítala antes de continuar.',
          ),
        ),
      );
      return;
    }
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora final debe ser posterior.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final item = widget.horario;
      if (item == null) {
        await widget.repository.createHorario(
          materiaId: _materiaId,
          profesor: profesor,
          salon: _salon.text.trim(),
          diaSemana: _day,
          horaInicio: _databaseTime(_start),
          horaFin: _databaseTime(_end),
        );
      } else {
        await widget.repository.updateHorario(
          id: item.id,
          materiaId: _materiaId,
          profesor: profesor,
          salon: _salon.text.trim(),
          diaSemana: _day,
          horaInicio: _databaseTime(_start),
          horaFin: _databaseTime(_end),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    }
  }

  Future<void> _deleteClass() async {
    final item = widget.horario;
    if (item == null || _saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFFECEC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFE5484D),
          ),
        ),
        title: const Text(
          'Eliminar clase',
          textAlign: TextAlign.center,
        ),
        content: Text(
          '¿Deseas eliminar ${item.materiaNombre} de tu horario?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5484D),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await widget.repository.deleteHorario(item.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la clase: $error')),
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
      filled: true,
      fillColor: isDark ? const Color(0xFF292934) : const Color(0xFFF3F3F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : const Color(0x1A000000),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF342E5A)
                            : const Color(0xFFEDEAFF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.horario == null
                                ? 'Agregar clase'
                                : 'Editar clase',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Completa los datos de tu horario',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<String>(
                  value: _materiaId,
                  isExpanded: true,
                  decoration: _decoration('Materia', Icons.menu_book_outlined),
                  items: widget.materias
                      .map((item) => DropdownMenuItem(
                            value: item['id'].toString(),
                            child: Text((item['nombre'] ?? '').toString()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _materiaId = value);
                  },
                ),
                const SizedBox(height: 13),
                _MateriaDetailsCard(
                  profesor: (_selectedMateria['profesor'] ?? 'Sin profesor')
                      .toString(),
                  color: _selectedMateriaColor,
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _salon,
                  textInputAction: TextInputAction.done,
                  decoration: _decoration('Salón', Icons.meeting_room_outlined),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el salón'
                      : null,
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<int>(
                  value: _day,
                  decoration: _decoration('Día', Icons.today_outlined),
                  items: List.generate(
                    6,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(const [
                        'Lunes',
                        'Martes',
                        'Miércoles',
                        'Jueves',
                        'Viernes',
                        'Sábado',
                      ][index]),
                    ),
                  ),
                  onChanged: (value) => _day = value!,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Horario de la clase',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(child: _timeButton('Inicio', _start, true)),
                    const SizedBox(width: 10),
                    Expanded(child: _timeButton('Fin', _end, false)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: _HorarioPageState._primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
                if (widget.horario != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: const Color(0xFFE5484D),
                      side: const BorderSide(color: Color(0xFFFFC9CB)),
                      backgroundColor: const Color(0xFFFFF7F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _deleteClass,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Eliminar clase'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeButton(String label, TimeOfDay value, bool start) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF292934) : const Color(0xFFF3F3F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pickTime(start),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.format(context),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
