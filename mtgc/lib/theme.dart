import 'package:flutter/material.dart';

/// Parchment-and-leather palette. Brown forward.
class AppColors {
  static const parchment = Color(0xFFE9DCC3); // background
  static const parchmentDark = Color(0xFFD9C2A0); // surfaces / cards
  static const leather = Color(0xFF5A3E2B); // primary
  static const saddle = Color(0xFF8B5E3C); // secondary
  static const gold = Color(0xFFB8860B); // accent
  static const ink = Color(0xFF3B2A1A); // text
}

final ColorScheme _scheme = const ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.leather,
  onPrimary: Color(0xFFF5ECD9),
  secondary: AppColors.saddle,
  onSecondary: Color(0xFFF5ECD9),
  tertiary: AppColors.gold,
  onTertiary: AppColors.ink,
  surface: AppColors.parchment,
  onSurface: AppColors.ink,
  surfaceContainerHighest: AppColors.parchmentDark,
  error: Color(0xFF8B2E2E),
  onError: Color(0xFFF5ECD9),
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: _scheme,
    useMaterial3: true,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.parchment,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.leather,
      foregroundColor: Color(0xFFF5ECD9),
      centerTitle: true,
      elevation: 2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.saddle,
        foregroundColor: const Color(0xFFF5ECD9),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
