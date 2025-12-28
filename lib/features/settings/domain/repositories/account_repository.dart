// lib/features/settings/domain/repositories/account_repository.dart

import 'package:dartz/dartz.dart';

import '../failures/settings_failure.dart';

/// Account Repository Interface
///
/// Defines operations for account management including
/// password changes, email verification, and account deletion.
abstract class AccountRepository {
  /// Change user password
  Future<Either<SettingsFailure, Unit>> changePassword({
    required String newPassword,
  });

  /// Send email verification to current user
  Future<Either<SettingsFailure, Unit>> sendEmailVerification();

  /// Check if user's email is verified
  Future<Either<SettingsFailure, bool>> checkEmailVerified();

  /// Delete user account permanently
  Future<Either<SettingsFailure, Unit>> deleteAccount(String userId);
}
