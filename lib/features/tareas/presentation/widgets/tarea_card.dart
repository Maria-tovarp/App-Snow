import 'package:flutter/material.dart';

import '../../data/tarea_model.dart';
import 'task_chip.dart';

class TareaCard extends StatelessWidget {
  final TareaModel tarea;

  final VoidCallback onCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TareaCard({
    super.key,
    required this.tarea,
    required this.onCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  bool get completada => tarea.estado.toLowerCase() == 'completada';

  Color get prioridadColor {
    switch (tarea.prioridad.toLowerCase()) {
      case 'alta':
        return Colors.red;

      case 'media':
        return Colors.orange;

      case 'baja':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Color get fechaColor {
    if (tarea.fechaVencimiento == null) {
      return Colors.grey;
    }

    final hoy = DateTime.now();

    final fecha = DateTime.parse(
      tarea.fechaVencimiento!,
    );

    final dias = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    )
        .difference(
          DateTime(
            hoy.year,
            hoy.month,
            hoy.day,
          ),
        )
        .inDays;

    if (dias <= 0) {
      return Colors.red;
    }

    if (dias <= 2) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String get diasRestantes {
    if (tarea.fechaVencimiento == null) {
      return 'Sin fecha';
    }

    final hoy = DateTime.now();

    final fecha = DateTime.parse(
      tarea.fechaVencimiento!,
    );

    final dias = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    )
        .difference(
          DateTime(
            hoy.year,
            hoy.month,
            hoy.day,
          ),
        )
        .inDays;

    if (dias > 1) {
      return 'Faltan $dias días';
    }

    if (dias == 1) {
      return 'Mañana';
    }

    if (dias == 0) {
      return 'Vence hoy';
    }

    if (dias == -1) {
      return 'Venció ayer';
    }

    return 'Vencida hace ${dias.abs()} días';
  }

  String get fechaBonita {
    if (tarea.fechaVencimiento == null) {
      return 'Sin fecha';
    }

    final f = DateTime.parse(
      tarea.fechaVencimiento!,
    );

    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${f.day} ${meses[f.month - 1]} ${f.year}';
  }

  String get materia {
    if (tarea.materiaNombre == null || tarea.materiaNombre!.isEmpty) {
      return 'Sin materia';
    }

    return tarea.materiaNombre!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7E7EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: completada ? null : onCompleted,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completada ? Colors.green : Colors.white,
                    border: Border.all(
                      color: completada ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: completada
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 15,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tarea.titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: completada ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'editar':
                      onEdit();
                      break;

                    case 'eliminar':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
          if ((tarea.descripcion ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              tarea.descripcion!,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TaskChip(
                text: materia,
                outlined: true,
              ),
              TaskChip(
                text: tarea.tipo,
                background: const Color(0xFFECECF5),
              ),
              TaskChip(
                text: tarea.prioridad,
                background: prioridadColor,
                textColor: Colors.white,
              ),
              TaskChip(
                text: tarea.dificultad,
                background: const Color(0xFFECECF5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fechaColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: fechaColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fechaBonita,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diasRestantes,
                        style: TextStyle(
                          color: fechaColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
