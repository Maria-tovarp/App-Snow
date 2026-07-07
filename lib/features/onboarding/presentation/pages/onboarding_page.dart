import 'package:helloworld/core/services/app_prefs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const Color primary = Color(0xFF5B4CF0);
  static const Color secondary = Color(0xFF7B6CFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5B4CF0),
              Color(0xFF7468FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: 95,
                    left: 38,
                    child:
                        _BubbleIcon(icon: Icons.cruelty_free_sharp, size: 30),
                  ),
                  const Positioned(
                    top: 175,
                    right: 55,
                    child:
                        _BubbleIcon(icon: Icons.cruelty_free_sharp, size: 28),
                  ),
                  const Positioned(
                    bottom: 180,
                    left: 82,
                    child:
                        _BubbleIcon(icon: Icons.cruelty_free_sharp, size: 34),
                  ),
                  const Positioned(
                    bottom: 215,
                    right: 58,
                    child:
                        _BubbleIcon(icon: Icons.cruelty_free_sharp, size: 28),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 34),
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 128,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 105,
                              height: 105,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 26,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.cruelty_free_outlined,
                                color: primary,
                                size: 58,
                              ),
                            ),
                            Positioned(
                              right: -6,
                              bottom: 15,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Snow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Organización Académica',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Tu compañero perfecto para gestionar\nmaterias, tareas, proyectos y alcanzar tus meta\nacadémicas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 42),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MiniFeature(
                              icon: Icons.menu_book_outlined,
                              label: 'Materias',
                            ),
                            SizedBox(width: 28),
                            _MiniFeature(
                              icon: Icons.school_outlined,
                              label: 'Proyectos',
                            ),
                            SizedBox(width: 28),
                            _MiniFeature(
                              icon: Icons.cruelty_free_outlined,
                              label: 'Metas',
                            ),
                          ],
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await AppPrefs.setSeenOnboarding();
                              if (context.mounted) context.go('/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                              elevation: 12,
                              shadowColor: Colors.black.withOpacity(0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Comenzar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 42),
                        const Text(
                          'Mantén tu semestre organizado • Versión 1.0',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniFeature({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: 23,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BubbleIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _BubbleIcon({
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: Colors.white24,
      size: size,
    );
  }
}
