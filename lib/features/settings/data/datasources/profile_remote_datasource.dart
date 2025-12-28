// lib/features/settings/data/datasources/profile_remote_datasource.dart

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile_model.dart';

/// Profile Remote Data Source Interface
abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String userId);
  Future<UserProfileModel> updateProfile(UserProfileModel profile);
  Future<String> uploadAvatar(String userId, Uint8List imageData);
  Future<void> deleteAvatar(String userId);
}

/// Profile Remote Data Source Implementation (Supabase)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient client;

  ProfileRemoteDataSourceImpl({required this.client});

  @override
  Future<UserProfileModel> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw ProfileRemoteException('Failed to fetch profile: $e');
    }
  }

  @override
  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    try {
      final response = await client
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.userId)
          .select()
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw ProfileRemoteException('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadAvatar(String userId, Uint8List imageData) async {
    try {
      final fileName = 'profile.jpg';
      final path = '$userId/$fileName';

      // Upload to Supabase Storage
      await client.storage.from('avatars').uploadBinary(
            path,
            imageData,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true, // Overwrite if exists
            ),
          );

      // Get public URL
      final url = client.storage.from('avatars').getPublicUrl(path);
      return url;
    } catch (e) {
      throw AvatarUploadException('Failed to upload avatar: $e');
    }
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      final path = '$userId/profile.jpg';
      await client.storage.from('avatars').remove([path]);
    } catch (e) {
      throw AvatarDeleteException('Failed to delete avatar: $e');
    }
  }
}

/// Exception thrown when profile remote operations fail
class ProfileRemoteException implements Exception {
  final String message;
  ProfileRemoteException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when avatar upload fails
class AvatarUploadException implements Exception {
  final String message;
  AvatarUploadException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when avatar deletion fails
class AvatarDeleteException implements Exception {
  final String message;
  AvatarDeleteException(this.message);

  @override
  String toString() => message;
}
