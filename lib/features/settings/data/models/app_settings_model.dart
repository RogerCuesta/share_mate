// lib/features/settings/data/models/app_settings_model.dart

import 'package:hive_ce/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/app_settings.dart';

part 'app_settings_model.g.dart';

/// App Settings Model for Hive persistence
///
/// Maps between AppSettings entity and Hive storage.
/// Stores user preferences locally (theme, language, notifications, etc.).
@HiveType(typeId: HiveTypeIds.appSettings) // typeId: 20
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  final String themeMode;

  @HiveField(1)
  final String language;

  @HiveField(2)
  final String currency;

  @HiveField(3)
  final String dateFormat;

  @HiveField(4)
  final bool paymentRemindersEnabled;

  @HiveField(5)
  final bool subscriptionChangesEnabled;

  @HiveField(6)
  final bool friendRequestsEnabled;

  @HiveField(7)
  final DateTime? lastUpdated;

  AppSettingsModel({
    this.themeMode = 'system',
    this.language = 'en',
    this.currency = 'USD',
    this.dateFormat = 'ddMMyyyy',
    this.paymentRemindersEnabled = true,
    this.subscriptionChangesEnabled = true,
    this.friendRequestsEnabled = true,
    this.lastUpdated,
  });

  /// Create model from domain entity
  factory AppSettingsModel.fromEntity(AppSettings entity) => AppSettingsModel(
        themeMode: _themeModeToString(entity.themeMode),
        language: entity.language,
        currency: entity.currency,
        dateFormat: _dateFormatToString(entity.dateFormat),
        paymentRemindersEnabled: entity.paymentRemindersEnabled,
        subscriptionChangesEnabled: entity.subscriptionChangesEnabled,
        friendRequestsEnabled: entity.friendRequestsEnabled,
        lastUpdated: entity.lastUpdated,
      );

  /// Convert model to domain entity
  AppSettings toEntity() => AppSettings(
        themeMode: _parseThemeMode(themeMode),
        language: language,
        currency: currency,
        dateFormat: _parseDateFormat(dateFormat),
        paymentRemindersEnabled: paymentRemindersEnabled,
        subscriptionChangesEnabled: subscriptionChangesEnabled,
        friendRequestsEnabled: friendRequestsEnabled,
        lastUpdated: lastUpdated,
      );

  // Conversion helpers

  static AppThemeMode _parseThemeMode(String value) {
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  static String _themeModeToString(AppThemeMode mode) => mode.name;

  static DateFormatType _parseDateFormat(String value) {
    return DateFormatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DateFormatType.ddMMyyyy,
    );
  }

  static String _dateFormatToString(DateFormatType format) => format.name;
}
