// lib/features/settings/presentation/providers/theme_provider.dart

import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/app_settings.dart';

part 'theme_provider.g.dart';

/// Theme Provider
///
/// Manages the current theme mode (light/dark/system) and persists
/// changes to local storage via AppSettings.
@Riverpod(keepAlive: true)
class Theme extends _$Theme {
  @override
  AppThemeMode build() {
    // Load theme asynchronously without blocking UI
    _loadTheme();
    // Return default while loading
    return AppThemeMode.system;
  }

  /// Load theme from storage
  Future<void> _loadTheme() async {
    final getSettings = ref.read(getSettingsProvider);
    final result = await getSettings();

    result.fold(
      (_) {
        // On error, keep system default
        state = AppThemeMode.system;
      },
      (settings) {
        // Update state with loaded theme
        state = settings.themeMode;
      },
    );
  }

  /// Change theme and persist to storage
  Future<void> setTheme(AppThemeMode mode) async {
    // Optimistic update - change immediately for better UX
    state = mode;

    // Persist to storage
    final saveSettings = ref.read(saveSettingsProvider);
    final getSettings = ref.read(getSettingsProvider);

    final currentResult = await getSettings();
    final current = currentResult.getOrElse(() => const AppSettings());

    final result = await saveSettings(current.copyWith(themeMode: mode));

    result.fold(
      (failure) {
        // On save error, could revert or show error
        // For now, keep the optimistic update
      },
      (_) {
        // Successfully saved
      },
    );
  }

  /// Convert to Flutter ThemeMode for MaterialApp
  ThemeMode get flutterThemeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
