// lib/features/friends/presentation/providers/friend_request_actions_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/friends/domain/failures/friendship_failure.dart';
import 'package:flutter_project_agents/features/friends/presentation/providers/friends_list_provider.dart';
import 'package:flutter_project_agents/features/friends/presentation/providers/pending_requests_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_request_actions_provider.g.dart';

/// Provider for friend request actions (send, accept, reject, remove)
///
/// This is a class-based provider that holds state for loading/error states
/// and provides methods to perform friendship operations.
@riverpod
class FriendRequestActions extends _$FriendRequestActions {
  @override
  FutureOr<void> build() {
    // Initial state is AsyncData(null)
    return null;
  }

  /// Send a friend request by email
  Future<void> sendFriendRequest(String email) async {
    state = const AsyncLoading();
    print('📤 [FriendActions] Sending friend request to: $email');

    final sendRequest = ref.read(sendFriendRequestProvider);
    final result = await sendRequest(friendEmail: email);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (failure) {
          print('❌ [FriendActions] Send failed: ${_getErrorMessage(failure)}');
          throw failure;
        },
        (friendshipId) {
          print('✅ [FriendActions] Request sent successfully: $friendshipId');
          // Invalidate lists to refresh
          ref.invalidate(friendsListProvider);
          ref.invalidate(pendingRequestsProvider);
          return null;
        },
      );
    });
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    state = const AsyncLoading();
    print('✅ [FriendActions] Accepting friend request: $friendshipId');

    final acceptRequest = ref.read(acceptFriendRequestProvider);
    final result = await acceptRequest(friendshipId: friendshipId);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (failure) {
          print('❌ [FriendActions] Accept failed: ${_getErrorMessage(failure)}');
          throw failure;
        },
        (_) {
          print('✅ [FriendActions] Request accepted successfully');
          // Invalidate lists to refresh
          ref.invalidate(friendsListProvider);
          ref.invalidate(pendingRequestsProvider);
          return null;
        },
      );
    });
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest(String friendshipId) async {
    state = const AsyncLoading();
    print('❌ [FriendActions] Rejecting friend request: $friendshipId');

    final rejectRequest = ref.read(rejectFriendRequestProvider);
    final result = await rejectRequest(friendshipId: friendshipId);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (failure) {
          print('❌ [FriendActions] Reject failed: ${_getErrorMessage(failure)}');
          throw failure;
        },
        (_) {
          print('✅ [FriendActions] Request rejected successfully');
          // Invalidate pending requests to refresh
          ref.invalidate(pendingRequestsProvider);
          return null;
        },
      );
    });
  }

  /// Remove an existing friend
  Future<void> removeFriend(String friendshipId) async {
    state = const AsyncLoading();
    print('🗑️ [FriendActions] Removing friend: $friendshipId');

    final remove = ref.read(removeFriendProvider);
    final result = await remove(friendshipId: friendshipId);

    state = await AsyncValue.guard(() async {
      return result.fold(
        (failure) {
          print('❌ [FriendActions] Remove failed: ${_getErrorMessage(failure)}');
          throw failure;
        },
        (_) {
          print('✅ [FriendActions] Friend removed successfully');
          // Invalidate friends list to refresh
          ref.invalidate(friendsListProvider);
          return null;
        },
      );
    });
  }

  /// Get user-friendly error message from failure
  String _getErrorMessage(FriendshipFailure failure) {
    return failure.when(
      serverError: (msg) => msg ?? 'Server error occurred',
      networkError: (msg) => msg ?? 'Network error occurred',
      userNotFound: (msg) => msg ?? 'User not found or not discoverable',
      alreadyFriends: (msg) => msg ?? 'Already friends or request pending',
      cannotAddSelf: (msg) => msg ?? 'Cannot add yourself as friend',
      requestNotFound: (msg) => msg ?? 'Friend request not found',
      friendshipNotFound: (msg) => msg ?? 'Friendship not found',
      unauthorized: (msg) => msg ?? 'Unauthorized action',
      cacheError: (msg) => msg ?? 'Cache error occurred',
      unexpected: (msg) => msg ?? 'Unexpected error occurred',
    );
  }
}
