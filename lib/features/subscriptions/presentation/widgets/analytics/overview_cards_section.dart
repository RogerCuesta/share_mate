import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_overview.dart';

/// Overview cards section for analytics metrics.
class OverviewCardsSection extends StatelessWidget {
  const OverviewCardsSection({
    required this.overview,
    super.key,
  });

  final AnalyticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: tokens.spacingSmall),
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: tokens.spacingMedium),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: tokens.spacingMedium,
            crossAxisSpacing: tokens.spacingMedium,
            childAspectRatio: 1.4,
            children: [
              _OverviewCard(
                title: 'Monthly Cost',
                value: '\$${overview.totalMonthlyCost.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                gradient: tokens.cardGradientPurple,
              ),
              _OverviewCard(
                title: 'Active Subscriptions',
                value: overview.totalActiveSubscriptions.toString(),
                icon: Icons.subscriptions,
                gradient: tokens.cardGradientBlue,
              ),
              _OverviewCard(
                title: 'Total Members',
                value: overview.totalMembers.toString(),
                icon: Icons.people,
                gradient: tokens.cardGradientCyan,
              ),
              _OverviewCard(
                title: 'Avg per Sub',
                value:
                    '\$${overview.averageCostPerSubscription.toStringAsFixed(2)}',
                icon: Icons.trending_up,
                gradient: tokens.cardGradientRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(tokens.borderRadiusLarge),
        boxShadow: tokens.cardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spacingSmall),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(tokens.borderRadiusSmall),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                SizedBox(height: tokens.spacingXSmall),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
