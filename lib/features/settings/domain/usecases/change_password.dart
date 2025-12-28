// lib/features/settings/domain/usecases/change_password.dart

import 'package:dartz/dartz.dart';

import '../failures/settings_failure.dart';
import '../repositories/account_repository.dart';

/// Use case: Change Password
///
/// Changes the user's password with validation.
class ChangePassword {
  final AccountRepository repository;

  // Minimum password length
  static const int minPasswordLength = 8;

  ChangePassword(this.repository);

  Future<Either<SettingsFailure, Unit>> call({
    required String newPassword,
  }) async {
    // Validate password length
    if (newPassword.length < minPasswordLength) {
      return Left(
        SettingsFailure.validationError(
          'Password must be at least $minPasswordLength characters',
        ),
      );
    }

    return repository.changePassword(newPassword: newPassword);
  }
}
