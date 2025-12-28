// lib/features/settings/presentation/providers/profile_provider.dart

import 'dart:typed_data';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

/// Current User Profile Provider
///
/// Manages the current authenticated user's profile with
/// reactive updates when profile changes.
@riverpod
class CurrentUserProfile extends _$CurrentUserProfile {
  @override
  Future<UserProfile?> build() async {
    // Get current user ID from auth
    final authState = ref.watch(authProvider);

    return authState.maybeWhen(
      authenticated: (user) => _fetchProfile(user.id),
      orElse: () => null,
    );
  }

  /// Fetch profile from repository
  Future<UserProfile?> _fetchProfile(String userId) async {
    final getProfile = ref.read(getProfileProvider);
    final result = await getProfile(userId);

    return result.fold(
      (_) => null,
      (profile) => profile,
    );
  }

  /// Update user profile
  Future<bool> updateProfile(UserProfile profile) async {
    final updateProfileUseCase = ref.read(updateProfileProvider);
    final result = await updateProfileUseCase.call(profile);

    return result.fold(
      (failure) {
        // Handle error - could show snackbar here
        return false;
      },
      (updatedProfile) {
        // Update state with new profile
        state = AsyncData(updatedProfile);
        return true;
      },
    );
  }

  /// Upload avatar and update profile
  Future<bool> uploadAvatar(String userId, Uint8List imageData) async {
    final uploadAvatarUseCase = ref.read(uploadAvatarProvider);
    final result = await uploadAvatarUseCase.call(userId, imageData);

    return result.fold(
      (failure) => false,
      (avatarUrl) async {
        // Get current profile
        final currentProfile = state.value;
        if (currentProfile == null) return false;

        // Update profile with new avatar URL
        final updatedProfile = currentProfile.copyWith(avatarUrl: avatarUrl);
        return updateProfile(updatedProfile);
      },
    );
  }

  /// Delete avatar and update profile
  Future<bool> deleteAvatar(String userId) async {
    final deleteAvatarUseCase = ref.read(deleteAvatarProvider);
    final result = await deleteAvatarUseCase.call(userId);

    return result.fold(
      (failure) => false,
      (_) async {
        // Get current profile
        final currentProfile = state.value;
        if (currentProfile == null) return false;

        // Update profile with null avatar URL
        final updatedProfile = currentProfile.copyWith(avatarUrl: null);
        return updateProfile(updatedProfile);
      },
    );
  }

  /// Refresh profile data from server
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authProvider);
      return authState.maybeWhen(
        authenticated: (user) => _fetchProfile(user.id),
        orElse: () => null,
      );
    });
  }
}
