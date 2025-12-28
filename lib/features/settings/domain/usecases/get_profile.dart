// lib/features/settings/domain/usecases/get_profile.dart

import 'package:dartz/dartz.dart';

import '../entities/user_profile.dart';
import '../failures/settings_failure.dart';
import '../repositories/profile_repository.dart';

/// Use case: Get User Profile
///
/// Fetches the user profile for a given user ID.
class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  Future<Either<SettingsFailure, UserProfile>> call(String userId) async {
    return repository.getProfile(userId);
  }
}
