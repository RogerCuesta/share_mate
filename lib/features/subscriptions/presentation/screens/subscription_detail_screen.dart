// lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Screen displaying detailed information about a subscription
///
/// Shows:
/// - Subscription header with icon and status
/// - Cost information (price, billing cycle, due date)
/// - Members list (if group subscription)
/// - Split information (if group subscription)
/// - Action buttons (edit, delete, mark as paid)
class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({
    required this.subscriptionId,
    super.key,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch subscription details by ID
    // For now, using placeholder data
    final subscription = _getPlaceholderSubscription();
    final members = _getPlaceholderMembers();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      appBar: _buildAppBar(context, subscription),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(subscription: subscription),
            const SizedBox(height: 16),
            _CostInformationCard(subscription: subscription),
            const SizedBox(height: 16),
            if (members.isNotEmpty) ...[
              _MembersSection(members: members),
              const SizedBox(height: 16),
              _SplitInformationCard(
                subscription: subscription,
                members: members,
              ),
              const SizedBox(height: 24),
            ],
            _ActionButtons(
              subscriptionId: subscriptionId,
              hasPendingPayments: members.any((m) => !m.hasPaid),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Subscription subscription,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Subscription Details',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to edit screen
            print('📝 Edit subscription: $subscriptionId');
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Subscription?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete the subscription and all associated data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete subscription
              Navigator.pop(context);
              context.pop();
              print('🗑️ Delete subscription: $subscriptionId');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Placeholder data - will be replaced with actual provider data
  Subscription _getPlaceholderSubscription() {
    return Subscription(
      id: subscriptionId,
      name: 'Netflix Premium',
      color: '#E50914',
      totalCost: 15.99,
      billingCycle: BillingCycle.monthly,
      dueDate: DateTime.now().add(const Duration(days: 15)),
      ownerId: 'current-user-id',
      sharedWith: ['user-2', 'user-3'],
      status: SubscriptionStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );
  }

  List<SubscriptionMember> _getPlaceholderMembers() {
    return [
      SubscriptionMember(
        id: 'member-1',
        subscriptionId: subscriptionId,
        userId: 'user-2',
        userName: 'John Doe',
        userEmail: 'john@example.com',
        amountToPay: 7.99,
        hasPaid: true,
        lastPaymentDate: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      SubscriptionMember(
        id: 'member-2',
        subscriptionId: subscriptionId,
        userId: 'user-3',
        userName: 'Jane Smith',
        userEmail: 'jane@example.com',
        amountToPay: 8.00,
        hasPaid: false,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];
  }
}

/// Header card with subscription icon, name, and status badge
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4FBB), Color(0xFF4834DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.subscriptions,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            subscription.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Status Badge
          _StatusBadge(status: subscription.status),
        ],
      ),
    );
  }
}

/// Status badge showing active/paused/cancelled state
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, IconData icon}) _getStatusConfig() {
    return switch (status) {
      SubscriptionStatus.active => (
          color: Colors.green,
          icon: Icons.check_circle,
        ),
      SubscriptionStatus.paused => (
          color: Colors.orange,
          icon: Icons.pause_circle,
        ),
      SubscriptionStatus.cancelled => (
          color: Colors.red,
          icon: Icons.cancel,
        ),
    };
  }
}

/// Card displaying cost, billing cycle, due date, and owner information
class _CostInformationCard extends StatelessWidget {
  const _CostInformationCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final daysUntilDue =
        subscription.dueDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Total Cost
          _InfoRow(
            label: 'Total Cost',
            value: '\$${subscription.totalCost.toStringAsFixed(2)}',
            valueStyle: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Billing Cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing Cycle',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subscription.billingCycle.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next Due Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Due Date',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(subscription.dueDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'in $daysUntilDue days',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Owner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Owner',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4FBB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6B4FBB),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF6B4FBB),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'You',
                      style: TextStyle(
                        color: Color(0xFF6B4FBB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Members section showing all members with payment status
class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.members});

  final List<SubscriptionMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${members.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member tiles
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MemberTile(member: member),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual member tile showing avatar, info, amount, and payment status
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final SubscriptionMember member;

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
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[700],
            child: Text(
              member.userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  member.userEmail,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${member.amountToPay.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _PaymentStatusBadge(isPaid: member.hasPaid),
            ],
          ),
        ],
      ),
    );
  }
}

/// Payment status badge (Paid/Pending)
class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.schedule,
            size: 12,
            color: isPaid ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'Paid' : 'Pending',
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Split information card showing totals and collection status
class _SplitInformationCard extends StatelessWidget {
  const _SplitInformationCard({
    required this.subscription,
    required this.members,
  });

  final Subscription subscription;
  final List<SubscriptionMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final collectedSoFar = members
        .where((m) => m.hasPaid)
        .fold(0.0, (sum, m) => sum + m.amountToPay);

    final remainingToCollect = members
        .where((m) => !m.hasPaid)
        .fold(0.0, (sum, m) => sum + m.amountToPay);

    final yourShare = subscription.totalCost - members.fold<double>(
      0.0,
      (sum, m) => sum + m.amountToPay,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Split Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Total Members',
            value: '${subscription.totalMembers} people',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Your Share',
            value: '\$${yourShare.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Collected So Far',
            value: '\$${collectedSoFar.toStringAsFixed(2)}',
            valueColor: Colors.green,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Remaining to Collect',
            value: '\$${remainingToCollect.toStringAsFixed(2)}',
            valueColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}

/// Reusable info row widget
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Action buttons section (mark as paid, edit, delete)
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.subscriptionId,
    required this.hasPendingPayments,
  });

  final String subscriptionId;
  final bool hasPendingPayments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mark All as Paid (only if pending)
        if (hasPendingPayments)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Mark all as paid
                print('✅ Mark all as paid');
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark All as Paid'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B4FBB),
                side: const BorderSide(color: Color(0xFF6B4FBB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (hasPendingPayments) const SizedBox(height: 12),

        // Edit Subscription
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit
              print('📝 Edit subscription: $subscriptionId');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Subscription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4FBB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete Subscription
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Subscription'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Subscription?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete the subscription and all associated data. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete subscription
              Navigator.pop(context);
              context.pop();
              print('🗑️ Deleted subscription: $subscriptionId');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
