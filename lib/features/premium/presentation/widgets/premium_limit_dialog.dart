import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showPremiumLimitDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final colors = Theme.of(context).colorScheme;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.surface,
      icon: const Icon(
        Icons.workspace_premium_rounded,
        color: Color(0xFFE6AD17),
        size: 38,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Ahora no'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.go('/premium');
          },
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('Ver Premium'),
        ),
      ],
    ),
  );
}
