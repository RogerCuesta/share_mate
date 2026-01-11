// lib/features/settings/domain/usecases/update_profile.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/entities/user_profile.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/profile_repository.dart';

/// Use case: Update User Profile
///
/// Updates the user profile with validation for bio length.
class UpdateProfile {

  UpdateProfile(this.repository);
  final ProfileRepository repository;

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
