// lib/features/settings/domain/repositories/profile_repository.dart

import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../entities/user_profile.dart';
import '../failures/settings_failure.dart';

/// Profile Repository Interface
///
/// Defines operations for managing user profiles including
/// fetching, updating, and avatar management.
abstract class ProfileRepository {
  /// Get user profile by user ID
  Future<Either<SettingsFailure, UserProfile>> getProfile(String userId);

  /// Update user profile
  Future<Either<SettingsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  );

  /// Upload user avatar and return the URL
  Future<Either<SettingsFailure, String>> uploadAvatar(
    String userId,
    Uint8List imageData,
  );

  /// Delete user avatar
  Future<Either<SettingsFailure, Unit>> deleteAvatar(String userId);
}
