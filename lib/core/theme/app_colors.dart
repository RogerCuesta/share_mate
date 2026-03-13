import 'package:flutter/material.dart';

/// Central color tokens for Share Mate.
class AppColors {
  AppColors._();

  // Legacy brand tokens kept for compatibility while screens migrate.
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color accentCyan = Color(0xFF39B9FF);
  static const Color accentGreen = Color(0xFF24C9A2);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentBlue = Color(0xFF4A90E2);

  // Dark transactional system (Phase 6 source of truth).
  static const Color darkSurfaceBase = Color(0xFF0F1525);
  static const Color darkSurfaceRaised = Color(0xFF1A2336);
  static const Color darkSurfaceAccent = Color(0xFF24344F);
  static const Color darkSurfaceCritical = Color(0xFF39212B);
  static const Color darkTextPrimary = Color(0xFFF4F7FF);
  static const Color darkTextSecondary = Color(0xFFB9C4DD);
  static const Color darkTextMuted = Color(0xFF7E8AAA);
  static const Color darkBorderSubtle = Color(0xFF2A3550);
  static const Color darkBorderStrong = Color(0xFF435377);

  // Light support theme (kept coherent with semantic tokens).
  static const Color lightSurfaceBase = Color(0xFFF5F7FB);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightSurfaceAccent = Color(0xFFEAF0FF);
  static const Color lightSurfaceCritical = Color(0xFFFCEEF1);
  static const Color lightTextPrimary = Color(0xFF1A2336);
  static const Color lightTextSecondary = Color(0xFF495978);
  static const Color lightTextMuted = Color(0xFF7080A0);
  static const Color lightBorderSubtle = Color(0xFFD8DEEA);
  static const Color lightBorderStrong = Color(0xFFB7C2D8);

  // Shared semantic tones.
  static const Color success = Color(0xFF2FD4A4);
  static const Color warning = Color(0xFFFFC55E);
  static const Color error = Color(0xFFFF7070);
  static const Color info = Color(0xFF53C5FF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D7CFF), Color(0xFF5F65E8)],
  );
  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF41C8FF), Color(0xFF2E9DFF)],
  );
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6180FF), Color(0xFF4B5FE0)],
  );
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8080), Color(0xFFE45D6F)],
  );
}
