import 'package:flutter/material.dart';

class AppColors {
  // Light mode colors (bilkul pehle jaisay)
  static const Color lightBackground = Colors.white;
  static const Color primaryMuted = Color(0xFF748469);
  static const Color secondaryMuted = Color(0xFFABB290);
  static const Color accentMuted = Color(0xFFAAC1B1);
  static const Color warmLight = Color(0xFFF9EAD7);

  // Dark mode colors (professional & easy on eyes)
  static const Color darkBackground = Color(0xFF121212);      // Main background (deep black)
  static const Color darkSurface = Color(0xFF1E1E1E);         // Drawer, cards, surfaces (slightly lighter)
  static const Color darkCard = Color(0xFF2C2C2C);            // Card background (soft grey)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);     // White text
  static const Color darkTextSecondary = Color(0xFFB0B0B0);   // Grey text for less emphasis
  static const Color darkDivider = Color(0xFF3D3D3D);         // Dividers, borders

  // Dark mode variant of your existing colors (for buttons, icons, etc.)
  static const Color darkPrimaryMuted = Color(0xFF8A9B7F);
  static const Color darkSecondaryMuted = Color(0xFFBCC9A3);
  static const Color darkAccentMuted = Color(0xFFC4D3C0);
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
    cardTheme: CardThemeData(  // ✅ Fixed: CardTheme → CardThemeData
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.darkPrimaryMuted,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkDivider,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimaryMuted,
      secondary: AppColors.darkSecondaryMuted,
      tertiary: AppColors.darkAccentMuted,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimaryMuted,
        foregroundColor: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(  // ✅ Fixed: CardTheme → CardThemeData
      color: AppColors.darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.darkTextPrimary),
      displayMedium: TextStyle(color: AppColors.darkTextPrimary),
      displaySmall: TextStyle(color: AppColors.darkTextPrimary),
      headlineLarge: TextStyle(color: AppColors.darkTextPrimary),
      headlineMedium: TextStyle(color: AppColors.darkTextPrimary),
      headlineSmall: TextStyle(color: AppColors.darkTextPrimary),
      titleLarge: TextStyle(color: AppColors.darkTextPrimary),
      titleMedium: TextStyle(color: AppColors.darkTextPrimary),
      titleSmall: TextStyle(color: AppColors.darkTextPrimary),
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
      bodySmall: TextStyle(color: AppColors.darkTextSecondary),
      labelLarge: TextStyle(color: AppColors.darkTextPrimary),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.darkPrimaryMuted,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
    ),
  );
}