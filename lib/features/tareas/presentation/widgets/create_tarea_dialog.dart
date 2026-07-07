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
  final repo = TareaRepository();

  final tituloCtrl = TextEditingController();

  final descripcionCtrl = TextEditingController();

  final duracionCtrl = TextEditingController(text: '60');

  bool loading = false;

  List<Map<String, dynamic>> materias = [];

  String? materiaId;

  DateTime? fechaVencimiento;

  String tipo = 'tarea';

  String prioridad = 'media';

  String dificultad = 'media';

  bool get isEdit => widget.tarea != null;

  @override
  void initState() {
    super.initState();

    _loadMaterias();

    if (isEdit) {
      _loadData();
    }
  }

  Future<void> _loadMaterias() async {
    final data = await repo.getMaterias();

    if (!mounted) return;

    setState(() {
      materias = data;
    });
  }

  void _loadData() {
    final t = widget.tarea!;

    tituloCtrl.text = t.titulo;

    descripcionCtrl.text = t.descripcion ?? '';

    duracionCtrl.text = t.duracionEstimada.toString();

    materiaId = t.materiaId;

    tipo = t.tipo;

    prioridad = t.prioridad;

    dificultad = t.dificultad;

    if (t.fechaVencimiento != null) {
      fechaVencimiento = DateTime.tryParse(
        t.fechaVencimiento!,
      );
    }
  }

  @override
  void dispose() {
    tituloCtrl.dispose();

    descripcionCtrl.dispose();

    duracionCtrl.dispose();

    super.dispose();
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

  Future<void> save() async {
    if (tituloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un título'),
        ),
      );
      return;
    }

    if (materiaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una materia'),
        ),
      );
      return;
    }

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
      if (isEdit) {
        await repo.updateTarea(
          id: widget.tarea!.id,
          titulo: tituloCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim().isEmpty
              ? null
              : descripcionCtrl.text.trim(),
          fechaVencimiento:
              fechaVencimiento!.toIso8601String().split('T').first,
          duracionEstimada: int.tryParse(duracionCtrl.text.trim()) ?? 60,
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
          fechaVencimiento:
              fechaVencimiento!.toIso8601String().split('T').first,
          duracionEstimada: int.tryParse(duracionCtrl.text) ?? 60,
          tipo: tipo,
          prioridad: prioridad,
          dificultad: dificultad,
          estado: 'pendiente',
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
            'Error:\n$e',
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

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Editar tarea' : 'Nueva tarea',
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
              TextField(
                controller: tituloCtrl,
                decoration: decoration('Título *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionCtrl,
                maxLines: 3,
                decoration: decoration('Descripción'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: materiaId,
                decoration: decoration('Materia *'),
                items: materias.map((m) {
                  return DropdownMenuItem(
                    value: m["id"] as String,
                    child: Text(m["nombre"]),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    materiaId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: duracionCtrl,
                keyboardType: TextInputType.number,
                decoration: decoration(
                  'Duración estimada (minutos)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: decoration('Tipo'),
                items: const [
                  DropdownMenuItem(
                    value: 'tarea',
                    child: Text('Tarea'),
                  ),
                  DropdownMenuItem(
                    value: 'examen',
                    child: Text('Examen'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    tipo = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: prioridad,
                decoration: decoration('Prioridad'),
                items: const [
                  DropdownMenuItem(
                    value: 'baja',
                    child: Text('Baja'),
                  ),
                  DropdownMenuItem(
                    value: 'media',
                    child: Text('Media'),
                  ),
                  DropdownMenuItem(
                    value: 'alta',
                    child: Text('Alta'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    prioridad = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: dificultad,
                decoration: decoration('Dificultad'),
                items: const [
                  DropdownMenuItem(
                    value: 'baja',
                    child: Text('Baja'),
                  ),
                  DropdownMenuItem(
                    value: 'media',
                    child: Text('Media'),
                  ),
                  DropdownMenuItem(
                    value: 'alta',
                    child: Text('Alta'),
                  ),
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
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : save,
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          isEdit ? 'Guardar cambios' : 'Crear tarea',
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
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
