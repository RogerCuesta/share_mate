// lib/features/settings/data/datasources/settings_local_datasource.dart

import 'package:hive/hive.dart';

import '../models/app_settings_model.dart';

/// Settings Local Data Source Interface
abstract class SettingsLocalDataSource {
  Future<void> init();
  Future<AppSettingsModel?> getSettings();
  Future<void> saveSettings(AppSettingsModel settings);
  Future<void> clearSettings();
}

/// Settings Local Data Source Implementation (Hive)
///
/// Stores app settings locally (theme, language, notifications, etc.)
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _boxName = 'app_settings';
  static const String _settingsKey = 'current_settings';
  Box<AppSettingsModel>? _box;

  @override
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<AppSettingsModel>(_boxName);
    }
  }

  @override
  Future<AppSettingsModel?> getSettings() async {
    try {
      await init();
      return _box!.get(_settingsKey);
    } catch (e) {
      throw SettingsLocalException('Failed to get settings: $e');
    }
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    try {
      await init();
      await _box!.put(_settingsKey, settings);
    } catch (e) {
      throw SettingsLocalException('Failed to save settings: $e');
    }
  }

  @override
  Future<void> clearSettings() async {
    try {
      await init();
      await _box!.delete(_settingsKey);
    } catch (e) {
      throw SettingsLocalException('Failed to clear settings: $e');
    }
  }
}

/// Exception thrown when settings local operations fail
class SettingsLocalException implements Exception {
  final String message;
  SettingsLocalException(this.message);

  @override
  String toString() => message;
}
