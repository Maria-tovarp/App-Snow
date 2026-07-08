import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helloworld/features/materias/data/materia_repository.dart';
import 'package:helloworld/features/materias/data/materia_model.dart';

import '../../data/tarea_model.dart';
import '../../data/tarea_repository.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final repo = TareaRepository();

  List<TareaModel> tareas = [];
  bool loading = true;
  int tabIndex = 0;

  static const Color primary = Color(0xFF5B4CF0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await repo.getTareas();
      if (!mounted) return;
      setState(() {
        tareas = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando tareas: $e')));
    }
  }

  List<TareaModel> get pendientes =>
      tareas.where((t) => t.estado.toLowerCase() != 'completada').toList();

  List<TareaModel> get completadas =>
      tareas.where((t) => t.estado.toLowerCase() == 'completada').toList();

  @override
  Widget build(BuildContext context) {
    final currentList = tabIndex == 0 ? pendientes : completadas;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _actions(),
                  const SizedBox(height: 16),
                  _tabs(),
                  const SizedBox(height: 16),
                  if (loading)
                    const SizedBox(height: 120)
                  else if (currentList.isEmpty)
                    _emptyState()
                  else
                    ...currentList.map((t) => _card(t)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: const _BottomNav(currentIndex: 2),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
      decoration: const BoxDecoration(color: primary),
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
                  'Tareas y Exámenes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${pendientes.length} pendientes',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openCreateModal,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nueva Tarea',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E4EC)),
          ),
          child: const Row(
            children: [
              Icon(Icons.filter_list, size: 18),
              SizedBox(width: 6),
              Text('Todas'),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDF5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tabItem('Pendientes (${pendientes.length})', 0),
          _tabItem('Completadas (${completadas.length})', 1),
        ],
      ),
    );
  }

  Widget _tabItem(String text, int index) {
    final active = tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4EC)),
      ),
      child: Center(
        child: Text(
          tabIndex == 0
              ? 'No tienes tareas pendientes'
              : 'No tienes tareas completadas',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _card(TareaModel t) {
    final isDone = t.estado.toLowerCase() == 'completada';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 132,
            decoration: BoxDecoration(
              color: isDone ? Colors.green : const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: isDone
                          ? null
                          : () async {
                              await repo.updateEstado(
                                id: t.id,
                                estado: 'completada',
                              );
                              await load();

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Tarea marcada como completada',
                                  ),
                                  backgroundColor: primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                      child: Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDone ? Colors.green : const Color(0xFF7A7A8C),
                            width: 2,
                          ),
                          color: isDone ? Colors.green : Colors.transparent,
                        ),
                        child: isDone
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 22,
                            color:
                                isDone ? Colors.grey.shade300 : Colors.black87,
                          ),
                          onPressed: isDone ? null : () => _openEditModal(t),
                        ),
                        const SizedBox(height: 14),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 22,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirmar = await _confirmDeleteDialog();
                            if (confirmar == true) {
                              await repo.deleteTarea(t.id);
                              await load();

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Tarea eliminada'),
                                  backgroundColor: primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if ((t.descripcion ?? '').isNotEmpty)
                  Text(
                    t.descripcion!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF7A7A8C),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _taskChip(_materiaLabel(t), outlined: true),
                    _taskChip(
                      t.prioridad,
                      background: _prioridadColor(t.prioridad),
                      textColor: Colors.white,
                    ),
                    _taskChip(t.tipo, background: const Color(0xFFE9E9F2)),
                    _taskChip(
                      t.dificultad,
                      background: const Color(0xFFE9E9F2),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _formatFechaBonita(t.fechaVencimiento),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7A7A8C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskChip(
    String text, {
    Color? background,
    Color textColor = Colors.black87,
    bool outlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            outlined ? Colors.white : (background ?? const Color(0xFFF1F1F6)),
        borderRadius: BorderRadius.circular(16),
        border: outlined ? Border.all(color: const Color(0xFFD9D9E3)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta':
        return const Color(0xFFE11D48);
      case 'media':
        return const Color(0xFFF59E0B);
      case 'baja':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _materiaLabel(TareaModel t) {
    if (t.materiaNombre != null && t.materiaNombre!.isNotEmpty) {
      return t.materiaNombre!;
    }
    return 'Sin materia';
  }

  String _formatFechaBonita(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha de entrega';

    final date = DateTime.tryParse(fecha);
    if (date == null) return fecha;

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

    final hoy = DateTime.now();
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final soloFecha = DateTime(date.year, date.month, date.day);
    final diff = soloFecha.difference(soloHoy).inDays;
    final fechaBase = '${date.day} ${meses[date.month - 1]} ${date.year}';

    if (diff > 1) return '$fechaBase ($diff días)';
    if (diff == 1) return '$fechaBase (1 día)';
    if (diff == 0) return '$fechaBase (hoy)';
    if (diff == -1) return '$fechaBase (venció ayer)';
    return '$fechaBase (vencida)';
  }

  Future<bool?> _confirmDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar tarea'),
          content: const Text('¿Estás segura de eliminar esta tarea?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11445),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
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
      builder: (_) => const _CreateTareaModal(),
    ).then((value) {
      if (value == true) load();
    });
  }

  void _openEditModal(TareaModel tarea) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CreateTareaModal(tarea: tarea),
    ).then((value) {
      if (value == true) load();
    });
  }
}

class _CreateTareaModal extends StatefulWidget {
  final TareaModel? tarea;

  const _CreateTareaModal({this.tarea});

  @override
  State<_CreateTareaModal> createState() => _CreateTareaModalState();
}

class _CreateTareaModalState extends State<_CreateTareaModal> {
  final tituloCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  final repo = TareaRepository();
  final materiaRepo = MateriaRepository();

  bool loading = false;

  List<MateriaModel> materias = [];

  String? materiaId;

  String? errorMessage;

  DateTime? fechaVencimiento;

  String tipo = 'tarea';
  String prioridad = 'media';
  String dificultad = 'media';

  bool get isEdit => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    _fillDataIfEdit();
    _loadMaterias();
  }

  void _fillDataIfEdit() {
    final t = widget.tarea;
    if (t == null) return;

    tituloCtrl.text = t.titulo;
    descCtrl.text = t.descripcion ?? '';
    materiaId = t.materiaId;

    final tiposValidos = ['tarea', 'examen', 'proyecto'];
    final prioridadesValidas = ['baja', 'media', 'alta'];
    final dificultadesValidas = ['baja', 'media', 'alta'];

    tipo = tiposValidos.contains(t.tipo.toLowerCase())
        ? t.tipo.toLowerCase()
        : 'tarea';

    prioridad = prioridadesValidas.contains(t.prioridad.toLowerCase())
        ? t.prioridad.toLowerCase()
        : 'media';

    dificultad = dificultadesValidas.contains(t.dificultad.toLowerCase())
        ? t.dificultad.toLowerCase()
        : 'media';

    if (t.fechaVencimiento != null && t.fechaVencimiento!.isNotEmpty) {
      fechaVencimiento = DateTime.tryParse(t.fechaVencimiento!);
    }
  }

  Future<void> _loadMaterias() async {
    try {
      final loaded = await materiaRepo.getMaterias();

      if (!mounted) return;

      setState(() {
        materias = loaded;

        final existeMateria = materias.any((m) => m.id == materiaId);

        if (!existeMateria) {
          materiaId = null;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaVencimiento ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => fechaVencimiento = picked);
    }
  }

  Future<void> save() async {
    if (tituloCtrl.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Ingresa el título de la tarea';
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    setState(() => loading = true);

    try {
      if (isEdit) {
        await repo.updateTarea(
          id: widget.tarea!.id,
          titulo: tituloCtrl.text.trim(),
          descripcion:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          fechaVencimiento:
              fechaVencimiento?.toIso8601String().split('T').first ?? '',
          tipo: tipo,
          prioridad: prioridad,
          dificultad: dificultad,
          materiaId: materiaId,
        );
      } else {
        await repo.createTarea(
          titulo: tituloCtrl.text.trim(),
          descripcion:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          fechaVencimiento:
              fechaVencimiento?.toIso8601String().split('T').first ?? '',
          tipo: tipo,
          prioridad: prioridad,
          dificultad: dificultad,
          estado: 'pendiente',
          materiaId: materiaId,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Tarea actualizada correctamente'
                : 'Tarea creada correctamente',
          ),
          backgroundColor: const Color(0xFF5B4CF0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar tarea: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF7A7A8C)),
      filled: true,
      fillColor: const Color(0xFFF3F3F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5B4CF0), width: 1.4),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = values.contains(value) ? value : values.first;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: _decoration(label),
      isExpanded: true,
      items: values
          .toSet()
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(
                e[0].toUpperCase() + e.substring(1),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _fechaLabel() {
    if (fechaVencimiento == null) return 'dd/mm/aaaa';
    final d = fechaVencimiento!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final safeMateriaId =
        materias.any((m) => m.id == materiaId) ? materiaId : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      backgroundColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
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
                      isEdit ? 'Editar Tarea' : 'Nueva Tarea',
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
                  'Completa la información de la tarea',
                  style: TextStyle(color: Color(0xFF8A8A9B), fontSize: 14),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: tituloCtrl,
                  decoration: _decoration('Título *'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
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
                        value: m.id,
                        child: Text(
                          m.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => materiaId = value),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickFecha,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration('Fecha de entrega *'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fechaLabel(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _dropdownField(
                        label: 'Tipo',
                        value: tipo,
                        values: const ['tarea', 'examen', 'proyecto'],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => tipo = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdownField(
                        label: 'Prioridad',
                        value: prioridad,
                        values: const ['baja', 'media', 'alta'],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => prioridad = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _dropdownField(
                  label: 'Dificultad',
                  value: dificultad,
                  values: const ['baja', 'media', 'alta'],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => dificultad = value);
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4CF0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF5B4CF0),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
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
                              fontWeight: FontWeight.w600,
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
                    child: const Text('Cancelar'),
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

class _BottomNav extends StatelessWidget {
  final int currentIndex;

  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/materias');
            break;
          case 2:
            context.go('/tareas');
            break;
          case 3:
            context.go('/metas');
            break;
          case 4:
            context.go('/perfil');
            break;
        }
      },
      selectedItemColor: const Color(0xFF5B4CF0),
      unselectedItemColor: const Color(0xFF8A8A9B),
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Materias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_outlined),
          label: 'Tareas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.track_changes_outlined),
          label: 'Metas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
