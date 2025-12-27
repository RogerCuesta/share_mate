// lib/features/friends/domain/entities/friendship.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship.freezed.dart';

/// Friendship status enum
///
/// Represents the lifecycle of a friendship:
/// - pending: Friend request sent, awaiting response
/// - accepted: Both users are friends
/// - rejected: Friend request was rejected
/// - removed: Friendship was terminated by either party
enum FriendshipStatus {
  pending,
  accepted,
  rejected,
  removed,
}

/// Friendship entity representing the relationship between two users
///
/// Uses a single-row bidirectional model where:
/// - user_id < friend_id (normalized ordering)
/// - initiator_id tracks who sent the request
/// - status tracks the current state of the friendship
@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    required String id,
    required String userId,
    required String friendId,
    required FriendshipStatus status,
    required String initiatorId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Friendship;

  const Friendship._();

  /// Returns true if the current user initiated this friendship
  bool isInitiatedBy(String currentUserId) {
    return initiatorId == currentUserId;
  }

  /// Returns the other user's ID (the friend's ID from perspective of userId)
  String getOtherUserId(String currentUserId) {
    return userId == currentUserId ? friendId : userId;
  }

  /// Returns true if this friendship is currently active
  bool get isActive => status == FriendshipStatus.accepted;

  /// Returns true if this friendship is pending
  bool get isPending => status == FriendshipStatus.pending;
}
