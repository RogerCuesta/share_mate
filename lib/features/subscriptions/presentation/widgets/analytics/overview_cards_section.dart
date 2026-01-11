// lib/features/subscriptions/presentation/widgets/analytics/overview_cards_section.dart

import 'package:flutter/material.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_overview.dart';

/// Overview Cards Section
///
/// Displays 4 key metrics in a 2x2 grid:
/// - Total Monthly Cost (purple gradient)
/// - Active Subscriptions (blue gradient)
/// - Total Members (cyan gradient)
/// - Average Cost per Subscription (red gradient)
class OverviewCardsSection extends StatelessWidget {

  const OverviewCardsSection({
    required this.overview, super.key,
  });
  final AnalyticsOverview overview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _OverviewCard(
                title: 'Monthly Cost',
                value: '\$${overview.totalMonthlyCost.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF8B7FFF),
                  ],
                ),
              ),
              _OverviewCard(
                title: 'Active Subscriptions',
                value: overview.totalActiveSubscriptions.toString(),
                icon: Icons.subscriptions,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF5FA8FF),
                  ],
                ),
              ),
              _OverviewCard(
                title: 'Total Members',
                value: overview.totalMembers.toString(),
                icon: Icons.people,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00D4FF),
                    Color(0xFF4ECDC4),
                  ],
                ),
              ),
              _OverviewCard(
                title: 'Avg per Sub',
                value: '\$${overview.averageCostPerSubscription.toStringAsFixed(2)}',
                icon: Icons.trending_up,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFF8E8E),
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

/// Individual Overview Card with gradient background
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
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),

            // Title and Value
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
