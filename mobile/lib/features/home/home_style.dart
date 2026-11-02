import 'package:flutter/material.dart';

/// Shared styling for the signed-in screens from the dark home design.
class HomeStyle {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF191919);
  static const border = Color(0xFF262626);
  static const muted = Color(0xFFA3A3A3);
  static const orange = Color(0xFFFF7810);
  static const green = Color(0xFF22C55E);

  static final theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: orange,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 44),
      ),
    ),
  );
}
