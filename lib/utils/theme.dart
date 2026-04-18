import 'package:flutter/material.dart';

class AppColors {
  // Light mode colors
  static const Color lightBackground = Colors.white; // pure white
  static const Color primaryMuted = Color(0xFF748469);
  static const Color secondaryMuted = Color(0xFFABB290);
  static const Color accentMuted = Color(0xFFAAC1B1);
  static const Color warmLight = Color(0xFFF9EAD7);

  // Dark mode background (aap decide karein – dark grey/black)
  static const Color darkBackground = Color(0xFF121212);
  // Dark mode mein same colors thoda adjust kar sakte hain (optional)
  static const Color darkPrimaryMuted = Color(0xFF8A9B7F);
  static const Color darkSecondaryMuted = Color(0xFFBCC9A3);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.primaryMuted,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryMuted,
      secondary: AppColors.secondaryMuted,
      tertiary: AppColors.accentMuted,
      surface: AppColors.warmLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryMuted,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryMuted,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.darkPrimaryMuted,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimaryMuted,
      secondary: AppColors.darkSecondaryMuted,
      tertiary: AppColors.accentMuted,
      surface: AppColors.warmLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkPrimaryMuted,
      elevation: 0,
    ),
  );
}