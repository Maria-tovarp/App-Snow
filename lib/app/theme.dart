import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF6C63FF),
  scaffoldBackgroundColor: const Color(0xFFF7F5FF),
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 15),
    bodyMedium: TextStyle(fontSize: 13),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3F3F6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF5B4CF0), width: 1.2),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  ),
);

final appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8E84FF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF332B73),
    onPrimaryContainer: Color(0xFFE4E0FF),
    secondary: Color(0xFF77D5C9),
    onSecondary: Color(0xFF082F2C),
    surface: Color(0xFF1C1D2A),
    onSurface: Color(0xFFF1F0FA),
    onSurfaceVariant: Color(0xFFB9B7C9),
    outline: Color(0xFF555366),
    outlineVariant: Color(0xFF343445),
    error: Color(0xFFFF7B82),
    onError: Color(0xFF3B090D),
  ),
  scaffoldBackgroundColor: const Color(0xFF11121B),
  cardColor: const Color(0xFF1C1D2A),
  dividerColor: const Color(0xFF343445),
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 15),
    bodyMedium: TextStyle(fontSize: 13),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF242534),
    labelStyle: const TextStyle(color: Color(0xFFB9B7C9)),
    hintStyle: const TextStyle(color: Color(0xFF8F8DA1)),
    prefixIconColor: const Color(0xFFAAA7BD),
    suffixIconColor: const Color(0xFFAAA7BD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF3E3E50)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF3E3E50)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF8E84FF), width: 1.5),
    ),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF1C1D2A),
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1C1D2A),
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF1C1D2A),
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF343445)),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xFF181923),
    indicatorColor: Color(0xFF332B73),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF292A39),
    contentTextStyle: TextStyle(color: Color(0xFFF1F0FA)),
  ),
);
