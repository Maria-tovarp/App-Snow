import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/calendario/presentation/pages/calendario_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/horario/presentation/pages/horario_page.dart';
import '../features/materias/presentation/pages/materias_page.dart';
import '../features/metas/presentation/pages/metas_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/premium/presentation/pages/premium_page.dart';
import '../features/premium/presentation/pages/premium_module_page.dart';
import '../features/proyectos/presentation/pages/proyectos_page.dart';
import '../features/tareas/presentation/pages/tareas_page.dart';

final appRouter = GoRouter(
  // Para la sustentación/video, la app inicia directamente en el onboarding.
  // Cuando ya no quieras forzarlo, vuelve a cambiarlo por: initialLocation: '/'
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage()),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const HomePage(),
      ),
    ),
    GoRoute(
      path: '/materias',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const MateriasPage(),
      ),
    ),
    GoRoute(
      path: '/tareas',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const TareasPage(),
      ),
    ),
    GoRoute(
      path: '/metas',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const MetasPage(),
      ),
    ),
    GoRoute(
      path: '/perfil',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/proyectos',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const ProyectosPage(),
      ),
    ),
    GoRoute(
      path: '/pomodoro',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const PomodoroPage(),
      ),
    ),
    GoRoute(
      path: '/calendario',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const CalendarioPage(),
      ),
    ),
    GoRoute(
      path: '/horario',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const HorarioPage(),
      ),
    ),
    GoRoute(
      path: '/premium',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const PremiumPage(),
      ),
    ),
    GoRoute(path: '/premium/insights', builder: (_, __) => const PremiumModulePage(module: PremiumModule.insights)),
    GoRoute(path: '/premium/grades', builder: (_, __) => const PremiumModulePage(module: PremiumModule.grades)),
    GoRoute(path: '/premium/planner', builder: (_, __) => const PremiumModulePage(module: PremiumModule.planner)),
    GoRoute(path: '/premium/assistant', builder: (_, __) => const PremiumModulePage(module: PremiumModule.assistant)),
  ],
);
