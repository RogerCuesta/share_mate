// lib/features/friends/presentation/providers/friends_list_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/friends/domain/entities/friend.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friends_list_provider.g.dart';

/// Provider for fetching the friends list
///
/// Retrieves all accepted friendships for the current user.
/// Returns a list of [Friend] entities with denormalized profile data.
///
/// **Offline-first**: Tries remote first, falls back to cache on network error.
/// Auto-disposes when not in use.
@riverpod
Future<List<Friend>> friendsList(FriendsListRef ref) async {
  print('📋 [FriendsList] Fetching friends list...');

  final getFriends = ref.watch(getFriendsProvider);
  final result = await getFriends();

  return result.fold(
    (failure) {
      print('❌ [FriendsList] Failed to fetch: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (friends) {
      print('✅ [FriendsList] Retrieved ${friends.length} friends');
      return friends;
    },
  );
}
