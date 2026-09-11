import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const String fontFamily = 'PlusJakartaSans';
  static  const goldColor = Color(0xFFC59B27);
  static  const goldBg = Color(0xFFFFFDF5);
  static  const goldBorder = Color(0xFFFDE8B3);
  static  const goldBadgeBg = Color(0xFFFDF0D1);
  static const Color kPrimary = Color(0xFF233876);      // Deep Royal Blue
  static const Color kPrimaryDark = Color(0xFF192A56);  // Dark Navy Blue
  static const Color kPrimaryLight = Color(0xFFEEF2FF); // Soft Ice/Blue Tint
  static const Color kPrimaryAccent = Color.fromARGB(92, 253, 183, 6); // Gold Accent
  // Background & Surfaces
  static const Color kBackground = Color(0xFFF8FAFC);   // Off-white background
  static const Color kSurface = Color(0xFFFFFFFF);      // Clean White surface
  static const Color kBorder = Color(0xFFE2E8F0);       // Light subtle border

  // Typography Colors
  static const Color kTextDark = Color(0xFF1E293B);     // Deep Slate/Dark Blue
  static const Color kTextMuted = Color(0xFF64748B);    // Muted Slate Gray

  // Status & Accent Colors
  static const Color kSuccess = Color(0xFF16A34A);      // Success Green
  static const Color kWarning = Color(0xFFD97706);      // Gold / Amber Accent
  static const Color kDanger = Color(0xFFDC2626);       // Red / Logout Accent
  static const Color kInfo = Color(0xFF2563EB);         // Vibrant Royal Info
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.kBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.kPrimary,
        secondary: AppColors.kWarning, // Using Gold accent as secondary
        surface: AppColors.kSurface,
        error: AppColors.kDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kSurface,
        foregroundColor: AppColors.kTextDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.kTextDark,
        displayColor: AppColors.kTextDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: const BorderSide(color: AppColors.kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AppColors.kPrimary,
        backgroundColor: AppColors.kBackground,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.kBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.kBorder, thickness: 1),
    );
  }


  
}