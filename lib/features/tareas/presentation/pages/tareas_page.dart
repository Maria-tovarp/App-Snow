import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/tarea_model.dart';
import '../../data/tarea_repository.dart';

import '../widgets/tarea_card.dart';
import '../widgets/tareas_header.dart';
import '../widgets/tareas_tabs.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/create_tarea_dialog.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TareaRepository repo = TareaRepository();

  List<TareaModel> tareas = [];

  bool loading = true;

  int tabIndex = 0;

  static const Color primary = Color(0xFF5B4CF0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await repo.getTareas();

      if (!mounted) return;

      setState(() {
        tareas = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error cargando tareas: $e',
          ),
        ),
      );
    }
  }

  List<TareaModel> get pendientes =>
      tareas
          .where(
            (t) =>
                t.estado.toLowerCase() !=
                'completada',
          )
          .toList();

  List<TareaModel> get completadas =>
      tareas
          .where(
            (t) =>
                t.estado.toLowerCase() ==
                'completada',
          )
          .toList();
            @override
  Widget build(BuildContext context) {
    final currentList =
        tabIndex == 0 ? pendientes : completadas;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      body: RefreshIndicator(
        onRefresh: load,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding: EdgeInsets.zero,

          children: [

            TareasHeader(
              pendientes: pendientes.length,
              onBack: () => context.go('/home'),
            ),

            Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [

                  SizedBox(
                    height: 48,

                    child: FilledButton.icon(
                      style:
                          FilledButton.styleFrom(
                        backgroundColor: primary,
                      ),

                      onPressed:
                          _openCreateModal,

                      icon:
                          const Icon(Icons.add),

                      label: const Text(
                        'Nueva tarea',
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TareasTabs(
                    pendientes:
                        pendientes.length,

                    completadas:
                        completadas.length,

                    currentIndex:
                        tabIndex,

                    onChanged: (value) {
                      setState(() {
                        tabIndex = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  if (loading)
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 80,
                      ),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else if (currentList.isEmpty)
                    _emptyState()
                  else
                    ...currentList.map(
                      (t) => TareaCard(
                        tarea: t,

                        onCompleted:
                            () async {
                          await repo
                              .updateEstado(
                            id: t.id,
                            estado:
                                'completada',
                          );

                          await load();
                        },

                        onEdit: () {
                          _openEditModal(
                            t,
                          );
                        },

                        onDelete: () async {
                          final ok =
                              await _confirmDeleteDialog();

                          if (ok == true) {
                            await repo
                                .deleteTarea(
                                    t.id);

                            await load();
                          }
                        },
                      ),
                    ),

                ],
              ),
            ),

          ],
        ),
      ),

      bottomNavigationBar:
          const BottomNav(
        currentIndex: 2,
      ),
    );
  }
    Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE4E4EC),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 54,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            tabIndex == 0
                ? 'No tienes tareas pendientes'
                : 'No tienes tareas completadas',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Eliminar tarea',
          ),
          content: const Text(
            '¿Deseas eliminar esta tarea?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCreateModal() {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const CreateTareaDialog(),
    ).then((value) {
      if (value == true) {
        load();
      }
    });
  }

  void _openEditModal(TareaModel tarea) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CreateTareaDialog(
        tarea: tarea,
      ),
    ).then((value) {
      if (value == true) {
        load();
      }
    });
  }
}
