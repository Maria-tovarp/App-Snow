import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snow/core/services/auth_session_service.dart';
import 'package:snow/core/services/theme_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  static const _primary = Color(0xFF5B4CF0);
  static const _primaryDark = Color(0xFF4435C9);

  void _open(BuildContext context, String route) {
    Navigator.pop(context);
    if (route != currentRoute) context.go(route);
  }

  static Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .68),
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        final error = colors.error;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .30),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: error.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: error, size: 29),
                ),
                const SizedBox(height: 17),
                Text(
                  '¿Cerrar sesión?',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tendrás que ingresar nuevamente para acceder a tus materias y herramientas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: error,
                      foregroundColor: colors.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text(
                      'Sí, cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await AuthSessionService.instance.signOut();
    ThemeService.instance.useLoggedOutTheme();
    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width =
        (MediaQuery.sizeOf(context).width * .86).clamp(280, 340).toDouble();

    return Drawer(
      width: width,
      elevation: 18,
      shadowColor: Colors.black.withValues(alpha: .28),
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(onClose: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                children: [
                  _MenuItem(
                    icon: Icons.home_rounded,
                    label: 'Inicio',
                    route: '/home',
                    currentRoute: currentRoute,
                    onTap: (route) => _open(context, route),
                  ),
                  const _SectionLabel('ORGANIZACIÓN'),
                  _MenuItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Materias',
                      route: '/materias',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.checklist_rounded,
                      label: 'Tareas',
                      route: '/tareas',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.folder_rounded,
                      label: 'Proyectos',
                      route: '/proyectos',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Calendario',
                      route: '/calendario',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.calendar_view_week_rounded,
                      label: 'Horario',
                      route: '/horario',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  const _SectionLabel('PRODUCTIVIDAD'),
                  _MenuItem(
                      icon: Icons.timer_rounded,
                      label: 'Pomodoro',
                      route: '/pomodoro',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.track_changes_rounded,
                      label: 'Metas',
                      route: '/metas',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  const SizedBox(height: 10),
                  _PremiumItem(
                    selected: currentRoute.startsWith('/premium'),
                    onTap: () => _open(context, '/premium'),
                  ),
                  _MenuItem(
                      icon: Icons.insights_rounded,
                      label: 'Estadísticas',
                      route: '/premium/insights',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.school_rounded,
                      label: 'Mis notas',
                      route: '/premium/grades',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Planificador',
                      route: '/premium/planner',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _MenuItem(
                      icon: Icons.smart_toy_rounded,
                      label: 'Snow Assistant',
                      route: '/premium/assistant',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  const _SectionLabel('CUENTA'),
                  _MenuItem(
                      icon: Icons.person_rounded,
                      label: 'Perfil',
                      route: '/perfil',
                      currentRoute: currentRoute,
                      onTap: (route) => _open(context, route)),
                  _LogoutItem(onTap: () => logout(context)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined,
                      size: 18, color: colors.onSurfaceVariant),
                  const SizedBox(width: 9),
                  Text('Organiza. Estudia. Avanza.',
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDrawer._primary, AppDrawer._primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: AppDrawer._primary.withValues(alpha: .25),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.cruelty_free_sharp,
                color: Colors.white, size: 25),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Snow',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 2),
              Text('Tu espacio académico',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          IconButton(
              tooltip: 'Cerrar menú',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 21)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(13, 18, 12, 6),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1)),
      );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.route,
      required this.currentRoute,
      required this.onTap});
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = route == currentRoute;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? AppDrawer._primary.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => onTap(route),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                      color: selected ? AppDrawer._primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 11),
              Icon(icon,
                  size: 22,
                  color:
                      selected ? AppDrawer._primary : colors.onSurfaceVariant),
              const SizedBox(width: 13),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color:
                              selected ? AppDrawer._primary : colors.onSurface,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600))),
              if (selected)
                const Icon(Icons.chevron_right_rounded,
                    color: AppDrawer._primary, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LogoutItem extends StatelessWidget {
  const _LogoutItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Material(
        color: error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 22, color: error),
                const SizedBox(width: 13),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: error,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumItem extends StatelessWidget {
  const _PremiumItem({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF211B52),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFD76A),
                      borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF3D3000), size: 19)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Snow Premium',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Descubre más herramientas',
                        style: TextStyle(color: Colors.white60, fontSize: 10))
                  ])),
              Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20),
            ]),
          ),
        ),
      );
}
