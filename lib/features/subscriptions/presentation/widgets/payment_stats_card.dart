import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_section_header.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card displaying payment statistics for a subscription.
class PaymentStatsCard extends ConsumerWidget {
  const PaymentStatsCard({
    required this.subscriptionId,
    super.key,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(paymentStatsProvider(subscriptionId));
    final tokens = Theme.of(context).appTokens;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Payment Analytics',
            subtitle: 'Collection coverage and split health',
          ),
          SizedBox(height: tokens.spacingMedium),
          statsAsync.when(
            data: (stats) => _buildStatsContent(context, stats),
            loading: () => SizedBox(
              height: 88,
              child: Center(
                child: CircularProgressIndicator(
                  color: tokens.ctaPrimary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: tokens.statusError),
                  SizedBox(width: tokens.spacingSmall),
                  Expanded(
                    child: Text(
                      'Failed to load stats',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.statusError,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, PaymentStats stats) {
    final tokens = Theme.of(context).appTokens;
    final currencyFormat = NumberFormat.currency(symbol: r'$');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.payment,
                label: 'Total Payments',
                value: '${stats.totalPayments}',
                color: tokens.ctaPrimary,
              ),
            ),
            SizedBox(width: tokens.spacingSmall),
            Expanded(
              child: _StatItem(
                icon: Icons.people_outline,
                label: 'Unique Payers',
                value: '${stats.uniquePayers}',
                color: tokens.statusInfo,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.attach_money,
                label: 'Amount Paid',
                value: currencyFormat.format(stats.totalAmountPaid),
                color: tokens.statusSuccess,
              ),
            ),
            SizedBox(width: tokens.spacingSmall),
            Expanded(
              child: _StatItem(
                icon: Icons.money_off,
                label: 'Amount Unpaid',
                value: currencyFormat.format(stats.totalAmountUnpaid),
                color: tokens.statusError,
              ),
            ),
          ],
        ),
        if (stats.paymentMethods.isNotEmpty) ...[
          SizedBox(height: tokens.spacingMedium),
          Divider(color: tokens.borderSubtle),
          SizedBox(height: tokens.spacingSmall),
          _PaymentMethodsSection(paymentMethods: stats.paymentMethods),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceAccent,
        borderRadius: BorderRadius.circular(tokens.borderRadiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: tokens.spacingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: tokens.spacingXSmall),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tokens.textMuted,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsSection extends StatelessWidget {
  const _PaymentMethodsSection({required this.paymentMethods});

  final Map<String, int> paymentMethods;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        SizedBox(height: tokens.spacingSmall),
        Wrap(
          spacing: tokens.spacingSmall,
          runSpacing: tokens.spacingSmall,
          children: paymentMethods.entries.map((entry) {
            return _PaymentMethodChip(
              method: entry.key,
              count: entry.value,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.method,
    required this.count,
  });

  final String method;
  final int count;

  String _displayName(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Transfer';
      case 'card':
        return 'Card';
      default:
        return value;
    }
  }

  IconData _icon(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'transfer':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.ctaPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.ctaPrimary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(method), color: tokens.ctaPrimary, size: 14),
          const SizedBox(width: 6),
          Text(
            _displayName(method),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tokens.ctaPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.ctaPrimary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.textOnAccent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
