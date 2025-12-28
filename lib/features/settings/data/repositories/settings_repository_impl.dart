// lib/features/settings/data/repositories/settings_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/failures/settings_failure.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings_model.dart';

/// Settings Repository Implementation
///
/// Manages app settings persistence in local storage (Hive).
/// Settings are local-only (no remote sync).
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

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
