import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_section_header.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ActiveSubscriptionsSection extends StatelessWidget {
  const ActiveSubscriptionsSection({
    required this.subscriptions,
    super.key,
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
          AppSectionHeader(
            title: 'Active Subscriptions',
            count: subscriptions.length,
            trailing: TextButton.icon(
              onPressed: () => debugPrint('Show sort options'),
              icon: const Icon(Icons.sort, size: 16),
              label: const Text('Sort'),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.92,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/subscription/${subscription.id}'),
      child: AppSectionCard(
        tone: subscription.isOverdue
            ? AppSectionCardTone.critical
            : AppSectionCardTone.base,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.subscriptions_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subscription.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '\$${subscription.totalCost.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDueDate(subscription.dueDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              subscription.billingCycle.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
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

class _EmptySubscriptionsView extends StatelessWidget {
  const _EmptySubscriptionsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: AppSectionCard(
        tone: AppSectionCardTone.raised,
        child: Column(
          children: [
            const Icon(Icons.subscriptions_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'No Active Subscriptions',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start managing your subscriptions by adding your first one',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => debugPrint('Navigate to add subscription'),
              icon: const Icon(Icons.add),
              label: const Text('Add Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveSubscriptionsLoading extends StatelessWidget {
  const ActiveSubscriptionsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.92,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const AppSectionCard(
                tone: AppSectionCardTone.raised,
                child: SizedBox(
                  height: 126,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
