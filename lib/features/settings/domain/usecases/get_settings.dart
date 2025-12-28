// lib/features/settings/domain/usecases/get_settings.dart

import 'package:dartz/dartz.dart';

import '../entities/app_settings.dart';
import '../failures/settings_failure.dart';
import '../repositories/settings_repository.dart';

/// Use case: Get App Settings
///
/// Retrieves the current app settings from local storage.
class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<Either<SettingsFailure, AppSettings>> call() async {
    return repository.getSettings();
  }
}
