import 'package:flutter/material.dart';

import '../../data/tarea_repository.dart';

class CreateTareaPage extends StatefulWidget {
  const CreateTareaPage({super.key});

  @override
  State<CreateTareaPage> createState() => _CreateTareaPageState();
}

class _CreateTareaPageState extends State<CreateTareaPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController(text: '60');

  final TareaRepository _repository = TareaRepository();

  List<Map<String, dynamic>> materias = [];

  String? materiaId;

  String tipo = 'tarea';
  String prioridad = 'media';
  String dificultad = 'media';
  String estado = 'pendiente';

  bool isLoading = false;

  DateTime? fechaVencimiento;

  @override
  void initState() {
    super.initState();
    _loadMaterias();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMaterias() async {
    try {
      final data = await _repository.getMaterias();

      if (!mounted) return;

      setState(() {
        materias = data;
      });
    } catch (_) {}
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
            'Debes seleccionar una fecha de vencimiento',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _repository.createTarea(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        fechaVencimiento: fechaVencimiento!.toIso8601String().split('T').first,
        duracionEstimada: int.tryParse(_duracionCtrl.text.trim()) ?? 60,
        tipo: tipo,
        prioridad: prioridad,
        dificultad: dificultad,
        estado: estado,
        materiaId: materiaId,
      );

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
          isLoading = false;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text("Nueva tarea"),
        elevation: 0,
        backgroundColor: const Color(0xFFF7F7FB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE4E4EC),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: InputDecoration(
                    labelText: "Título",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese un título";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Descripción",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: materiaId,
                  decoration: InputDecoration(
                    labelText: "Materia",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return "Seleccione una materia";
                    }
                    return null;
                  },
                  items: materias.map((materia) {
                    return DropdownMenuItem<String>(
                      value: materia["id"] as String,
                      child: Text(
                        materia["nombre"] as String,
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
                TextFormField(
                  controller: _duracionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Duración estimada (minutos)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Ingrese la duración";
                    }

                    final minutos = int.tryParse(value);

                    if (minutos == null || minutos <= 0) {
                      return "La duración debe ser mayor que 0";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: "Tipo",
                  value: tipo,
                  items: const [
                    "tarea",
                    "examen",
                  ],
                  onChanged: (value) {
                    setState(() {
                      tipo = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: "Prioridad",
                  value: prioridad,
                  items: const [
                    "baja",
                    "media",
                    "alta",
                  ],
                  onChanged: (value) {
                    setState(() {
                      prioridad = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: "Dificultad",
                  value: dificultad,
                  items: const [
                    "baja",
                    "media",
                    "alta",
                  ],
                  onChanged: (value) {
                    setState(() {
                      dificultad = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    fechaVencimiento == null
                        ? "Seleccionar fecha de vencimiento"
                        : "${fechaVencimiento!.day.toString().padLeft(2, '0')}/"
                            "${fechaVencimiento!.month.toString().padLeft(2, '0')}/"
                            "${fechaVencimiento!.year}",
                  ),
                  onPressed: _pickFecha,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4CF0),
                    ),
                    onPressed: isLoading ? null : _save,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Guardar tarea",
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
