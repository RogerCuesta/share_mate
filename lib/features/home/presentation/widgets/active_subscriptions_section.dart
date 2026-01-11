import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Active Subscriptions section for home screen
///
/// Displays active subscriptions in a colorful grid layout.
/// Each card features:
/// - Custom gradient based on subscription color
/// - Glassmorphism effect
/// - Service logo/icon
/// - Price and due date
/// - Shadow with subscription color
class ActiveSubscriptionsSection extends StatelessWidget {

  const ActiveSubscriptionsSection({
    required this.subscriptions, super.key,
  });
  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return const _EmptySubscriptionsView();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _SectionHeader(
            subscriptionCount: subscriptions.length,
            onSort: () {
              // TODO: Implement sort options
              debugPrint('Show sort options');
            },
          ),
          const SizedBox(height: 16),

          // Subscriptions Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              return _SubscriptionCard(subscription: subscriptions[index]);
            },
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

  const _SectionHeader({
    required this.subscriptionCount,
    required this.onSort,
  });
  final int subscriptionCount;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title with count
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Active Subscriptions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: ' ($subscriptionCount)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Sort button
        TextButton.icon(
          onPressed: onSort,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          icon: const Icon(Icons.sort, size: 16),
          label: const Text(
            'Sort',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION CARD
// ═══════════════════════════════════════════════════════════════════════════

class _SubscriptionCard extends StatelessWidget {

  const _SubscriptionCard({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(subscription.color);
    final isDueSoon = subscription.isDueSoon;
    final isOverdue = subscription.isOverdue;

    return GestureDetector(
      onTap: () {
        debugPrint('🔍 Opening subscription details: ${subscription.id}');
        context.push('/subscription/${subscription.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and members indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SubscriptionLogo(
                          iconUrl: subscription.iconUrl,
                        ),
                        _MembersIndicator(
                          memberCount: subscription.totalMembers,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Price
                    Text(
                      '\$${subscription.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Due date
                    Row(
                      children: [
                        Icon(
                          _getDueDateIcon(isDueSoon, isOverdue),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(subscription.dueDate),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Service name
                    Text(
                      subscription.name,
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

                    // Billing cycle badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subscription.billingCycle.name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6C63FF); // Default purple
    }
  }

  IconData _getDueDateIcon(bool isDueSoon, bool isOverdue) {
    if (isOverdue) return Icons.error_outline;
    if (isDueSoon) return Icons.warning_amber_rounded;
    return Icons.calendar_today_outlined;
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    if (diff < 0) {
      final absDiff = diff.abs();
      return 'Overdue $absDiff ${absDiff == 1 ? 'day' : 'days'}';
    }
    if (diff <= 7) return 'Due in $diff ${diff == 1 ? 'day' : 'days'}';

    return 'Due ${DateFormat('MMM d').format(date)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION LOGO
// ═══════════════════════════════════════════════════════════════════════════

class _SubscriptionLogo extends StatelessWidget {

  const _SubscriptionLogo({this.iconUrl});
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: iconUrl != null
            ? Image.network(
                iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _DefaultIcon(),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white.withValues(alpha: 0.5),
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : _DefaultIcon(),
      ),
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.subscriptions_outlined,
      color: Colors.white.withValues(alpha: 0.7),
      size: 28,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MEMBERS INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

class _MembersIndicator extends StatelessWidget {

  const _MembersIndicator({required this.memberCount});
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.white.withValues(alpha: 0.9),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            memberCount.toString(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptySubscriptionsView extends StatelessWidget {
  const _EmptySubscriptionsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          // Empty icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A3E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.subscriptions_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            'No Active Subscriptions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Start managing your subscriptions by adding your first one',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Add button
          FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to add subscription
              debugPrint('Navigate to add subscription');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Subscription'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

class ActiveSubscriptionsLoading extends StatelessWidget {
  const ActiveSubscriptionsLoading({super.key});

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
                'Active Subscriptions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const _LoadingCard();
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
