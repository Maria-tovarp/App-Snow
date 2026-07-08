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

  final TareaRepository repo = TareaRepository();

  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  List<Map<String, dynamic>> materias = [];

  String? materiaId;

  String tipo = 'tarea';
  String prioridad = 'media';
  String dificultad = 'media';
  String estado = 'pendiente';

  /// Siempre tendrá una fecha
  DateTime fechaVencimiento = DateTime.now();

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

      if (t.fechaVencimiento != null && t.fechaVencimiento!.isNotEmpty) {
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
    } catch (e) {
      debugPrint(
        'Error cargando materias: $e',
      );
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaVencimiento,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (picked == null) return;

    setState(() {
      fechaVencimiento = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      final fecha = DateFormat(
        'yyyy-MM-dd',
      ).format(fechaVencimiento);

      if (editing) {
        await repo.updateTarea(
          id: widget.tarea!.id,
          titulo: tituloCtrl.text.trim(),
          descripcion: descripcionCtrl.text.trim().isEmpty
              ? null
              : descripcionCtrl.text.trim(),
          fechaVencimiento: fecha,
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
          fechaVencimiento: fecha,
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
    String label, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F8FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
          color: Color(0xFF5B4CF0),
          width: 1.6,
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
      isExpanded: true,
      decoration: _inputDecoration(label),
      borderRadius: BorderRadius.circular(14),
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

  String get fechaTexto => DateFormat(
        'dd/MM/yyyy',
      ).format(fechaVencimiento);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool mobile = screenWidth < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 16 : 40,
        vertical: mobile ? 16 : 32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: mobile ? 420 : 680,
        ),
        child: Container(
          padding: EdgeInsets.all(
            mobile ? 22 : 30,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: TextStyle(
                                fontSize: mobile ? 24 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Completa la información de la tarea',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  TextFormField(
                    controller: tituloCtrl,
                    decoration: _inputDecoration(
                      'Título *',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese un título';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  TextFormField(
                    controller: descripcionCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Descripción',
                    ),
                  ),

                  const SizedBox(height: 18),

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

                  const SizedBox(height: 18),

                  InkWell(
                    onTap: _pickFecha,
                    borderRadius: BorderRadius.circular(14),
                    child: IgnorePointer(
                      child: TextFormField(
                        initialValue: fechaTexto,
                        decoration: _inputDecoration(
                          'Fecha de entrega *',
                          suffixIcon: const Icon(
                            Icons.calendar_month_outlined,
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (mobile)
                    Column(
                      children: [
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
                        const SizedBox(height: 18),
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
                      ],
                    )
                  else
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
                            onChanged: (value) {
                              setState(() {
                                tipo = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
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
                    onChanged: (value) {
                      setState(() {
                        dificultad = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 28),
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
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              editing ? 'Guardar cambios' : 'Crear tarea',
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
      ),
    );
  }
}
