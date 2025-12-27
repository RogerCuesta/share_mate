// lib/features/friends/presentation/providers/friend_search_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/friends/domain/entities/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_search_provider.g.dart';

/// Provider for searching users by email
///
/// This is a family provider that takes an email as parameter.
/// Returns a list of matching profiles (exact email match).
///
/// **Privacy-first**: Only returns discoverable users.
/// **Caching**: Results are cached in local storage for performance.
/// Auto-disposes when not in use.
@riverpod
Future<List<Profile>> friendSearch(
  FriendSearchRef ref,
  String email,
) async {
  // Don't search for empty queries
  if (email.trim().isEmpty) {
    return [];
  }

  print('🔍 [FriendSearch] Searching for: $email');

  final searchUsers = ref.watch(searchUsersProvider);
  final result = await searchUsers(email: email);

  return result.fold(
    (failure) {
      print('❌ [FriendSearch] Search failed: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (profiles) {
      print('✅ [FriendSearch] Found ${profiles.length} users');
      return profiles;
    },
  );
}
