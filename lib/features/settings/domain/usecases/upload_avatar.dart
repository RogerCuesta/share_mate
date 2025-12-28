// lib/features/settings/domain/usecases/upload_avatar.dart

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../failures/settings_failure.dart';
import '../repositories/profile_repository.dart';

/// Use case: Upload Avatar
///
/// Uploads a user avatar image and validates file size.
class UploadAvatar {
  final ProfileRepository repository;

  // 5MB max file size
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  UploadAvatar(this.repository);

  Future<Either<SettingsFailure, String>> call(
    String userId,
    Uint8List imageData,
  ) async {
    // Validate file size
    if (imageData.length > maxFileSizeBytes) {
      return const Left(SettingsFailure.fileTooLarge(5));
    }

    return repository.uploadAvatar(userId, imageData);
  }
}
