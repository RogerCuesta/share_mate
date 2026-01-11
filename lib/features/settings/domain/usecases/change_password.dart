// lib/features/settings/domain/usecases/change_password.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/account_repository.dart';

/// Use case: Change Password
///
/// Changes the user's password with validation.
class ChangePassword {

  ChangePassword(this.repository);
  final AccountRepository repository;

  // Minimum password length
  static const int minPasswordLength = 8;

  Future<Either<SettingsFailure, Unit>> call({
    required String newPassword,
  }) async {
    // Validate password length
    if (newPassword.length < minPasswordLength) {
      return const Left(
        SettingsFailure.validationError(
          'Password must be at least $minPasswordLength characters',
        ),
      );
    }

    return repository.changePassword(newPassword: newPassword);
  }
}
