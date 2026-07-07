import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/calendario/presentation/pages/calendario_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/materias/presentation/pages/materias_page.dart';
import '../features/metas/presentation/pages/metas_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/proyectos/presentation/pages/proyectos_page.dart';
import '../features/tareas/presentation/pages/tareas_page.dart';

final appRouter = GoRouter(
  // Para la sustentación/video, la app inicia directamente en el onboarding.
  // Cuando ya no quieras forzarlo, vuelve a cambiarlo por: initialLocation: '/'
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(path: '/materias', builder: (context, state) => const MateriasPage()),
    GoRoute(path: '/tareas', builder: (context, state) => const TareasPage()),
    GoRoute(path: '/metas', builder: (context, state) => const MetasPage()),
    GoRoute(path: '/perfil', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/proyectos', builder: (context, state) => const ProyectosPage()),
    GoRoute(path: '/pomodoro', builder: (context, state) => const PomodoroPage()),
    GoRoute(path: '/calendario', builder: (context, state) => const CalendarioPage()),
  ],
);
