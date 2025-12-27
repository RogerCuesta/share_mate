// lib/features/friends/presentation/providers/pending_requests_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/friends/domain/entities/friend.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_requests_provider.g.dart';

/// Provider for fetching pending friend requests
///
/// Retrieves all pending friend requests received by the current user.
/// Returns a list of [Friend] entities representing users who sent requests.
///
/// **Excludes**: Requests initiated by the current user (sent requests).
/// **Offline-first**: Tries remote first, falls back to cache on network error.
/// Auto-disposes when not in use.
@riverpod
Future<List<Friend>> pendingRequests(PendingRequestsRef ref) async {
  print('📨 [PendingRequests] Fetching pending requests...');

  final getPendingRequests = ref.watch(getPendingRequestsProvider);
  final result = await getPendingRequests();

  return result.fold(
    (failure) {
      print('❌ [PendingRequests] Failed to fetch: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (requests) {
      print('✅ [PendingRequests] Retrieved ${requests.length} pending requests');
      return requests;
    },
  );
}
