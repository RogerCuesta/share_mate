// lib/features/friends/domain/entities/friend.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';

/// Denormalized Friend entity for display purposes
///
/// Combines Friendship + Profile data to simplify UI layer.
/// Contains all necessary information to display a friend in lists.
@freezed
class Friend with _$Friend {
  const factory Friend({
    required String friendshipId,
    required String userId,
    required String fullName,
    required String email,
    String? avatarUrl,
    required DateTime friendsSince,
  }) = _Friend;
}
