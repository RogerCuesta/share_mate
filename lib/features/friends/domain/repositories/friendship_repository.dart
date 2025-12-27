// lib/features/friends/domain/repositories/friendship_repository.dart

import 'package:dartz/dartz.dart';

import '../entities/friend.dart';
import '../entities/friendship.dart';
import '../entities/profile.dart';
import '../failures/friendship_failure.dart';

/// Repository interface for friendship operations
///
/// Defines the contract for friendship data operations.
/// Implementation in data layer handles offline-first strategy.
abstract class FriendshipRepository {
  /// Send a friend request to a user by email
  ///
  /// Returns the friendship ID if successful.
  /// Throws [FriendshipFailure.userNotFound] if email doesn't exist.
  /// Throws [FriendshipFailure.alreadyFriends] if already friends or request pending.
  /// Throws [FriendshipFailure.cannotAddSelf] if trying to add yourself.
  Future<Either<FriendshipFailure, String>> sendFriendRequest({
    required String friendEmail,
  });

  /// Accept a pending friend request
  ///
  /// Throws [FriendshipFailure.requestNotFound] if request doesn't exist or already processed.
  /// Throws [FriendshipFailure.unauthorized] if user is not the recipient.
  Future<Either<FriendshipFailure, void>> acceptFriendRequest({
    required String friendshipId,
  });

  /// Reject a pending friend request
  ///
  /// Throws [FriendshipFailure.requestNotFound] if request doesn't exist or already processed.
  /// Throws [FriendshipFailure.unauthorized] if user is not the recipient.
  Future<Either<FriendshipFailure, void>> rejectFriendRequest({
    required String friendshipId,
  });

  /// Remove an existing friendship
  ///
  /// Throws [FriendshipFailure.friendshipNotFound] if friendship doesn't exist or not active.
  Future<Either<FriendshipFailure, void>> removeFriend({
    required String friendshipId,
  });

  /// Get list of all accepted friends for the current user
  ///
  /// Returns denormalized Friend entities with profile data.
  /// Tries remote first, falls back to cache on network error.
  Future<Either<FriendshipFailure, List<Friend>>> getFriends();

  /// Get list of pending friend requests received by current user
  ///
  /// Returns denormalized Friend entities for users who sent requests.
  /// Excludes requests initiated by current user.
  Future<Either<FriendshipFailure, List<Friend>>> getPendingRequests();

  /// Search for users by email (exact match)
  ///
  /// Returns profile + is_friend flag.
  /// Only returns discoverable users.
  /// Returns empty list if no match found.
  Future<Either<FriendshipFailure, List<Profile>>> searchUsersByEmail({
    required String email,
  });

  /// Get the current user's profile
  ///
  /// Used to display and edit user's own profile.
  Future<Either<FriendshipFailure, Profile>> getMyProfile();

  /// Update the current user's profile
  ///
  /// Allows updating: fullName, avatarUrl, isDiscoverable.
  /// Email cannot be changed (tied to auth.users).
  Future<Either<FriendshipFailure, Profile>> updateProfile({
    String? fullName,
    String? avatarUrl,
    bool? isDiscoverable,
  });
}
