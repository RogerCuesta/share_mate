// lib/features/settings/domain/usecases/delete_avatar.dart

import 'package:dartz/dartz.dart';

import '../failures/settings_failure.dart';
import '../repositories/profile_repository.dart';

/// Use case: Delete Avatar
///
/// Deletes the user's avatar from storage.
class DeleteAvatar {
  final ProfileRepository repository;

  DeleteAvatar(this.repository);

  Future<Either<SettingsFailure, Unit>> call(String userId) async {
    return repository.deleteAvatar(userId);
  }
}
