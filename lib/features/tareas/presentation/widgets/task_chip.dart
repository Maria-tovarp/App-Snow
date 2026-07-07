import 'package:flutter/material.dart';

class TaskChip extends StatelessWidget {
  final String text;
  final Color? background;
  final Color textColor;
  final bool outlined;

  const TaskChip({
    super.key,
    required this.text,
    this.background,
    this.textColor = Colors.black87,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            outlined ? Colors.white : (background ?? const Color(0xFFF2F2F7)),
        borderRadius: BorderRadius.circular(18),
        border: outlined
            ? Border.all(
                color: const Color(0xFFD9D9E3),
              )
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
