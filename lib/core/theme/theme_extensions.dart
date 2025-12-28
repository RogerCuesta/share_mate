// lib/core/theme/theme_extensions.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom theme extension for brand-specific properties
///
/// Extends ThemeData with custom properties like gradients,
/// custom shadows, spacing, and brand-specific UI elements.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  /// Gradients
  final LinearGradient primaryGradient;
  final LinearGradient cardGradientPurple;
  final LinearGradient cardGradientCyan;
  final LinearGradient cardGradientBlue;
  final LinearGradient cardGradientRed;

  /// Custom shadows
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;
  final List<BoxShadow> bottomNavShadow;

  /// Border radius
  final double borderRadiusSmall;
  final double borderRadiusMedium;
  final double borderRadiusLarge;
  final double borderRadiusXLarge;

  /// Spacing
  final double spacingXSmall;
  final double spacingSmall;
  final double spacingMedium;
  final double spacingLarge;
  final double spacingXLarge;

  /// Glassmorphism blur
  final double glassBlurSigma;

  const AppThemeExtension({
    required this.primaryGradient,
    required this.cardGradientPurple,
    required this.cardGradientCyan,
    required this.cardGradientBlue,
    required this.cardGradientRed,
    required this.cardShadow,
    required this.buttonShadow,
    required this.bottomNavShadow,
    required this.borderRadiusSmall,
    required this.borderRadiusMedium,
    required this.borderRadiusLarge,
    required this.borderRadiusXLarge,
    required this.spacingXSmall,
    required this.spacingSmall,
    required this.spacingMedium,
    required this.spacingLarge,
    required this.spacingXLarge,
    required this.glassBlurSigma,
  });

  /// Light theme extension
  static final light = AppThemeExtension(
    primaryGradient: AppColors.primaryGradient,
    cardGradientPurple: AppColors.primaryGradient,
    cardGradientCyan: AppColors.cyanGradient,
    cardGradientBlue: AppColors.blueGradient,
    cardGradientRed: AppColors.redGradient,
    cardShadow: [
      BoxShadow(
        color: AppColors.lightShadow,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: AppColors.lightShadow,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
    bottomNavShadow: [
      BoxShadow(
        color: AppColors.lightShadow,
        blurRadius: 12,
        offset: const Offset(0, -4),
      ),
    ],
    borderRadiusSmall: 8,
    borderRadiusMedium: 12,
    borderRadiusLarge: 16,
    borderRadiusXLarge: 24,
    spacingXSmall: 4,
    spacingSmall: 8,
    spacingMedium: 16,
    spacingLarge: 24,
    spacingXLarge: 32,
    glassBlurSigma: 10,
  );

  /// Dark theme extension
  static final dark = AppThemeExtension(
    primaryGradient: AppColors.primaryGradient,
    cardGradientPurple: AppColors.primaryGradient,
    cardGradientCyan: AppColors.cyanGradient,
    cardGradientBlue: AppColors.blueGradient,
    cardGradientRed: AppColors.redGradient,
    cardShadow: [
      BoxShadow(
        color: AppColors.darkShadow,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: AppColors.darkShadow,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
    bottomNavShadow: [
      BoxShadow(
        color: AppColors.darkShadow,
        blurRadius: 12,
        offset: const Offset(0, -4),
      ),
    ],
    borderRadiusSmall: 8,
    borderRadiusMedium: 12,
    borderRadiusLarge: 16,
    borderRadiusXLarge: 24,
    spacingXSmall: 4,
    spacingSmall: 8,
    spacingMedium: 16,
    spacingLarge: 24,
    spacingXLarge: 32,
    glassBlurSigma: 10,
  );

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? cardGradientPurple,
    LinearGradient? cardGradientCyan,
    LinearGradient? cardGradientBlue,
    LinearGradient? cardGradientRed,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonShadow,
    List<BoxShadow>? bottomNavShadow,
    double? borderRadiusSmall,
    double? borderRadiusMedium,
    double? borderRadiusLarge,
    double? borderRadiusXLarge,
    double? spacingXSmall,
    double? spacingSmall,
    double? spacingMedium,
    double? spacingLarge,
    double? spacingXLarge,
    double? glassBlurSigma,
  }) {
    return AppThemeExtension(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      cardGradientPurple: cardGradientPurple ?? this.cardGradientPurple,
      cardGradientCyan: cardGradientCyan ?? this.cardGradientCyan,
      cardGradientBlue: cardGradientBlue ?? this.cardGradientBlue,
      cardGradientRed: cardGradientRed ?? this.cardGradientRed,
      cardShadow: cardShadow ?? this.cardShadow,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      bottomNavShadow: bottomNavShadow ?? this.bottomNavShadow,
      borderRadiusSmall: borderRadiusSmall ?? this.borderRadiusSmall,
      borderRadiusMedium: borderRadiusMedium ?? this.borderRadiusMedium,
      borderRadiusLarge: borderRadiusLarge ?? this.borderRadiusLarge,
      borderRadiusXLarge: borderRadiusXLarge ?? this.borderRadiusXLarge,
      spacingXSmall: spacingXSmall ?? this.spacingXSmall,
      spacingSmall: spacingSmall ?? this.spacingSmall,
      spacingMedium: spacingMedium ?? this.spacingMedium,
      spacingLarge: spacingLarge ?? this.spacingLarge,
      spacingXLarge: spacingXLarge ?? this.spacingXLarge,
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;

    return AppThemeExtension(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      cardGradientPurple: LinearGradient.lerp(cardGradientPurple, other.cardGradientPurple, t)!,
      cardGradientCyan: LinearGradient.lerp(cardGradientCyan, other.cardGradientCyan, t)!,
      cardGradientBlue: LinearGradient.lerp(cardGradientBlue, other.cardGradientBlue, t)!,
      cardGradientRed: LinearGradient.lerp(cardGradientRed, other.cardGradientRed, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      buttonShadow: BoxShadow.lerpList(buttonShadow, other.buttonShadow, t)!,
      bottomNavShadow: BoxShadow.lerpList(bottomNavShadow, other.bottomNavShadow, t)!,
      borderRadiusSmall: _lerpDouble(borderRadiusSmall, other.borderRadiusSmall, t),
      borderRadiusMedium: _lerpDouble(borderRadiusMedium, other.borderRadiusMedium, t),
      borderRadiusLarge: _lerpDouble(borderRadiusLarge, other.borderRadiusLarge, t),
      borderRadiusXLarge: _lerpDouble(borderRadiusXLarge, other.borderRadiusXLarge, t),
      spacingXSmall: _lerpDouble(spacingXSmall, other.spacingXSmall, t),
      spacingSmall: _lerpDouble(spacingSmall, other.spacingSmall, t),
      spacingMedium: _lerpDouble(spacingMedium, other.spacingMedium, t),
      spacingLarge: _lerpDouble(spacingLarge, other.spacingLarge, t),
      spacingXLarge: _lerpDouble(spacingXLarge, other.spacingXLarge, t),
      glassBlurSigma: _lerpDouble(glassBlurSigma, other.glassBlurSigma, t),
    );
  }

  /// Helper for lerping doubles
  static double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Extension to access custom theme properties
extension ThemeExtensions on ThemeData {
  AppThemeExtension get custom => extension<AppThemeExtension>()!;
}
