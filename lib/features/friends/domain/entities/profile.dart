// lib/features/friends/domain/entities/profile.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// User profile entity for the Friends feature
///
/// Represents the extended user profile with discoverable settings.
/// This is separate from the Auth User entity to support friends-specific fields.
@freezed
class Profile with _$Profile {
  const factory Profile({
    required String userId,
    required String fullName,
    required String email,
    String? avatarUrl,
    required bool isDiscoverable,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Profile;
}
