// lib/features/settings/domain/usecases/update_profile.dart

import 'package:dartz/dartz.dart';

import '../entities/user_profile.dart';
import '../failures/settings_failure.dart';
import '../repositories/profile_repository.dart';

/// Use case: Update User Profile
///
/// Updates the user profile with validation for bio length.
class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<Either<SettingsFailure, UserProfile>> call(
    UserProfile profile,
  ) async {
    // Validate bio length
    if (!profile.isBioValid) {
      return const Left(
        SettingsFailure.validationError(
          'Bio must be 150 characters or less',
        ),
      );
    }

    return repository.updateProfile(profile);
  }
}
