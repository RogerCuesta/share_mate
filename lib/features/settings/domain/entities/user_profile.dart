// lib/features/settings/domain/entities/user_profile.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// User Profile Entity
///
/// Represents a user's profile information including avatar, bio,
/// and privacy settings for friend discoverability.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    required String email,
    required String fullName,
    required DateTime createdAt, String? avatarUrl,
    String? bio,
    @Default(true) bool isDiscoverable,
    DateTime? updatedAt,
  }) = _UserProfile;

  const UserProfile._();

  /// Validate bio length (max 150 chars)
  bool get isBioValid => bio == null || bio!.length <= 150;

  /// Check if profile has an avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Get initials from full name for default avatar
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';

    final names = trimmed.split(' ').where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return '?';
    if (names.length == 1) return names[0][0].toUpperCase();

    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }
}
