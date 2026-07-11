import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helloworld/core/services/local_data_store.dart';

import '../../data/proyecto_model.dart';
import '../../data/proyecto_repository.dart';

class ProyectosPage extends StatefulWidget {
  const ProyectosPage({super.key});

  @override
  State<ProyectosPage> createState() => _ProyectosPageState();
}

class _ProyectosPageState extends State<ProyectosPage> {
  final repo = ProyectoRepository();

  List<ProyectoModel> proyectos = [];
  bool loading = true;

  static const Color primary = Color(0xFF5B4CF0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await repo.getProyectos();
      if (!mounted) return;
      setState(() {
        proyectos = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando proyectos: $e')),
      );
    }
  }

  Future<bool?> _confirmDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.only(top: 26),
          title: Column(
            children: const [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Eliminar Proyecto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este proyecto?\n\n'
            'Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(
                        color: Color(0xFFD9D9E3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openCreateModal() {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _CreateProyectoModal(),
    ).then((value) {
      if (value == true) load();
    });
  }

  void _openEditModal(ProyectoModel proyecto) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CreateProyectoModal(proyecto: proyecto),
    ).then((value) {
      if (value == true) load();
    });
  }

  String _formatFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '--';
    final date = DateTime.tryParse(fecha);
    if (date == null) return '--';

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

    return '${date.day} ${meses[date.month - 1]}';
  }

  String _duracionLabel(String? inicio, String? fin) {
    if (inicio == null || fin == null) return '--';

    final fi = DateTime.tryParse(inicio);
    final ff = DateTime.tryParse(fin);

    if (fi == null || ff == null) return '--';

    final dias = ff.difference(fi).inDays;
    return '$dias días';
  }

  String _estadoProyecto(ProyectoModel p) {
    final hoy = DateTime.now();

    if (p.fechaFin == null) {
      return 'En progreso';
    }

    final fechaFin = DateTime.parse(p.fechaFin!);

    // Proyecto terminado
    if (p.avancePorcentual >= 100) {
      return 'Finalizado';
    }

    // Proyecto vencido
    if (fechaFin.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
      return 'Vencido';
    }

    // Días restantes
    final diasRestantes = fechaFin.difference(hoy).inDays;

    if (diasRestantes <= 3) {
      return 'Próximo a vencer';
    }

    return 'En progreso';
  }

  Color _colorEstadoProyecto(ProyectoModel p) {
    switch (_estadoProyecto(p)) {
      case 'Finalizado':
        return const Color(0xFF22C55E); // Verde

      case 'Vencido':
        return const Color(0xFFEF4444); // Rojo

      case 'Próximo a vencer':
        return const Color(0xFFF59E0B); // Amarillo

      default:
        return primary; // Morado de la app
    }
  }

  Future<void> _showUpdateProgressDialog(ProyectoModel proyecto) async {
    double avance = proyecto.avancePorcentual.toDouble();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: SizedBox()),
                        const Text(
                          'Actualizar avance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      proyecto.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8A8A9B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${avance.round()}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: avance,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) {
                        setDialogState(() {
                          avance = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          await repo.updateAvance(
                            id: proyecto.id,
                            avancePorcentual: avance.round(),
                          );

                          if (!mounted) return;

                          Navigator.pop(context);
                          load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFD9D9E3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final proyectosEnProgreso =
        proyectos.where((p) => p.avancePorcentual < 100).toList();

    final proyectosFinalizados =
        proyectos.where((p) => p.avancePorcentual >= 100).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _newProjectButton(),
                  const SizedBox(height: 18),
                  if (loading)
                    const SizedBox(height: 250)
                  else if (proyectos.isEmpty)
                    _emptyState()
                  else ...[
                    if (proyectosEnProgreso.isNotEmpty) ...[
                      Text(
                        'En Progreso',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      ...proyectosEnProgreso.map(_projectCard),
                    ],
                    if (proyectosFinalizados.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Finalizados',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      ...proyectosFinalizados.map(_projectCard),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final proyectosEnProgreso =
        proyectos.where((p) => p.avancePorcentual < 100).length;

    final proyectosFinalizados =
        proyectos.where((p) => p.avancePorcentual >= 100).length;

    final textoActivos =
        '$proyectosEnProgreso ${proyectosEnProgreso == 1 ? "activo" : "activos"}';

    final textoFinalizados =
        '$proyectosFinalizados ${proyectosFinalizados == 1 ? "finalizado" : "finalizados"}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
      decoration: const BoxDecoration(
        color: primary,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proyectos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$textoActivos • $textoFinalizados',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newProjectButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _openCreateModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Proyecto',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 54,
            color: Color(0xFF8C8C9E),
          ),
          SizedBox(height: 18),
          Text(
            'No tienes proyectos registrados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6E6E80),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Comienza agregando tus proyectos académicos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8A8A9B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectCard(ProyectoModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFF04A4A),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (p.avancePorcentual < 100)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openEditModal(p),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final confirmar = await _confirmDeleteDialog();
                        if (confirmar == true) {
                          await repo.deleteProyecto(p.id);
                          await load();
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if ((p.descripcion ?? '').isNotEmpty)
                  Text(
                    p.descripcion!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF6E6E80),
                    ),
                  ),
                if (p.materiaNombre != null && p.materiaNombre!.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _colorEstadoProyecto(p).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _estadoProyecto(p),
                          style: TextStyle(
                            color: _colorEstadoProyecto(p),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (p.materiaNombre != null &&
                          p.materiaNombre!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD7D7E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                p.materiaNombre!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Avance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${p.avancePorcentual}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: p.avancePorcentual / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2DFFF),
                    valueColor: const AlwaysStoppedAnimation(primary),
                  ),
                ),
                const SizedBox(height: 18),
                if (p.avancePorcentual < 100)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        _showUpdateProgressDialog(p);
                      },
                      icon: const Icon(
                        Icons.trending_up_rounded,
                        color: primary,
                        size: 20,
                      ),
                      label: const Text(
                        'Actualizar avance',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Proyecto completado',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inicio',
                            style: TextStyle(
                              color: Color(0xFF8A8A9B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFecha(p.fechaInicio),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Entrega',
                            style: TextStyle(
                              color: Color(0xFF8A8A9B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFecha(p.fechaFin),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Duración',
                            style: TextStyle(
                              color: Color(0xFF8A8A9B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _duracionLabel(p.fechaInicio, p.fechaFin),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateProyectoModal extends StatefulWidget {
  final ProyectoModel? proyecto;

  const _CreateProyectoModal({this.proyecto});

  @override
  State<_CreateProyectoModal> createState() => _CreateProyectoModalState();
}

class _CreateProyectoModalState extends State<_CreateProyectoModal> {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final repo = ProyectoRepository();

  List<Map<String, dynamic>> materias = [];
  String? materiaId;
  DateTime? fechaInicio;
  DateTime? fechaFin;
  double avance = 0;
  bool loading = false;

  bool get isEdit => widget.proyecto != null;

  static const Color primary = Color(0xFF5B4CF0);

  @override
  void initState() {
    super.initState();
    _fillIfEdit();
    _loadMaterias();
  }

  void _fillIfEdit() {
    final p = widget.proyecto;
    if (p == null) return;

    tituloCtrl.text = p.titulo;
    descripcionCtrl.text = p.descripcion ?? '';
    materiaId = p.materiaId;
    avance = p.avancePorcentual.toDouble();

    if (p.fechaInicio != null && p.fechaInicio!.isNotEmpty) {
      fechaInicio = DateTime.tryParse(p.fechaInicio!);
    }

    if (p.fechaFin != null && p.fechaFin!.isNotEmpty) {
      fechaFin = DateTime.tryParse(p.fechaFin!);
    }
  }

  Future<void> _loadMaterias() async {
    try {
      final loaded = await LocalDataStore.instance.getMaterias();
      if (!mounted) return;

      setState(() {
        materias = loaded;
        final exists = materias.any((m) => m['id'] == materiaId);
        if (!exists) materiaId = null;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => fechaInicio = picked);
    }
  }

  Future<void> _pickFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaFin ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => fechaFin = picked);
    }
  }

  String _fechaLabel(DateTime? fecha) {
    if (fecha == null) return 'dd/mm/aaaa';

    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF7A7A8C),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F3F7),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
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
        borderSide: const BorderSide(
          color: primary,
          width: 1.3,
        ),
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A8A9B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: Color(0xFF4D4D55),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el título del proyecto'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (isEdit) {
        await repo.updateProyecto(
          id: widget.proyecto!.id,
          titulo: tituloCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim().isEmpty
              ? null
              : descripcionCtrl.text.trim(),
          materiaId: materiaId,
          fechaInicio: fechaInicio?.toIso8601String().split('T').first,
          fechaFin: fechaFin?.toIso8601String().split('T').first,
          avancePorcentual: widget.proyecto!.avancePorcentual,
        );
      } else {
        await repo.createProyecto(
          titulo: tituloCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim().isEmpty
              ? null
              : descripcionCtrl.text.trim(),
          materiaId: materiaId,
          fechaInicio: fechaInicio?.toIso8601String().split('T').first,
          fechaFin: fechaFin?.toIso8601String().split('T').first,
          avancePorcentual: 0,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar proyecto: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeMateriaId =
        materias.any((m) => m['id'] == materiaId) ? materiaId : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Text(
                      isEdit ? 'Editar Proyecto' : 'Nuevo Proyecto',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completa la información del proyecto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8A8A9B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: tituloCtrl,
                  decoration: _decoration('Título *'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descripcionCtrl,
                  maxLines: 3,
                  decoration: _decoration('Descripción'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  value: safeMateriaId,
                  decoration: _decoration('Materia *'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Selecciona una materia'),
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
                    setState(() => materiaId = value);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _datePickerField(
                        label: 'Fecha inicio *',
                        value: _fechaLabel(fechaInicio),
                        onTap: _pickFechaInicio,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _datePickerField(
                        label: 'Fecha entrega *',
                        value: _fechaLabel(fechaFin),
                        onTap: _pickFechaFin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? 'Guardar cambios' : 'Crear',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFD9D9E3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
