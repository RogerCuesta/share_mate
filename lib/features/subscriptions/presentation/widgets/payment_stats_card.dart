// lib/features/subscriptions/presentation/widgets/payment_stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card displaying payment statistics for a subscription
///
/// Shows:
/// - Total payments count
/// - Total amount paid
/// - Total amount unpaid
/// - Unique payers count
/// - Payment methods breakdown
class PaymentStatsCard extends ConsumerWidget {
  const PaymentStatsCard({
    required this.subscriptionId,
    super.key,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(paymentStatsProvider(subscriptionId));

    return Card(
      color: const Color(0xFF1E1E2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4FBB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFF6B4FBB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            statsAsync.when(
              data: (stats) => _buildStatsContent(stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6B4FBB),
                  ),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load stats',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(PaymentStats stats) {
    final currencyFormat = NumberFormat.currency(symbol: r'$');

    return Column(
      children: [
        // Main stats row
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.payment,
                label: 'Total Payments',
                value: '${stats.totalPayments}',
                color: const Color(0xFF6B4FBB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.people_outline,
                label: 'Unique Payers',
                value: '${stats.uniquePayers}',
                color: const Color(0xFF4ECDC4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Amount stats row
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.attach_money,
                label: 'Amount Paid',
                value: currencyFormat.format(stats.totalAmountPaid),
                color: const Color(0xFF44C854),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.money_off,
                label: 'Amount Unpaid',
                value: currencyFormat.format(stats.totalAmountUnpaid),
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
        if (stats.paymentMethods.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A2A3E)),
          const SizedBox(height: 12),
          _buildPaymentMethodsSection(stats.paymentMethods),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodsSection(Map<String, int> paymentMethods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  String _getMethodDisplayName(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Transfer';
      case 'card':
        return 'Card';
      default:
        return method;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4FBB).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B4FBB).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMethodIcon(method),
            color: const Color(0xFF6B4FBB),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _getMethodDisplayName(method),
            style: const TextStyle(
              color: Color(0xFF6B4FBB),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4FBB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
