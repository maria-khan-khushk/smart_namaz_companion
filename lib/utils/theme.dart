import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // Arabic & Urdu premium typography helper
  static TextStyle arabicStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.notoSansArabic(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Base font style for English text
  static TextStyle englishStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(textStyle: base.displayLarge, color: textColor),
      displayMedium: GoogleFonts.plusJakartaSans(textStyle: base.displayMedium, color: textColor),
      displaySmall: GoogleFonts.plusJakartaSans(textStyle: base.displaySmall, color: textColor),
      headlineLarge: GoogleFonts.plusJakartaSans(textStyle: base.headlineLarge, color: textColor, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.plusJakartaSans(textStyle: base.headlineMedium, color: textColor, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.plusJakartaSans(textStyle: base.headlineSmall, color: textColor, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.plusJakartaSans(textStyle: base.titleLarge, color: textColor, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.plusJakartaSans(textStyle: base.titleMedium, color: textColor, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.plusJakartaSans(textStyle: base.titleSmall, color: textColor, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.plusJakartaSans(textStyle: base.bodyLarge, color: textColor),
      bodyMedium: GoogleFonts.plusJakartaSans(textStyle: base.bodyMedium, color: secondaryColor),
      bodySmall: GoogleFonts.plusJakartaSans(textStyle: base.bodySmall, color: secondaryColor),
      labelLarge: GoogleFonts.plusJakartaSans(textStyle: base.labelLarge, color: textColor, fontWeight: FontWeight.w600),
    );
  }

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
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryMuted,
      unselectedItemColor: Colors.black45,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      selectedIconTheme: IconThemeData(color: AppColors.primaryMuted, size: 24),
      unselectedIconTheme: IconThemeData(color: Colors.black45, size: 24),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryMuted,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    textTheme: _buildTextTheme(ThemeData.light().textTheme, Colors.black87, Colors.black54),
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
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: AppColors.darkPrimaryMuted,
      unselectedItemColor: AppColors.darkTextSecondary,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      selectedIconTheme: IconThemeData(color: AppColors.darkPrimaryMuted, size: 24),
      unselectedIconTheme: IconThemeData(color: AppColors.darkTextSecondary, size: 24),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimaryMuted,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    textTheme: _buildTextTheme(ThemeData.dark().textTheme, AppColors.darkTextPrimary, AppColors.darkTextSecondary),
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