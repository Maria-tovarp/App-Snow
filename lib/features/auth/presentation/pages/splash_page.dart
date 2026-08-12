import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snow/core/services/app_prefs.dart';
import 'package:snow/core/services/local_data_store.dart';
import 'package:snow/core/storage/shared_preferences_session_storage.dart';

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

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (hasSession && userId != null) {
      await Future.wait([
        AppPrefs.loadHomeSummary(userId),
        LocalDataStore.instance.loadCache(),
      ]);
      if (!mounted) return;
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
