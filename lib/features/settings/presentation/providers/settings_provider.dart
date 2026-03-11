// lib/features/settings/presentation/providers/settings_provider.dart

import 'dart:async';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

/// App Settings Provider
///
/// Manages app-wide settings including theme, language,
/// currency, date format, and notification preferences.
@riverpod
class Settings extends _$Settings {
  @override
  Future<AppSettings> build() async {
    return _loadSettings();
  }

  /// Load settings from storage
  Future<AppSettings> _loadSettings() async {
    final getSettings = ref.read(getSettingsProvider);
    final result = await getSettings();

    return result.fold(
      (_) => const AppSettings(), // Return defaults on error
      (settings) => settings,
    );
  }

  /// Update theme mode
  Future<bool> updateThemeMode(AppThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(current.copyWith(themeMode: mode));
  }

  /// Update language
  Future<bool> updateLanguage(String language) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(current.copyWith(language: language));
  }

  /// Update currency
  Future<bool> updateCurrency(String currency) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(current.copyWith(currency: currency));
  }

  /// Update date format
  Future<bool> updateDateFormat(DateFormatType dateFormat) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(current.copyWith(dateFormat: dateFormat));
  }

  /// Toggle payment reminders
  Future<bool> togglePaymentReminders({required bool enabled}) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(
      current.copyWith(paymentRemindersEnabled: enabled),
    );
  }

  /// Toggle subscription changes notifications
  Future<bool> toggleSubscriptionChanges({required bool enabled}) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(
      current.copyWith(subscriptionChangesEnabled: enabled),
    );
  }

  /// Toggle friend requests notifications
  Future<bool> toggleFriendRequests({required bool enabled}) async {
    final current = state.value ?? const AppSettings();
    return _saveSettings(
      current.copyWith(friendRequestsEnabled: enabled),
    );
  }

  /// Save settings and update state
  Future<bool> _saveSettings(AppSettings settings) async {
    final saveSettings = ref.read(saveSettingsProvider);
    final result = await saveSettings(settings);

    return result.fold(
      (failure) => false,
      (_) {
        // Update state with new settings
        state = AsyncData(settings);
        final orchestrator = ref.read(billingAutomationOrchestratorProvider);
        final reason = settings.paymentRemindersEnabled
            ? 'settings_payment_reminders_enabled'
            : 'settings_payment_reminders_disabled';
        if (settings.paymentRemindersEnabled) {
          unawaited(orchestrator.run(reason: reason));
        } else {
          unawaited(orchestrator.clearAll(reason: reason));
        }
        return true;
      },
    );
  }

  /// Reset to default settings
  Future<bool> resetToDefaults() async {
    return _saveSettings(const AppSettings());
  }

  /// Refresh settings from storage
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadSettings());
  }
}
