import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';

class StatsCards extends StatelessWidget {
  const StatsCards({required this.stats, super.key});

  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('secondary-stats-cards'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Monthly Cost',
              amount: stats.totalMonthlyCost,
              icon: Icons.trending_up,
              tone: AppSectionCardTone.raised,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Pending to Collect',
              amount: stats.pendingToCollect,
              icon: Icons.info_outline,
              tone: AppSectionCardTone.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.tone,
  });

  final String title;
  final double amount;
  final IconData icon;
  final AppSectionCardTone tone;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      tone: tone,
      child: SizedBox(
        height: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsCardsLoading extends StatelessWidget {
  const StatsCardsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _LoadingCard()),
          SizedBox(width: 16),
          Expanded(child: _LoadingCard()),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppSectionCard(
      tone: AppSectionCardTone.raised,
      child: SizedBox(
        height: 108,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class StatsCardsError extends StatelessWidget {
  const StatsCardsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppSectionCard(
        tone: AppSectionCardTone.critical,
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
