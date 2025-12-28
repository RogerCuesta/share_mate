// lib/features/settings/domain/failures/settings_failure.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_failure.freezed.dart';

/// Settings Feature Failures
///
/// Represents all possible failures that can occur in the settings feature
/// including profile updates, avatar management, account operations, and more.
@freezed
class SettingsFailure with _$SettingsFailure {
  const factory SettingsFailure.profileUpdateError(String message) =
      _ProfileUpdateError;
  const factory SettingsFailure.avatarUploadError(String message) =
      _AvatarUploadError;
  const factory SettingsFailure.avatarDeleteError(String message) =
      _AvatarDeleteError;
  const factory SettingsFailure.settingsSaveError(String message) =
      _SettingsSaveError;
  const factory SettingsFailure.passwordChangeError(String message) =
      _PasswordChangeError;
  const factory SettingsFailure.accountDeletionError(String message) =
      _AccountDeletionError;
  const factory SettingsFailure.networkError() = _NetworkError;
  const factory SettingsFailure.storageError(String message) = _StorageError;
  const factory SettingsFailure.validationError(String message) =
      _ValidationError;
  const factory SettingsFailure.fileTooLarge(int maxSizeMB) = _FileTooLarge;
  const factory SettingsFailure.invalidFileType(String acceptedTypes) =
      _InvalidFileType;
  const factory SettingsFailure.emailVerificationError(String message) =
      _EmailVerificationError;
}
