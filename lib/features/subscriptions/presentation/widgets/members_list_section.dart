import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';

class MembersListSection extends StatelessWidget {
  const MembersListSection({
    required this.members,
    required this.onManageContacts,
    required this.onMemberRemoved,
    super.key,
  });

  final List<SubscriptionMemberInput> members;
  final VoidCallback onManageContacts;
  final ValueChanged<String> onMemberRemoved;

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
                key: const Key('manage-contacts-button'),
                onPressed: onManageContacts,
                icon: const Icon(Icons.people_alt_outlined, size: 18),
                label: const Text('Manage'),
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
          if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No members selected yet',
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
      key: Key('selected-member-${member.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                  member.email ?? 'No email',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.close,
              color: Colors.redAccent,
              size: 20,
            ),
            tooltip: 'Remove member',
          ),
        ],
      ),
    );
  }
}
