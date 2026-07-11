import 'package:flutter/material.dart';

import 'package:helloworld/features/materias/data/materia_model.dart';
import 'package:helloworld/features/materias/data/materia_repository.dart';

import '../../data/tarea_repository.dart';

class CreateTareaPage extends StatefulWidget {
  const CreateTareaPage({super.key});

  @override
  State<CreateTareaPage> createState() => _CreateTareaPageState();
}

class _CreateTareaPageState extends State<CreateTareaPage> {
  final _repository = TareaRepository();
  final _materiaRepository = MateriaRepository();

  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  bool isLoading = false;

  DateTime fecha = DateTime.now();

  String tipo = 'Tarea';
  String prioridad = 'Media';
  String dificultad = 'Media';

  List<MateriaModel> materias = [];

  String? materiaId;

  @override
  void initState() {
    super.initState();
    _loadMaterias();
  }

  Future<void> _loadMaterias() async {
    try {
      final data = await _materiaRepository.getMaterias();

      if (!mounted) return;

      setState(() {
        materias = data;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
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
        fechaVencimiento: fecha.toIso8601String().split('T').first,
        tipo: tipo,
        prioridad: prioridad,
        dificultad: dificultad,
        estado: 'pendiente',
        materiaId: materiaId,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
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

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() {
        fecha = result;
      });
    }
  }

  String _fechaTexto() {
    const meses = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${fecha.day} ${meses[fecha.month]} ${fecha.year}';
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF5B4CF0),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      appBar: AppBar(
        title: const Text('Nueva tarea'),
        backgroundColor: const Color(0xFFF7F5FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 550,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E2F0),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _tituloCtrl,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _inputDecoration(
                        'Título',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el título de la tarea';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 3,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _inputDecoration(
                        'Descripción',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: materiaId,
                      decoration: _inputDecoration(
                        'Materia',
                      ),
                      items: materias.map((m) {
                        return DropdownMenuItem<String>(
                          value: m.id,
                          child: Text(
                            m.nombre,
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
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: _inputDecoration(
                        'Tipo',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tarea',
                          child: Text('Tarea'),
                        ),
                        DropdownMenuItem(
                          value: 'Proyecto',
                          child: Text('Proyecto'),
                        ),
                        DropdownMenuItem(
                          value: 'Examen',
                          child: Text('Examen'),
                        ),
                        DropdownMenuItem(
                          value: 'Quiz',
                          child: Text('Quiz'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          tipo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: prioridad,
                      decoration: _inputDecoration(
                        'Prioridad',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Alta',
                          child: Text('Alta'),
                        ),
                        DropdownMenuItem(
                          value: 'Media',
                          child: Text('Media'),
                        ),
                        DropdownMenuItem(
                          value: 'Baja',
                          child: Text('Baja'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          prioridad = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: dificultad,
                      decoration: _inputDecoration(
                        'Dificultad',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Alta',
                          child: Text('Alta'),
                        ),
                        DropdownMenuItem(
                          value: 'Media',
                          child: Text('Media'),
                        ),
                        DropdownMenuItem(
                          value: 'Baja',
                          child: Text('Baja'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          dificultad = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Fecha de vencimiento',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF5B4CF0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fechaTexto(),
                              ),
                            ),
                            const Icon(
                              Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4CF0),
                        ),
                        onPressed: isLoading ? null : _guardar,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Guardar tarea',
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
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
        ),
      ),
    );
  }
}
