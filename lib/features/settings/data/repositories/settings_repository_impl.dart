// lib/features/settings/data/repositories/settings_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/models/app_settings_model.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/settings_repository.dart';

/// Settings Repository Implementation
///
/// Manages app settings persistence in local storage (Hive).
/// Settings are local-only (no remote sync).
class SettingsRepositoryImpl implements SettingsRepository {

  SettingsRepositoryImpl({required this.localDataSource});
  final SettingsLocalDataSource localDataSource;

  @override
  Future<Either<SettingsFailure, AppSettings>> getSettings() async {
    try {
      final model = await localDataSource.getSettings();

      // Return cached settings or default
      if (model != null) {
        return Right(model.toEntity());
      }

      // Return default settings if none cached
      return const Right(AppSettings());
    } on SettingsLocalException catch (e) {
      return Left(SettingsFailure.storageError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.settingsSaveError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> saveSettings(
    AppSettings settings,
  ) async {
    try {
      final model = AppSettingsModel.fromEntity(settings);
      await localDataSource.saveSettings(model);
      return const Right(unit);
    } on SettingsLocalException catch (e) {
      return Left(SettingsFailure.storageError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.settingsSaveError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> clearAllData() async {
    try {
      await localDataSource.clearSettings();
      return const Right(unit);
    } on SettingsLocalException catch (e) {
      return Left(SettingsFailure.storageError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.settingsSaveError('Unexpected error: $e'),
      );
    }
  }
}
