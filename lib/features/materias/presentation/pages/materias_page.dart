import 'package:flutter/material.dart';
import 'package:snow/core/widgets/app_drawer.dart';
import 'package:snow/core/widgets/app_section_header.dart';
import 'package:snow/core/services/local_data_store.dart';
import 'package:snow/features/premium/data/premium_service.dart';
import 'package:snow/features/premium/presentation/widgets/premium_limit_dialog.dart';

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
    if (_store.hasCached('materias')) {
      materias = _store.cached('materias');
      loading = false;
    }
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

  Future<void> _openCreateModal() async {
    final premium = PremiumService.instance;
    await premium.initialize();
    if (!mounted) return;
    if (!premium.isPremium && materias.length >= 5) {
      await showPremiumLimitDialog(
        context,
        title: 'Llegaste al límite gratuito',
        message:
            'El plan gratis permite hasta 5 materias. Activa Premium para agregar materias ilimitadas.',
      );
      return;
    }
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

  Future<void> _deleteMateria(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.only(top: 26),
          title: Column(
            children: const [
              CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Eliminar Materia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta Materia?\n\n'
            'Esta acción no se puede deshacer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(
                        color: Color(0xFFD9D9E3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final materia = Map<String, dynamic>.from(materias[index]);
    final id = materia['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el ID de la materia.')),
      );
      return;
    }

    setState(() => materias.removeAt(index));
    _store.cacheRows('materias', materias);

    try {
      await _store.deleteMateria(id);
      await _loadMaterias();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materia eliminada correctamente'),
          backgroundColor: primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final restoreIndex = index.clamp(0, materias.length).toInt();
        materias.insert(restoreIndex, materia);
      });
      _store.cacheRows('materias', materias);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la materia: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRoute: '/materias'),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMaterias,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const AppSectionHeader(
                    title: 'Mis Materias',
                    subtitle: 'Gestiona tus asignaturas',
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
                                  profesor:
                                      materia['profesor']?.toString() ?? '',
                                  creditos:
                                      materia['creditos']?.toString() ?? '0',
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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF393947) : const Color(0xFFE4E4EC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 128,
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
                          style: TextStyle(
                            color: colors.onSurface,
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
                        icon: Icon(
                          Icons.edit_outlined,
                          color: colors.onSurface,
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

  bool nombreError = false;
  bool profesorError = false;
  bool creditosError = false;

  static const Color primary = Color(0xFF5B4CF0);

  Color selectedColor = const Color(0xFFABDEE6);

  final List<Color> colors = const [
    Color(0xFFABDEE6),
    Color(0xFFCBAACB),
    Color(0xFFFFFFB5),
    Color(0xFFFFCCB6),
    Color(0xFFF3B0C3),
    Color(0xFFC6DBDA),
    Color(0xFFFEE1E8),
    Color(0xFFFED7C3),
    Color(0xFFF6EAC2),
    Color(0xFFECD5E3),
    Color(0xFFFF968A),
    Color(0xFFFFAEA5),
    Color(0xFFFFC5BF),
    Color(0xFFFFD8BE),
    Color(0xFFFFC8A2),
    Color(0xFFD4F0F0),
    Color(0xFF8FCACA),
    Color(0xFFCCE2CB),
    Color(0xFFB6CFB6),
    Color(0xFF97C1A9),
    Color(0xFFFCB9AA),
    Color(0xFFFFDBCC),
    Color(0xFFECEAE4),
    Color(0xFFA2E1DB),
    Color(0xFF55CBCD),
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

    return const Color(0xFFABDEE6);
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    profesorCtrl.dispose();
    creditosCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      nombreError = nombreCtrl.text.trim().isEmpty;
      profesorError = profesorCtrl.text.trim().isEmpty;
      creditosError = creditosCtrl.text.trim().isEmpty;
    });

    if (nombreError || profesorError || creditosError) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF242534) : const Color(0xFFF0F0F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? colors.onSurfaceVariant : const Color(0xFF20202A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: colors.primary,
          decoration: _decoration().copyWith(
            hintStyle: TextStyle(color: colors.onSurfaceVariant),
            errorStyle: TextStyle(color: colors.error),
            errorText: label == 'Nombre de la materia' && nombreError
                ? 'Ingresa el nombre de la materia'
                : label == 'Profesor' && profesorError
                    ? 'Ingresa el nombre del profesor'
                    : label == 'Créditos' && creditosError
                        ? 'Ingresa los créditos'
                        : null,
          ),
          onChanged: (_) {
            if (label == 'Nombre de la materia' && nombreError) {
              setState(() => nombreError = false);
            }

            if (label == 'Créditos' && creditosError) {
              setState(() => creditosError = false);
            }

            if (label == 'Profesor' && profesorError) {
              setState(() => profesorError = false);
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
        decoration: BoxDecoration(
          color: colorsTheme.surface,
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
                    style: TextStyle(
                      color: colorsTheme.onSurface,
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
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.close,
                            color: colorsTheme.onSurface,
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
                label: 'Profesor',
                controller: profesorCtrl,
              ),
              _input(
                label: 'Créditos',
                controller: creditosCtrl,
                keyboardType: TextInputType.number,
              ),
              Text(
                'Color',
                style: TextStyle(
                  color: colorsTheme.onSurface,
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
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF302875)
                              : const Color(0xFFE4E4EC),
                          width: selected ? 3 : 1,
                        ),
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
                    foregroundColor: colorsTheme.onSurface,
                    side: const BorderSide(
                      color: Color(0xFFD6D6DE),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: colorsTheme.onSurface,
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
