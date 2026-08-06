import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';
import 'package:helloworld/core/services/theme_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Snow',
        theme: appTheme,
        darkTheme: appDarkTheme,
        themeMode: ThemeService.instance.themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
