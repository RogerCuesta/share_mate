import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_status_badge.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:intl/intl.dart';

class SubscriptionDetailSummaryHero extends StatelessWidget {
  const SubscriptionDetailSummaryHero({
    required this.subscription,
    super.key,
  });

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final dueStatus = _dueStatus(subscription.dueDate);

    return Container(
      padding: EdgeInsets.all(tokens.spacingLarge),
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: BorderRadius.circular(tokens.borderRadiusXLarge),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(tokens.borderRadiusLarge),
                ),
                child: const Icon(
                  Icons.subscriptions,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: tokens.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: tokens.spacingXSmall),
                    Text(
                      'Next due: ${DateFormat('MMM dd, yyyy').format(subscription.dueDate)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Total cost',
                  value: '\$${subscription.totalCost.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: tokens.spacingSmall),
              Expanded(
                child: _Metric(
                  label: 'Billing cycle',
                  value: subscription.billingCycle.displayName,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingMedium),
          Wrap(
            spacing: tokens.spacingSmall,
            runSpacing: tokens.spacingSmall,
            children: [
              AppStatusBadge(
                label: subscription.status.displayName,
                tone: _subscriptionTone(subscription.status),
              ),
              AppStatusBadge(
                label: dueStatus.label,
                tone: dueStatus.tone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({String label, AppStatusTone tone}) _dueStatus(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final delta = due.difference(today).inDays;

    if (delta < 0) {
      final overdueDays = delta.abs();
      return (
        label: overdueDays == 1
            ? 'Overdue by 1 day'
            : 'Overdue by $overdueDays days',
        tone: AppStatusTone.error,
      );
    }
    if (delta == 0) {
      return (label: 'Due today', tone: AppStatusTone.warning);
    }
    if (delta == 1) {
      return (label: 'Due in 1 day', tone: AppStatusTone.warning);
    }
    return (label: 'Due in $delta days', tone: AppStatusTone.info);
  }

  AppStatusTone _subscriptionTone(SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.active => AppStatusTone.synced,
      SubscriptionStatus.paused => AppStatusTone.warning,
      SubscriptionStatus.cancelled => AppStatusTone.error,
    };
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
