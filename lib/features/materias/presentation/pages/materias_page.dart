import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helloworld/core/services/local_data_store.dart';

class MateriasPage extends StatefulWidget {
  const MateriasPage({super.key});

  @override
  State<MateriasPage> createState() => _MateriasPageState();
}

class _MateriasPageState extends State<MateriasPage> {
  static const Color primary = Color(0xFF5B4CF0);

  final _store = LocalDataStore.instance;

  List<Map<String, dynamic>> materias = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterias();
  }

  Future<void> _loadMaterias() async {
    final data = await _store.getMaterias();

    if (!mounted) return;

    setState(() {
      materias = data;
      loading = false;
    });
  }

  Color _parseColor(dynamic value) {
    if (value is Color) return value;

    final text = value?.toString() ?? '';
    final intColor = int.tryParse(text);

    if (intColor != null) return Color(intColor);

    return primary;
  }

  void _openCreateModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _MateriaModal(
        onSubmit: (data) async {
          await _store.createMateria(
            nombre: data['nombre'].toString(),
            profesor: data['profesor'].toString(),
            creditos: int.tryParse(data['creditos'].toString()) ?? 3,
            color: (data['color'] as Color).value.toString(),
          );

          await _loadMaterias();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materia creada correctamente'),
              backgroundColor: primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _openEditModal(int index) {
    final materia = materias[index];

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _MateriaModal(
        isEdit: true,
        initialData: materia,
        onSubmit: (data) async {
          final id = materia['id']?.toString();

          if (id == null) return;

          await _store.updateMateria(id, {
            'nombre': data['nombre'].toString(),
            'profesor': data['profesor'].toString(),
            'creditos': int.tryParse(data['creditos'].toString()) ?? 3,
            'color': (data['color'] as Color).value.toString(),
          });

          await _loadMaterias();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materia actualizada correctamente'),
              backgroundColor: primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _deleteMateria(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: const Text('¿Seguro que deseas eliminar esta materia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final id = materias[index]['id']?.toString();

              if (id != null) {
                await _store.deleteMateria(id);
                await _loadMaterias();
              }

              if (!mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Materia eliminada'),
                  backgroundColor: primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
                    onRefresh: _loadMaterias,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
                          decoration: const BoxDecoration(
                            color: primary,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => context.go('/home'),
                                borderRadius: BorderRadius.circular(30),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 4, right: 12),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mis Materias',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Gestiona tus asignaturas',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _openCreateModal,
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  label: const Text(
                                    'Agregar Materia',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (loading)
                                const SizedBox(height: 420)
                              else if (materias.isEmpty)
                                const SizedBox(
                                  height: 420,
                                  child: Center(
                                    child: Text(
                                      'No tienes materias registradas',
                                      style: TextStyle(
                                        color: Color(0xFF7C7C90),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...materias.asMap().entries.map(
                                  (entry) {
                                    final index = entry.key;
                                    final materia = entry.value;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _MateriaCard(
                                        nombre: materia['nombre']?.toString() ?? '',
                                        profesor: materia['profesor']?.toString() ?? '',
                                        creditos: materia['creditos']?.toString() ?? '0',
                                        color: _parseColor(materia['color']),
                                        onEdit: () => _openEditModal(index),
                                        onDelete: () => _deleteMateria(index),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const _BottomNavMaterias(),
        ],
      ),
    );
  }

}

class _MateriaCard extends StatelessWidget {
  final String nombre;
  final String profesor;
  final String creditos;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MateriaCard({
    required this.nombre,
    required this.profesor,
    required this.creditos,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre.isEmpty ? 'Materia sin nombre' : nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF20202A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profesor.isEmpty ? 'Sin profesor' : profesor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7C7C90),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$creditos créditos',
                          style: const TextStyle(
                            color: Color(0xFF7C7C90),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.black,
                          size: 21,
                        ),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MateriaModal extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSubmit;

  const _MateriaModal({
    this.isEdit = false,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<_MateriaModal> createState() => _MateriaModalState();
}

class _MateriaModalState extends State<_MateriaModal> {
  final nombreCtrl = TextEditingController();
  final profesorCtrl = TextEditingController();
  final creditosCtrl = TextEditingController(text: '3');

  static const Color primary = Color(0xFF5B4CF0);

  Color selectedColor = const Color(0xFFFF403B);

  final List<Color> colors = const [
    Color(0xFFFF403B),
    Color(0xFFFF9800),
    Color(0xFF12B981),
    Color(0xFF2F80ED),
    Color(0xFF7C4DFF),
    Color(0xFFE91E63),
    Color(0xFF00A99D),
    Color(0xFFFF5722),
    Color(0xFF5D6EF3),
    Color(0xFF9B4DF0),
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    if (widget.isEdit && data != null) {
      nombreCtrl.text = data['nombre']?.toString() ?? '';
      profesorCtrl.text = data['profesor']?.toString() ?? '';
      creditosCtrl.text = data['creditos']?.toString() ?? '3';
      selectedColor = _parseColor(data['color']);
    }
  }

  Color _parseColor(dynamic value) {
    if (value is Color) return value;

    final intValue = int.tryParse(value?.toString() ?? '');

    if (intValue != null) return Color(intValue);

    return const Color(0xFFFF403B);
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    profesorCtrl.dispose();
    creditosCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre de la materia'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSubmit({
      'nombre': nombreCtrl.text.trim(),
      'profesor': profesorCtrl.text.trim(),
      'creditos':
          creditosCtrl.text.trim().isEmpty ? '3' : creditosCtrl.text.trim(),
      'color': selectedColor,
    });

    Navigator.pop(context);
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF20202A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _decoration(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Text(
                    widget.isEdit ? 'Editar Materia' : 'Nueva Materia',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF20202A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.close,
                            color: Color(0xFF4B4B55),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Completa la información de la materia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A8A9B),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              _input(
                label: 'Nombre de la materia',
                controller: nombreCtrl,
              ),
              _input(
                label: 'Profesor (opcional)',
                controller: profesorCtrl,
              ),
              _input(
                label: 'Créditos',
                controller: creditosCtrl,
                keyboardType: TextInputType.number,
              ),
              const Text(
                'Color',
                style: TextStyle(
                  color: Color(0xFF20202A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: colors.map((c) {
                  final selected = c == selectedColor;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = c;
                      });
                    },
                    child: Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    widget.isEdit ? 'Actualizar' : 'Crear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(
                      color: Color(0xFFD6D6DE),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavMaterias extends StatelessWidget {
  const _BottomNavMaterias();

  static const Color primary = Color(0xFF5B4CF0);
  static const Color muted = Color(0xFF7C7C90);

  void _go(BuildContext context, int index) {
    switch (index) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE7E7EF)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                active: false,
                onTap: () => _go(context, 0),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                label: 'Materias',
                active: true,
                onTap: () => _go(context, 1),
              ),
              _NavItem(
                icon: Icons.checklist_outlined,
                label: 'Tareas',
                active: false,
                onTap: () => _go(context, 2),
              ),
              _NavItem(
                icon: Icons.track_changes_outlined,
                label: 'Metas',
                active: false,
                onTap: () => _go(context, 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                active: false,
                onTap: () => _go(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? _BottomNavMaterias.primary : _BottomNavMaterias.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
