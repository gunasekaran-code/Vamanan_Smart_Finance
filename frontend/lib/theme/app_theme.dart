import 'package:flutter/material.dart';

/// SmartFinance design tokens. Keep every hard-coded color out of
/// widgets and behind one of these instead, so a palette change is a
/// one-file edit.
class AppColors {
  AppColors._();

  static const Color kPrimary = Color(0xFF16A34A);
  static const Color kPrimaryDark = Color(0xFF0F7A38);
  static const Color kPrimaryLight = Color(0xFFDCFCE7);

  static const Color kBackground = Color(0xFFF4F6F8);
  static const Color kSurface = Color(0xFFFFFFFF);
  static const Color kBorder = Color(0xFFE2E5EA);

  static const Color kTextDark = Color(0xFF101828);
  static const Color kTextMuted = Color(0xFF667085);

  static const Color kSuccess = Color(0xFF16A34A);
  static const Color kWarning = Color(0xFFD97706);
  static const Color kDanger = Color(0xFFDC2626);
  static const Color kInfo = Color(0xFF2563EB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.kBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.kPrimary,
        secondary: AppColors.kPrimaryDark,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
