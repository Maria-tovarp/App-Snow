import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/meta_model.dart';
import '../../data/meta_repository.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final repo = MetaRepository();

  List<MetaModel> metas = [];
  bool loading = true;
  int tab = 0; // 0 pendientes, 1 completadas

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await repo.getMetas();
      if (!mounted) return;
      setState(() {
        metas = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando metas: $e')),
      );
    }
  }

  List<MetaModel> get pendientes =>
      metas.where((m) => m.estado != 'completada').toList();

  List<MetaModel> get completadas =>
      metas.where((m) => m.estado == 'completada').toList();

  void _showCreateModal() {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final periodoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          const Text(
                            'Nueva Meta',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Define tus objetivos académicos para el semestre',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8A8A9B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: tituloCtrl,
                        decoration: _inputDecoration('Título *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: _inputDecoration('Descripción'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: periodoCtrl,
                        decoration: _inputDecoration('Semestre'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (tituloCtrl.text.trim().isEmpty) return;

                            await repo.createMeta(
                              titulo: tituloCtrl.text.trim(),
                              descripcion: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              periodo: periodoCtrl.text.trim().isEmpty
                                  ? null
                                  : periodoCtrl.text.trim(),
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            _load();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B4CF0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Crear',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD9D9E3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF7A7A8C)),
      filled: true,
      fillColor: const Color(0xFFF3F3F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF5B4CF0),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _summaryCard(String title, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E2EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF7B7B8B),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.track_changes,
            size: 50,
            color: Color(0xFF7A7A8C),
          ),
          SizedBox(height: 16),
          Text(
            'No tienes metas pendientes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6E6E80),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Define tus objetivos para el semestre',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF8A8A9B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaCard(MetaModel m) {
    final isCompleted = m.estado == 'completada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 96,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF5B4CF0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((m.descripcion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    m.descripcion!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF6E6E80),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((m.periodo ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.periodo!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFE9F9EF)
                            : const Color(0xFFFFF5E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        isCompleted ? 'Completada' : 'Pendiente',
                        style: TextStyle(
                          fontSize: 13,
                          color: isCompleted
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (!isCompleted)
                IconButton(
                  onPressed: () async {
                    await repo.completarMeta(m.id);
                    _load();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                ),
              IconButton(
                onPressed: () async {
                  await repo.deleteMeta(m.id);
                  _load();
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ideasCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ideas de Metas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '• Mantener un promedio mayor a 4.0',
            style:
                TextStyle(fontSize: 15, color: Color(0xFF6E6E80), height: 1.7),
          ),
          Text(
            '• Entregar todos los trabajos a tiempo',
            style:
                TextStyle(fontSize: 15, color: Color(0xFF6E6E80), height: 1.7),
          ),
          Text(
            '• Estudiar al menos 2 horas diarias',
            style:
                TextStyle(fontSize: 15, color: Color(0xFF6E6E80), height: 1.7),
          ),
          Text(
            '• Aprobar todas las materias en el primer intento',
            style:
                TextStyle(fontSize: 15, color: Color(0xFF6E6E80), height: 1.7),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = tab == 0 ? pendientes : completadas;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 38, 20, 24),
                  color: const Color(0xFF5B4CF0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/home'),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const Text(
                            'Metas Académicas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '${completadas.length}/${metas.length} completadas',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _showCreateModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B4CF0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Nueva Meta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _summaryCard('Total', metas.length),
                          const SizedBox(width: 10),
                          _summaryCard('Completadas', completadas.length),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E9EF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            _tabButton(
                              label: 'Pendientes (${pendientes.length})',
                              active: tab == 0,
                              onTap: () => setState(() => tab = 0),
                            ),
                            _tabButton(
                              label: 'Completadas (${completadas.length})',
                              active: tab == 1,
                              onTap: () => setState(() => tab = 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (loading)
                        const SizedBox(height: 190)
                      else if (currentList.isEmpty)
                        _emptyState()
                      else
                        ...currentList.map(_metaCard),
                      const SizedBox(height: 18),
                      _ideasCard(),
                    ],
                  ),
                ),
              ],
            ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
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
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Materias'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tareas'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Metas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        selectedItemColor: const Color(0xFF5B4CF0),
        unselectedItemColor: const Color(0xFF8B8B9B),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

}
