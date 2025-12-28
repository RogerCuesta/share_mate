// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'theme_extensions.dart';

/// Main theme builder for SubMate
///
/// Provides centralized theme configuration with:
/// - Material 3 design system
/// - Custom brand colors and gradients
/// - Typography scale
/// - Theme extensions for custom properties
class AppTheme {
  AppTheme._(); // Private constructor

  // =========================================================================
  // LIGHT THEME
  // =========================================================================

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: Brightness.light,
      primary: AppColors.primaryPurple,
      onPrimary: Colors.white,
      secondary: AppColors.accentCyan,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: colorScheme.onSurface),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: colorScheme.onSurface),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurface),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurface),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.lightOnSurface.withOpacity(0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryPurple;
          }
          return AppColors.lightSurfaceVariant;
        }),
      ),

      // Custom theme extensions
      extensions: [AppThemeExtension.light],
    );
  }

  // =========================================================================
  // DARK THEME
  // =========================================================================

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: Brightness.dark,
      primary: AppColors.primaryPurple,
      onPrimary: Colors.white,
      secondary: AppColors.accentCyan,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: colorScheme.onSurface),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: colorScheme.onSurface),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurface),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: colorScheme.onSurface),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.darkOnSurface.withOpacity(0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryPurple;
          }
          return AppColors.darkSurfaceVariant;
        }),
      ),

      // Custom theme extensions
      extensions: [AppThemeExtension.dark],
    );
  }
}
