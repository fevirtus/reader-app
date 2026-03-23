import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF155DFC),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF7F9FC),
      foregroundColor: Color(0xFF121826),
    ),
  );
}
