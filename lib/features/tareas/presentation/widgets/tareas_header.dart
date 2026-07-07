import 'package:flutter/material.dart';

class TareasHeader extends StatelessWidget {
  final int pendientes;
  final VoidCallback onBack;

  const TareasHeader({
    super.key,
    required this.pendientes,
    required this.onBack,
  });

  static const Color primary = Color(0xFF5B4CF0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        42,
        20,
        26,
      ),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tareas y Exámenes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pendientes pendientes',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}