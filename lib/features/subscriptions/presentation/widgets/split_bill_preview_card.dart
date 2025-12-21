// lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';

/// Card displaying split bill preview with breakdown
///
/// Shows the total amount, member count, split calculation with purple gradient card,
/// and individual breakdown for each member. Uses breakdown from provider which ensures
/// proper rounding where the owner receives any remainder from decimal calculations.
class SplitBillPreviewCard extends StatelessWidget {
  const SplitBillPreviewCard({
    required this.totalAmount,
    required this.totalMembers,
    required this.splitAmount,
    required this.breakdown,
    super.key,
  });

  final double totalAmount;
  final int totalMembers;
  final double splitAmount;
  final List<MemberSplit> breakdown;

  @override
  Widget build(BuildContext context) {
    if (totalAmount == 0 || breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Split Bill Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Summary - Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary - Total Members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Members',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Text(
                '$totalMembers people',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Each Person Pays Card (Purple Gradient)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4FBB), Color(0xFF4834DF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Approx. Per Person',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${splitAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Section
          Text(
            'Breakdown',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // Breakdown list from provider
          ...breakdown.map(
            (memberSplit) => _BreakdownRow(
              name: memberSplit.name,
              amount: memberSplit.amount,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual row in the breakdown section showing member name and amount
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.name,
    required this.amount,
  });

  final String name;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
