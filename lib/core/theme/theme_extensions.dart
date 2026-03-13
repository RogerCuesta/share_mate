import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_colors.dart';

/// App-wide semantic tokens.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceAccent,
    required this.surfaceCritical,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.statusSynced,
    required this.statusPending,
    required this.statusRequiresAction,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
    required this.ctaPrimary,
    required this.ctaSecondary,
    required this.ctaDestructive,
    required this.borderSubtle,
    required this.borderStrong,
    required this.densityCompact,
    required this.densityRegular,
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

  // Semantic colors.
  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceAccent;
  final Color surfaceCritical;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color statusSynced;
  final Color statusPending;
  final Color statusRequiresAction;
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusInfo;
  final Color ctaPrimary;
  final Color ctaSecondary;
  final Color ctaDestructive;
  final Color borderSubtle;
  final Color borderStrong;

  // Density tokens.
  final double densityCompact;
  final double densityRegular;

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

  /// Light extension.
  static const light = AppThemeExtension(
    surfaceBase: AppColors.lightSurfaceBase,
    surfaceRaised: AppColors.lightSurfaceRaised,
    surfaceAccent: AppColors.lightSurfaceAccent,
    surfaceCritical: AppColors.lightSurfaceCritical,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    textOnAccent: Colors.white,
    iconPrimary: AppColors.lightTextPrimary,
    iconSecondary: AppColors.lightTextSecondary,
    statusSynced: AppColors.success,
    statusPending: AppColors.warning,
    statusRequiresAction: AppColors.error,
    statusSuccess: AppColors.success,
    statusWarning: AppColors.warning,
    statusError: AppColors.error,
    statusInfo: AppColors.info,
    ctaPrimary: AppColors.primaryPurple,
    ctaSecondary: AppColors.lightSurfaceAccent,
    ctaDestructive: AppColors.error,
    borderSubtle: AppColors.lightBorderSubtle,
    borderStrong: AppColors.lightBorderStrong,
    densityCompact: 8,
    densityRegular: 16,
    primaryGradient: AppColors.primaryGradient,
    cardGradientPurple: AppColors.primaryGradient,
    cardGradientCyan: AppColors.cyanGradient,
    cardGradientBlue: AppColors.blueGradient,
    cardGradientRed: AppColors.redGradient,
    cardShadow: [
      BoxShadow(
        color: Color(0x140D1525),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x140D1525),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    bottomNavShadow: [
      BoxShadow(
        color: Color(0x140D1525),
        blurRadius: 12,
        offset: Offset(0, -4),
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

  /// Dark extension.
  static const dark = AppThemeExtension(
    surfaceBase: AppColors.darkSurfaceBase,
    surfaceRaised: AppColors.darkSurfaceRaised,
    surfaceAccent: AppColors.darkSurfaceAccent,
    surfaceCritical: AppColors.darkSurfaceCritical,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    textOnAccent: Colors.white,
    iconPrimary: AppColors.darkTextPrimary,
    iconSecondary: AppColors.darkTextSecondary,
    statusSynced: AppColors.success,
    statusPending: AppColors.warning,
    statusRequiresAction: AppColors.error,
    statusSuccess: AppColors.success,
    statusWarning: AppColors.warning,
    statusError: AppColors.error,
    statusInfo: AppColors.info,
    ctaPrimary: AppColors.primaryPurple,
    ctaSecondary: AppColors.darkSurfaceAccent,
    ctaDestructive: AppColors.error,
    borderSubtle: AppColors.darkBorderSubtle,
    borderStrong: AppColors.darkBorderStrong,
    densityCompact: 8,
    densityRegular: 16,
    primaryGradient: AppColors.primaryGradient,
    cardGradientPurple: AppColors.primaryGradient,
    cardGradientCyan: AppColors.cyanGradient,
    cardGradientBlue: AppColors.blueGradient,
    cardGradientRed: AppColors.redGradient,
    cardShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    bottomNavShadow: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 12,
        offset: Offset(0, -4),
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
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceAccent,
    Color? surfaceCritical,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnAccent,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? statusSynced,
    Color? statusPending,
    Color? statusRequiresAction,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusError,
    Color? statusInfo,
    Color? ctaPrimary,
    Color? ctaSecondary,
    Color? ctaDestructive,
    Color? borderSubtle,
    Color? borderStrong,
    double? densityCompact,
    double? densityRegular,
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
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      surfaceCritical: surfaceCritical ?? this.surfaceCritical,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      statusSynced: statusSynced ?? this.statusSynced,
      statusPending: statusPending ?? this.statusPending,
      statusRequiresAction: statusRequiresAction ?? this.statusRequiresAction,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
      statusInfo: statusInfo ?? this.statusInfo,
      ctaPrimary: ctaPrimary ?? this.ctaPrimary,
      ctaSecondary: ctaSecondary ?? this.ctaSecondary,
      ctaDestructive: ctaDestructive ?? this.ctaDestructive,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      densityCompact: densityCompact ?? this.densityCompact,
      densityRegular: densityRegular ?? this.densityRegular,
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
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceAccent: Color.lerp(surfaceAccent, other.surfaceAccent, t)!,
      surfaceCritical: Color.lerp(surfaceCritical, other.surfaceCritical, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      statusSynced: Color.lerp(statusSynced, other.statusSynced, t)!,
      statusPending: Color.lerp(statusPending, other.statusPending, t)!,
      statusRequiresAction:
          Color.lerp(statusRequiresAction, other.statusRequiresAction, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      ctaPrimary: Color.lerp(ctaPrimary, other.ctaPrimary, t)!,
      ctaSecondary: Color.lerp(ctaSecondary, other.ctaSecondary, t)!,
      ctaDestructive: Color.lerp(ctaDestructive, other.ctaDestructive, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      densityCompact: _lerpDouble(densityCompact, other.densityCompact, t),
      densityRegular: _lerpDouble(densityRegular, other.densityRegular, t),
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      cardGradientPurple:
          LinearGradient.lerp(cardGradientPurple, other.cardGradientPurple, t)!,
      cardGradientCyan:
          LinearGradient.lerp(cardGradientCyan, other.cardGradientCyan, t)!,
      cardGradientBlue:
          LinearGradient.lerp(cardGradientBlue, other.cardGradientBlue, t)!,
      cardGradientRed:
          LinearGradient.lerp(cardGradientRed, other.cardGradientRed, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      buttonShadow: BoxShadow.lerpList(buttonShadow, other.buttonShadow, t)!,
      bottomNavShadow:
          BoxShadow.lerpList(bottomNavShadow, other.bottomNavShadow, t)!,
      borderRadiusSmall:
          _lerpDouble(borderRadiusSmall, other.borderRadiusSmall, t),
      borderRadiusMedium:
          _lerpDouble(borderRadiusMedium, other.borderRadiusMedium, t),
      borderRadiusLarge:
          _lerpDouble(borderRadiusLarge, other.borderRadiusLarge, t),
      borderRadiusXLarge:
          _lerpDouble(borderRadiusXLarge, other.borderRadiusXLarge, t),
      spacingXSmall: _lerpDouble(spacingXSmall, other.spacingXSmall, t),
      spacingSmall: _lerpDouble(spacingSmall, other.spacingSmall, t),
      spacingMedium: _lerpDouble(spacingMedium, other.spacingMedium, t),
      spacingLarge: _lerpDouble(spacingLarge, other.spacingLarge, t),
      spacingXLarge: _lerpDouble(spacingXLarge, other.spacingXLarge, t),
      glassBlurSigma: _lerpDouble(glassBlurSigma, other.glassBlurSigma, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

extension ThemeExtensions on ThemeData {
  AppThemeExtension get appTokens =>
      extension<AppThemeExtension>() ??
      (brightness == Brightness.dark
          ? AppThemeExtension.dark
          : AppThemeExtension.light);
  AppThemeExtension get custom => appTokens;
}
