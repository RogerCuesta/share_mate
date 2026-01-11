// lib/features/settings/domain/usecases/get_settings.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/settings_repository.dart';

/// Use case: Get App Settings
///
/// Retrieves the current app settings from local storage.
class GetSettings {

  GetSettings(this.repository);
  final SettingsRepository repository;

  Future<Either<SettingsFailure, AppSettings>> call() async {
    return repository.getSettings();
  }
}
