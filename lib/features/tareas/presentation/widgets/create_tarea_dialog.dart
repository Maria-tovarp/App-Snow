import 'package:flutter/material.dart';

import '../../data/tarea_model.dart';
import '../../data/tarea_repository.dart';

class CreateTareaDialog extends StatefulWidget {
  final TareaModel? tarea;

  const CreateTareaDialog({
    super.key,
    this.tarea,
  });

  @override
  State<CreateTareaDialog> createState() => _CreateTareaDialogState();
}

class _CreateTareaDialogState extends State<CreateTareaDialog> {
  final _formKey = GlobalKey<FormState>();

  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  final repo = TareaRepository();

  List<Map<String, dynamic>> materias = [];

  String? materiaId;

  String tipo = 'tarea';
  String prioridad = 'media';
  String dificultad = 'media';
  String estado = 'pendiente';

  DateTime? fechaVencimiento;

  bool loading = false;

  bool get editing => widget.tarea != null;

  @override
  void initState() {
    super.initState();

    _loadMaterias();

    if (editing) {
      final t = widget.tarea!;

      tituloCtrl.text = t.titulo;
      descripcionCtrl.text = t.descripcion ?? '';

      materiaId = t.materiaId;

      tipo = t.tipo;
      prioridad = t.prioridad;
      dificultad = t.dificultad;
      estado = t.estado;

      if (t.fechaVencimiento != null) {
        fechaVencimiento = DateTime.parse(
          t.fechaVencimiento!,
        );
      }
    }
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMaterias() async {
    try {
      final data = await repo.getMaterias();

      if (!mounted) return;

      setState(() {
        materias = data;
      });
    } catch (_) {}
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaVencimiento ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        fechaVencimiento = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (fechaVencimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleccione la fecha de vencimiento',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (editing) {
        await repo.updateTarea(
          id: widget.tarea!.id,
          titulo: tituloCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim().isEmpty
              ? null
              : descripcionCtrl.text.trim(),
          fechaVencimiento: fechaVencimiento!.toIso8601String(),
          tipo: tipo,
          prioridad: prioridad,
          dificultad: dificultad,
          materiaId: materiaId,
        );
      } else {
        await repo.createTarea(
          titulo: tituloCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim().isEmpty
              ? null
              : descripcionCtrl.text.trim(),
          fechaVencimiento: fechaVencimiento!.toIso8601String(),
          tipo: tipo,
          prioridad: prioridad,
          dificultad: dificultad,
          estado: estado,
          materiaId: materiaId,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar la tarea\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item[0].toUpperCase() + item.substring(1),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 20,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        editing ? 'Editar tarea' : 'Nueva tarea',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: tituloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descripcionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: materiaId,
                  decoration: InputDecoration(
                    labelText: 'Materia',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione una materia';
                    }
                    return null;
                  },
                  items: materias.map((m) {
                    return DropdownMenuItem<String>(
                      value: m['id'] as String,
                      child: Text(
                        m['nombre'] as String,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      materiaId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Tipo',
                  value: tipo,
                  items: const [
                    'tarea',
                    'examen',
                  ],
                  onChanged: (value) {
                    setState(() {
                      tipo = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Prioridad',
                  value: prioridad,
                  items: const [
                    'baja',
                    'media',
                    'alta',
                  ],
                  onChanged: (value) {
                    setState(() {
                      prioridad = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Dificultad',
                  value: dificultad,
                  items: const [
                    'baja',
                    'media',
                    'alta',
                  ],
                  onChanged: (value) {
                    setState(() {
                      dificultad = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFecha,
                    icon: const Icon(
                      Icons.calendar_month,
                    ),
                    label: Text(
                      fechaVencimiento == null
                          ? 'Seleccionar fecha de vencimiento'
                          : '${fechaVencimiento!.day.toString().padLeft(2, '0')}/${fechaVencimiento!.month.toString().padLeft(2, '0')}/${fechaVencimiento!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4CF0),
                    ),
                    onPressed: loading ? null : _save,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            editing ? 'Guardar cambios' : 'Guardar tarea',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancelar',
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
