// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Brand color palettes for SubMate
///
/// Defines light and dark color schemes following Material 3 guidelines
/// with custom brand colors for gradients and special UI elements.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // =========================================================================
  // BRAND COLORS (Theme-independent)
  // =========================================================================

  /// Primary brand purple
  static const Color primaryPurple = Color(0xFF6C63FF);

  /// Secondary brand colors
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentGreen = Color(0xFF4ECDC4);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentBlue = Color(0xFF4A90E2);

  // =========================================================================
  // LIGHT THEME COLORS
  // =========================================================================

  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF0F0F0);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF2D2D44);

  /// Light theme elevation/shadow colors
  static const Color lightShadow = Color(0x1A000000); // 10% black
  static const Color lightBorder = Color(0x1AFFFFFF); // 10% white

  // =========================================================================
  // DARK THEME COLORS
  // =========================================================================

  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF2D2D44);
  static const Color darkSurfaceVariant = Color(0xFF353553);
  static const Color darkOnBackground = Colors.white;
  static const Color darkOnSurface = Color(0xFFE1E1E1);

  /// Dark theme elevation/shadow colors
  static const Color darkShadow = Color(0x33000000); // 20% black
  static const Color darkBorder = Color(0x1AFFFFFF); // 10% white

  // =========================================================================
  // SEMANTIC COLORS (Theme-aware)
  // =========================================================================

  /// Success color (used in both themes)
  static const Color success = accentGreen;

  /// Error color (used in both themes)
  static const Color error = accentRed;

  /// Warning color
  static const Color warning = Color(0xFFFFA726);

  /// Info color
  static const Color info = accentCyan;

  // =========================================================================
  // GRADIENTS
  // =========================================================================

  /// Primary gradient (purple)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
  );

  /// Cyan gradient (for cards)
  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4FF), Color(0xFF4ECDC4)],
  );

  /// Blue gradient (for cards)
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A90E2), Color(0xFF5FA8FF)],
  );

  /// Red gradient (for cards)
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
  );
}
