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
  static const double height = 80;
  static const TextStyle titleStyle = TextStyle(
    inherit: false,
    fontFamily: 'Roboto',
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0,
  );
  static const TextStyle subtitleStyle = TextStyle(
    inherit: false,
    fontFamily: 'Roboto',
    color: Color(0xFFDCD8FF),
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0,
  );

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool menuEnabled;
  final VoidCallback? onMenuBlocked;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: double.infinity,
      height: height + topInset,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 12, 8),
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
                        textScaler: TextScaler.noScaling,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        textScaler: TextScaler.noScaling,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle),
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
