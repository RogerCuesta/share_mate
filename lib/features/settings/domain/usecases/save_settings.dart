// lib/features/settings/domain/usecases/save_settings.dart

import 'package:dartz/dartz.dart';

import '../entities/app_settings.dart';
import '../failures/settings_failure.dart';
import '../repositories/settings_repository.dart';

/// Use case: Save App Settings
///
/// Persists app settings to local storage.
class SaveSettings {
  final SettingsRepository repository;

  SaveSettings(this.repository);

  Future<Either<SettingsFailure, Unit>> call(AppSettings settings) async {
    return repository.saveSettings(settings);
  }
}
