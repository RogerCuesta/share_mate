// lib/features/settings/domain/usecases/get_profile.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/entities/user_profile.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/profile_repository.dart';

/// Use case: Get User Profile
///
/// Fetches the user profile for a given user ID.
class GetProfile {

  GetProfile(this.repository);
  final ProfileRepository repository;

  Future<Either<SettingsFailure, UserProfile>> call(String userId) async {
    return repository.getProfile(userId);
  }
}
