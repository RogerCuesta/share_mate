// lib/features/settings/domain/repositories/settings_repository.dart

import 'package:dartz/dartz.dart';

import '../entities/app_settings.dart';
import '../failures/settings_failure.dart';

/// Settings Repository Interface
///
/// Defines operations for managing app settings including
/// theme, language, notifications, and other preferences.
abstract class SettingsRepository {
  /// Get current app settings
  Future<Either<SettingsFailure, AppSettings>> getSettings();

  /// Save app settings
  Future<Either<SettingsFailure, Unit>> saveSettings(AppSettings settings);

  /// Clear all local data (for logout)
  Future<Either<SettingsFailure, Unit>> clearAllData();
}
