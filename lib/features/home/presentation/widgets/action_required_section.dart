import 'package:flutter/material.dart';

import '../../../subscriptions/domain/entities/subscription_member.dart';

/// Action Required section for home screen
///
/// Displays pending payments that need attention.
/// Shows maximum 2 items with a "View all" button for more.
///
/// Features:
/// - Animated entrance for each tile
/// - User avatar with fallback to initials
/// - Days overdue indicator
/// - Remind button for each payment
class ActionRequiredSection extends StatelessWidget {
  final List<SubscriptionMember> pendingPayments;

  const ActionRequiredSection({
    super.key,
    required this.pendingPayments,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingPayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _SectionHeader(
            itemCount: pendingPayments.length,
            onViewAll: () {
              // TODO: Navigate to all pending payments
              debugPrint('Navigate to all pending payments');
            },
          ),
          const SizedBox(height: 16),

          // Pending payment tiles
          ...List.generate(
            pendingPayments.length,
            (index) => _AnimatedPendingPaymentTile(
              member: pendingPayments[index],
              index: index,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final int itemCount;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.itemCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title
        const Text(
          'Action Required',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),

        // View all button
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C63FF).withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: const Color(0xFF6C63FF).withOpacity(0.9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED PENDING PAYMENT TILE
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedPendingPaymentTile extends StatefulWidget {
  final SubscriptionMember member;
  final int index;

  const _AnimatedPendingPaymentTile({
    required this.member,
    required this.index,
  });

  @override
  State<_AnimatedPendingPaymentTile> createState() =>
      _AnimatedPendingPaymentTileState();
}

class _AnimatedPendingPaymentTileState
    extends State<_AnimatedPendingPaymentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Delay based on index for staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _PendingPaymentTile(member: widget.member),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PENDING PAYMENT TILE
// ═══════════════════════════════════════════════════════════════════════════

class _PendingPaymentTile extends StatelessWidget {
  final SubscriptionMember member;

  const _PendingPaymentTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isOverdue = member.isOverdue;
    final daysOverdue = member.daysOverdue ?? 0;
    final statusColor = isOverdue ? const Color(0xFFFF6B6B) : const Color(0xFFFFB84D);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          _UserAvatar(member: member, statusColor: statusColor),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: _UserInfo(
              member: member,
              daysOverdue: daysOverdue,
            ),
          ),

          // Payment Info and Action
          _PaymentAction(
            member: member,
            statusColor: statusColor,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER AVATAR
// ═══════════════════════════════════════════════════════════════════════════

class _UserAvatar extends StatelessWidget {
  final SubscriptionMember member;
  final Color statusColor;

  const _UserAvatar({
    required this.member,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withOpacity(0.2),
            backgroundImage: member.userAvatar != null
                ? NetworkImage(member.userAvatar!)
                : null,
            child: member.userAvatar == null
                ? Text(
                    member.userName[0].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
        ),

        // Overdue indicator badge
        if (member.isOverdue)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2A2A3E),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.priority_high,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER INFO
// ═══════════════════════════════════════════════════════════════════════════

class _UserInfo extends StatelessWidget {
  final SubscriptionMember member;
  final int daysOverdue;

  const _UserInfo({
    required this.member,
    required this.daysOverdue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User name
        Text(
          member.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Subscription and overdue info
        Row(
          children: [
            // Subscription indicator (TODO: Get actual subscription name)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Subscription',
                style: TextStyle(
                  color: const Color(0xFF6C63FF).withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Days overdue
            Text(
              daysOverdue > 0
                  ? '$daysOverdue ${daysOverdue == 1 ? 'day' : 'days'} ago'
                  : 'Due soon',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT ACTION
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentAction extends StatelessWidget {
  final SubscriptionMember member;
  final Color statusColor;

  const _PaymentAction({
    required this.member,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Amount
        Text(
          '-\$${member.amountToPay.toStringAsFixed(2)}',
          style: TextStyle(
            color: statusColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),

        // Remind button
        OutlinedButton(
          onPressed: () {
            // TODO: Send reminder to member
            debugPrint('Send reminder to ${member.userName}');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: statusColor,
            side: BorderSide(color: statusColor.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Remind',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

class ActionRequiredLoading extends StatelessWidget {
  const ActionRequiredLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Action Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading skeleton
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
