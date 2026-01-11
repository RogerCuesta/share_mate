// lib/features/settings/data/repositories/profile_repository_impl.dart

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/profile_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/models/user_profile_model.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/user_profile.dart';
import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/profile_repository.dart';
import 'package:image/image.dart' as img;

/// Profile Repository Implementation
///
/// Implements offline-first strategy:
/// - Try remote first
/// - Cache successful responses locally
/// - Fallback to cache on network errors
class ProfileRepositoryImpl implements ProfileRepository {

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;

  @override
  Future<Either<SettingsFailure, UserProfile>> getProfile(
    String userId,
  ) async {
    try {
      // Try remote first
      final model = await remoteDataSource.getProfile(userId);

      // Cache the result
      await localDataSource.cacheProfile(model);

      return Right(model.toEntity());
    } on ProfileRemoteException catch (e) {
      // Network error - try cache
      try {
        final cachedModel = await localDataSource.getProfile(userId);
        if (cachedModel != null) {
          return Right(cachedModel.toEntity());
        }
        return const Left(SettingsFailure.networkError());
      } catch (_) {
        return Left(SettingsFailure.profileUpdateError(e.message));
      }
    } catch (e) {
      return Left(
        SettingsFailure.profileUpdateError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, UserProfile>> updateProfile(
    UserProfile profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);

      // Update remote
      final updatedModel = await remoteDataSource.updateProfile(model);

      // Update cache
      await localDataSource.cacheProfile(updatedModel);

      return Right(updatedModel.toEntity());
    } on ProfileRemoteException catch (e) {
      return Left(SettingsFailure.profileUpdateError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.profileUpdateError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, String>> uploadAvatar(
    String userId,
    Uint8List imageData,
  ) async {
    try {
      // Resize image to 512x512 to save bandwidth and storage
      final resizedImageData = await _resizeImage(imageData);

      // Upload to Supabase Storage
      final url = await remoteDataSource.uploadAvatar(userId, resizedImageData);

      return Right(url);
    } on AvatarUploadException catch (e) {
      return Left(SettingsFailure.avatarUploadError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.avatarUploadError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> deleteAvatar(String userId) async {
    try {
      await remoteDataSource.deleteAvatar(userId);
      return const Right(unit);
    } on AvatarDeleteException catch (e) {
      return Left(SettingsFailure.avatarDeleteError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.avatarDeleteError('Unexpected error: $e'),
      );
    }
  }

  /// Resize image to 512x512 for optimal storage and bandwidth
  Future<Uint8List> _resizeImage(Uint8List imageData) async {
    try {
      // Decode image
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to 512x512 maintaining aspect ratio
      final resized = img.copyResize(
        image,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.average,
      );

      // Encode as JPEG with 85% quality
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      // If resizing fails, return original
      return imageData;
    }
  }
}
