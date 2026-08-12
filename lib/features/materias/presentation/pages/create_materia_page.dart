import 'package:flutter/material.dart';

import 'package:snow/features/materias/data/materia_repository.dart';

class CreateMateriaPage extends StatefulWidget {
  const CreateMateriaPage({super.key});

  @override
  State<CreateMateriaPage> createState() => _CreateMateriaPageState();
}

class _CreateMateriaPageState extends State<CreateMateriaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _profesorCtrl = TextEditingController();
  final _creditosCtrl = TextEditingController();
  final MateriaRepository _repository = MateriaRepository();

  String selectedColor = '#ABDEE6';
  bool isLoading = false;

  final List<String> colors = [
    '#ABDEE6',
    '#CBAACB',
    '#FFFFB5',
    '#FFCCB6',
    '#F3B0C3',
    '#C6DBDA',
    '#FEE1E8',
    '#FED7C3',
    '#F6EAC2',
    '#ECD5E3',
    '#FF968A',
    '#FFAEA5',
    '#FFC5BF',
    '#FFD8BE',
    '#FFC8A2',
    '#D4F0F0',
    '#8FCACA',
    '#CCE2CB',
    '#B6CFB6',
    '#97C1A9',
    '#FCB9AA',
    '#FFDBCC',
    '#ECEAE4',
    '#A2E1DB',
    '#55CBCD',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _profesorCtrl.dispose();
    _creditosCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _repository.createMateria(
        nombre: _nombreCtrl.text.trim(),
        profesor: _profesorCtrl.text.trim(),
        creditos: int.parse(_creditosCtrl.text.trim()),
        color: selectedColor,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        title: const Text('Nueva materia'),
        backgroundColor: const Color(0xFFF7F5FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E2F0)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la materia',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _profesorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Profesor',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el profesor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _creditosCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Créditos',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa los créditos';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Debe ser un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Color',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF302875)
                                : const Color(0xFFE4E4EC),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                        : const Text('Guardar'),
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
