import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final repo = TareaRepository();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  List<Map<String, dynamic>> materias = [];

  String? materiaId;

  String tipo = 'tarea';

  String prioridad = 'media';

  String dificultad = 'media';

  String estado = 'pendiente';

  DateTime? fechaVencimiento;

  bool loading = false;

  bool loadingMaterias = true;

  bool get editing => widget.tarea != null;

  @override
  void initState() {
    super.initState();

    _loadMaterias();

    if (editing) {
      final t = widget.tarea!;

      _tituloCtrl.text = t.titulo;

      _descripcionCtrl.text = t.descripcion ?? '';

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
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMaterias() async {
    final data = await repo.getMaterias();

    if (!mounted) return;

    setState(() {
      materias = data;
      loadingMaterias = false;
    });
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaVencimiento ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
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
            'Seleccione una fecha de entrega',
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
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
          fechaVencimiento: fechaVencimiento!.toIso8601String(),
          tipo: tipo,
          prioridad: prioridad,
          dificultad: dificultad,
          materiaId: materiaId,
        );
      } else {
        await repo.createTarea(
          titulo: _tituloCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
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

  InputDecoration _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xffF8F8FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Color(0xff5B4CF0),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label),
      borderRadius: BorderRadius.circular(14),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e[0].toUpperCase() + e.substring(1),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String get fechaTexto {
    if (fechaVencimiento == null) {
      return 'Seleccionar fecha';
    }

    return DateFormat(
      'dd/MM/yyyy',
    ).format(fechaVencimiento!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Encabezado
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing ? 'Editar tarea' : 'Nueva tarea',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Completa la información de la tarea.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                /// Título
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: _inputDecoration('Título *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese un título';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                /// Descripción
                TextFormField(
                  controller: _descripcionCtrl,
                  minLines: 3,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    'Descripción',
                  ),
                ),

                const SizedBox(height: 18),

                /// Materia
                DropdownButtonFormField<String>(
                  value: materiaId,
                  decoration: _inputDecoration(
                    'Materia *',
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccione una materia';
                    }

                    return null;
                  },
                  items: materias
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m['id'] as String,
                          child: Text(
                            m['nombre'] as String,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      materiaId = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                /// Fecha
                InkWell(
                  onTap: _pickFecha,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8F8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fechaTexto,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Color(0xff5B4CF0),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// Tipo y prioridad
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Tipo',
                        value: tipo,
                        items: const [
                          'tarea',
                          'examen',
                        ],
                        onChanged: (v) {
                          setState(() {
                            tipo = v!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Prioridad',
                        value: prioridad,
                        items: const [
                          'baja',
                          'media',
                          'alta',
                        ],
                        onChanged: (v) {
                          setState(() {
                            prioridad = v!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _buildDropdown(
                  label: 'Dificultad',
                  value: dificultad,
                  items: const [
                    'baja',
                    'media',
                    'alta',
                  ],
                  onChanged: (v) {
                    setState(() {
                      dificultad = v!;
                    });
                  },
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4CF0),
                      foregroundColor: Colors.white,
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
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            editing ? 'Guardar cambios' : 'Crear',
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
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
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
