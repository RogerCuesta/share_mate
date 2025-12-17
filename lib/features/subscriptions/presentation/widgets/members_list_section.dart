// lib/features/subscriptions/presentation/widgets/members_list_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/add_member_dialog.dart';

/// Section displaying the list of members with add/remove functionality
///
/// Displays a header with "Members" title and "Add" button, followed by
/// a list of member cards showing avatar, name, email, and delete button.
class MembersListSection extends StatelessWidget {
  const MembersListSection({
    required this.members,
    required this.onMemberAdded,
    required this.onMemberRemoved,
    super.key,
  });

  final List<SubscriptionMemberInput> members;
  final ValueChanged<SubscriptionMemberInput> onMemberAdded;
  final ValueChanged<String> onMemberRemoved;

  Future<void> _showAddMemberDialog(BuildContext context) async {
    final member = await showDialog<SubscriptionMemberInput>(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );

    if (member != null) {
      onMemberAdded(member);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMemberDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4FBB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Members list or empty state
          if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No members added yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ...members.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MemberTile(
                  member: member,
                  onDelete: () => onMemberRemoved(member.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Individual member tile displaying avatar, name, email, and delete button
class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.onDelete,
  });

  final SubscriptionMemberInput member;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar placeholder with "img" text
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[700],
            child: const Text(
              'img',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
