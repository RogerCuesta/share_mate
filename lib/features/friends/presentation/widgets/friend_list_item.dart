// lib/features/friends/presentation/widgets/friend_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/friends/domain/entities/friend.dart';
import 'package:flutter_project_agents/features/friends/presentation/providers/friend_request_actions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget for displaying a friend in the list
class FriendListItem extends ConsumerWidget {
  const FriendListItem({
    required this.friend,
    super.key,
  });

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF6B4FBB).withOpacity(0.2),
          child: friend.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    friend.avatarUrl!,
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
        title: Text(
          friend.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              friend.email,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Friends since ${_formatDate(friend.friendsSince)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          color: const Color(0xFF2A2A3E),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, color: Colors.red[300], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Remove Friend',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'remove') {
              _showRemoveConfirmation(context, ref);
            }
          },
        ),
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Remove Friend',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${friend.fullName} from your friends?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final actions = ref.read(friendRequestActionsProvider.notifier);
              await actions.removeFriend(friend.friendshipId);

              if (!context.mounted) return;

              final state = ref.read(friendRequestActionsProvider);
              state.when(
                data: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend removed'),
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
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red[300]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
