import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.menuEnabled = true,
    this.onMenuBlocked,
  });

  static const Color backgroundColor = Color(0xFF5B4CF0);
  static const double height = 104;

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool menuEnabled;
  final VoidCallback? onMenuBlocked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
          child: Row(
            children: [
              Builder(
                builder: (drawerContext) => SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    tooltip: 'Abrir menú',
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (!menuEnabled) {
                        onMenuBlocked?.call();
                        return;
                      }
                      Scaffold.of(drawerContext).openDrawer();
                    },
                    icon: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFDCD8FF),
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 6),
                ...actions,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
