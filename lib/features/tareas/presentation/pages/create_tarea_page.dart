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
  final _duracionCtrl = TextEditingController();

  final TareaRepository _repository = TareaRepository();

  String tipo = 'tarea';
  String prioridad = 'media';
  String dificultad = 'media';
  String estado = 'pendiente';
  bool isLoading = false;
  DateTime? fechaVencimiento;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
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

    setState(() => isLoading = true);

    try {
      await _repository.createTarea(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        fechaAsignacion: DateTime.now().toIso8601String().split('T').first,
        fechaVencimiento: fechaVencimiento?.toIso8601String().split('T').first,
        duracionEstimada: int.tryParse(_duracionCtrl.text.trim()) ?? 0,
        tipo: tipo,
        prioridad: prioridad,
        dificultad: dificultad,
        estado: estado,
        materiaId: null,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar tarea: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
              child: Text(item),
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
        title: const Text('Nueva tarea'),
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4E4EC)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _duracionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duración estimada (minutos)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Tipo',
                  value: tipo,
                  items: const ['tarea', 'examen'],
                  onChanged: (value) {
                    setState(() => tipo = value!);
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Prioridad',
                  value: prioridad,
                  items: const ['baja', 'media', 'alta'],
                  onChanged: (value) {
                    setState(() => prioridad = value!);
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Dificultad',
                  value: dificultad,
                  items: const ['baja', 'media', 'alta'],
                  onChanged: (value) {
                    setState(() => dificultad = value!);
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Estado',
                  value: estado,
                  items: const ['pendiente', 'completada'],
                  onChanged: (value) {
                    setState(() => estado = value!);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _pickFecha,
                    child: Text(
                      fechaVencimiento == null
                          ? 'Seleccionar fecha de vencimiento'
                          : 'Vence: ${fechaVencimiento!.toIso8601String().split('T').first}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4CF0),
                    ),
                    onPressed: isLoading ? null : _save,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Guardar tarea'),
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
