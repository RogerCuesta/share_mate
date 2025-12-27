// lib/features/friends/presentation/widgets/friend_request_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/friends/domain/entities/friend.dart';
import 'package:flutter_project_agents/features/friends/presentation/providers/friend_request_actions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget for displaying a pending friend request
class FriendRequestCard extends ConsumerWidget {
  const FriendRequestCard({
    required this.request,
    super.key,
  });

  final Friend request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF6B4FBB).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6B4FBB).withOpacity(0.2),
                  child: request.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            request.avatarUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Color(0xFF6B4FBB),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF6B4FBB),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.email,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      side: BorderSide(color: Colors.grey[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAccept(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4FBB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(friendRequestActionsProvider.notifier);
    await actions.acceptFriendRequest(request.friendshipId);

    if (!context.mounted) return;

    final state = ref.read(friendRequestActionsProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.fullName} is now your friend!'),
            backgroundColor: const Color(0xFF44C854),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(friendRequestActionsProvider.notifier);
    await actions.rejectFriendRequest(request.friendshipId);

    if (!context.mounted) return;

    final state = ref.read(friendRequestActionsProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined'),
            backgroundColor: Color(0xFF44C854),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
