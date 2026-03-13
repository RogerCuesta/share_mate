import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_section_header.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';

class ActionRequiredSection extends StatelessWidget {
  const ActionRequiredSection({
    required this.pendingPayments,
    super.key,
  });

  final List<SubscriptionMember> pendingPayments;

  @override
  Widget build(BuildContext context) {
    if (pendingPayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      key: const Key('action-required-section'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Action Required',
            count: pendingPayments.length,
            trailing: TextButton(
              onPressed: () => debugPrint('Navigate to all pending payments'),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 16),
          ...pendingPayments.map(_PendingPaymentTile.new),
        ],
      ),
    );
  }
}

class _PendingPaymentTile extends StatelessWidget {
  const _PendingPaymentTile(this.member);
  final SubscriptionMember member;

  @override
  Widget build(BuildContext context) {
    final isOverdue = member.isOverdue;
    final daysOverdue = member.daysOverdue ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSectionCard(
        tone: isOverdue ? AppSectionCardTone.critical : AppSectionCardTone.base,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(member.userName[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.userName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysOverdue > 0
                        ? '$daysOverdue ${daysOverdue == 1 ? 'day' : 'days'} ago'
                        : 'Due soon',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-\$${member.amountToPay.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () =>
                      debugPrint('Send reminder to ${member.userName}'),
                  child: const Text('Remind'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ActionRequiredLoading extends StatelessWidget {
  const ActionRequiredLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: AppSectionCard(
        tone: AppSectionCardTone.raised,
        child: SizedBox(
          height: 76,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
