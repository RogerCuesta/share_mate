// lib/features/settings/domain/entities/app_settings.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// App Settings Entity
///
/// Represents user preferences for app behavior including theme,
/// language, currency, date format, and notification preferences.
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default('en') String language,
    @Default('USD') String currency,
    @Default(DateFormatType.ddMMyyyy) DateFormatType dateFormat,
    @Default(true) bool paymentRemindersEnabled,
    @Default(true) bool subscriptionChangesEnabled,
    @Default(true) bool friendRequestsEnabled,
    DateTime? lastUpdated,
  }) = _AppSettings;

  const AppSettings._();

  /// Check if notification settings are enabled
  bool get hasNotificationsEnabled =>
      paymentRemindersEnabled ||
      subscriptionChangesEnabled ||
      friendRequestsEnabled;
}

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system;

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

/// Date format options
enum DateFormatType {
  ddMMyyyy, // 28/12/2025
  mmDDyyyy, // 12/28/2025
  yyyyMMdd; // 2025-12-28

  String get displayName {
    switch (this) {
      case DateFormatType.ddMMyyyy:
        return 'DD/MM/YYYY';
      case DateFormatType.mmDDyyyy:
        return 'MM/DD/YYYY';
      case DateFormatType.yyyyMMdd:
        return 'YYYY-MM-DD';
    }
  }

  String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    switch (this) {
      case DateFormatType.ddMMyyyy:
        return '$day/$month/$year';
      case DateFormatType.mmDDyyyy:
        return '$month/$day/$year';
      case DateFormatType.yyyyMMdd:
        return '$year-$month-$day';
    }
  }
}
