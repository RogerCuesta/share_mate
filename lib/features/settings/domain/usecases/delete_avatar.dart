// lib/features/settings/domain/usecases/delete_avatar.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/profile_repository.dart';

/// Use case: Delete Avatar
///
/// Deletes the user's avatar from storage.
class DeleteAvatar {

  DeleteAvatar(this.repository);
  final ProfileRepository repository;

  Future<Either<SettingsFailure, Unit>> call(String userId) async {
    return repository.deleteAvatar(userId);
  }
}
