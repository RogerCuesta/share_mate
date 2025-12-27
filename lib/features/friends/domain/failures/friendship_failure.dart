// lib/features/friends/domain/failures/friendship_failure.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship_failure.freezed.dart';

/// Failure types for friendship operations
///
/// Represents all possible error states in the Friends feature.
/// Used with Either<FriendshipFailure, Success> pattern for error handling.
@freezed
class FriendshipFailure with _$FriendshipFailure {
  /// Server error (500, database errors, etc.)
  const factory FriendshipFailure.serverError([String? message]) = _ServerError;

  /// Network error (no internet, timeout, etc.)
  const factory FriendshipFailure.networkError([String? message]) = _NetworkError;

  /// User not found or not discoverable
  const factory FriendshipFailure.userNotFound([String? message]) = _UserNotFound;

  /// Friendship already exists or request already sent
  const factory FriendshipFailure.alreadyFriends([String? message]) = _AlreadyFriends;

  /// Cannot send friend request to yourself
  const factory FriendshipFailure.cannotAddSelf([String? message]) = _CannotAddSelf;

  /// Friend request not found or already processed
  const factory FriendshipFailure.requestNotFound([String? message]) = _RequestNotFound;

  /// Friendship not found or not active
  const factory FriendshipFailure.friendshipNotFound([String? message]) = _FriendshipNotFound;

  /// User is not authorized to perform this action
  const factory FriendshipFailure.unauthorized([String? message]) = _Unauthorized;

  /// Local cache error
  const factory FriendshipFailure.cacheError([String? message]) = _CacheError;

  /// Unknown or unexpected error
  const factory FriendshipFailure.unexpected([String? message]) = _Unexpected;
}
