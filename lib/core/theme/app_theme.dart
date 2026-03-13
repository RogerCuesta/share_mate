import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_colors.dart';
import 'package:flutter_project_agents/core/theme/app_text_styles.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        extension: AppThemeExtension.light,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        extension: AppThemeExtension.dark,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeExtension extension,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: extension.ctaPrimary,
      onPrimary: extension.textOnAccent,
      secondary: extension.statusInfo,
      onSecondary: extension.textOnAccent,
      error: extension.statusError,
      onError: extension.textOnAccent,
      surface: extension.surfaceRaised,
      onSurface: extension.textPrimary,
      tertiary: extension.surfaceAccent,
      onTertiary: extension.textPrimary,
      outline: extension.borderSubtle,
      shadow: Colors.black,
      inverseSurface:
          isDark ? AppColors.lightSurfaceRaised : AppColors.darkSurfaceRaised,
      onInverseSurface:
          isDark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
      inversePrimary: extension.ctaPrimary,
      scrim: Colors.black54,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: extension.surfaceBase,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: extension.iconPrimary),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: extension.textPrimary,
        ),
      ),
      textTheme: _buildTextTheme(extension),
      cardTheme: CardThemeData(
        color: extension.surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(extension.borderRadiusLarge),
          side: BorderSide(color: extension.borderSubtle),
        ),
      ),
      dividerColor: extension.borderSubtle,
      iconTheme: IconThemeData(color: extension.iconPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extension.surfaceAccent,
        hintStyle: TextStyle(color: extension.textMuted),
        contentPadding: EdgeInsets.symmetric(
          horizontal: extension.spacingMedium,
          vertical: extension.spacingSmall + 6,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(extension.borderRadiusMedium),
          borderSide: BorderSide(color: extension.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(extension.borderRadiusMedium),
          borderSide: BorderSide(color: extension.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(extension.borderRadiusMedium),
          borderSide: BorderSide(color: extension.ctaPrimary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(extension.borderRadiusMedium),
          borderSide: BorderSide(color: extension.statusError),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: extension.ctaPrimary,
          foregroundColor: extension.textOnAccent,
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(extension.borderRadiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: extension.textPrimary,
          side: BorderSide(color: extension.borderStrong),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(extension.borderRadiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: extension.statusInfo,
          textStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: extension.surfaceRaised,
        contentTextStyle: TextStyle(color: extension.textPrimary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: extension.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(extension.borderRadiusLarge),
          side: BorderSide(color: extension.borderSubtle),
        ),
      ),
      extensions: [extension],
    );
  }

  static TextTheme _buildTextTheme(AppThemeExtension extension) {
    return TextTheme(
      displayLarge:
          AppTextStyles.displayLarge.copyWith(color: extension.textPrimary),
      displayMedium:
          AppTextStyles.displayMedium.copyWith(color: extension.textPrimary),
      displaySmall:
          AppTextStyles.displaySmall.copyWith(color: extension.textPrimary),
      headlineLarge:
          AppTextStyles.headlineLarge.copyWith(color: extension.textPrimary),
      headlineMedium:
          AppTextStyles.headlineMedium.copyWith(color: extension.textPrimary),
      headlineSmall:
          AppTextStyles.headlineSmall.copyWith(color: extension.textPrimary),
      titleLarge:
          AppTextStyles.titleLarge.copyWith(color: extension.textPrimary),
      titleMedium:
          AppTextStyles.titleMedium.copyWith(color: extension.textPrimary),
      titleSmall:
          AppTextStyles.titleSmall.copyWith(color: extension.textSecondary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: extension.textPrimary),
      bodyMedium:
          AppTextStyles.bodyMedium.copyWith(color: extension.textSecondary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: extension.textMuted),
      labelLarge:
          AppTextStyles.labelLarge.copyWith(color: extension.textPrimary),
      labelMedium:
          AppTextStyles.labelMedium.copyWith(color: extension.textSecondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: extension.textMuted),
    );
  }
}
