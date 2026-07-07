import 'package:flutter/material.dart';

class TareasTabs extends StatelessWidget {
  final int pendientes;
  final int completadas;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const TareasTabs({
    super.key,
    required this.pendientes,
    required this.completadas,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDF5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _tabButton(
            index: 0,
            text: 'Pendientes ($pendientes)',
          ),
          _tabButton(
            index: 1,
            text: 'Completadas ($completadas)',
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required String text,
  }) {
    final active = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.black87
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}