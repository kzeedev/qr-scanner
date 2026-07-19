import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFA726),
        secondary: Color(0xFF2C2C2E),
        surface: Color(0xFF222222),
        onSurface: Colors.white,
      ),
    );
  }
}
