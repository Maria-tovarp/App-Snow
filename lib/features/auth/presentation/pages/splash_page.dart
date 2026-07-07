import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:helloworld/core/services/app_prefs.dart';
import 'package:helloworld/core/storage/shared_preferences_session_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _sessionStorage = const SharedPreferencesSessionStorage();

  @override
  void initState() {
    super.initState();
    _goToInitialPage();
  }

  Future<void> _goToInitialPage() async {
    final seenOnboarding = await AppPrefs.hasSeenOnboarding();
    final hasSession = await _sessionStorage.hasSession();

    if (!mounted) return;

    if (!seenOnboarding) {
      context.go('/onboarding');
      return;
    }

    context.go(hasSession ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEDEAFF),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
