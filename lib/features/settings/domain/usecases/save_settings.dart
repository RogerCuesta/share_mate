// lib/features/settings/domain/usecases/save_settings.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/settings_repository.dart';

/// Use case: Save App Settings
///
/// Persists app settings to local storage.
class SaveSettings {

  SaveSettings(this.repository);
  final SettingsRepository repository;

  Future<Either<SettingsFailure, Unit>> call(AppSettings settings) async {
    return repository.saveSettings(settings);
  }
}
