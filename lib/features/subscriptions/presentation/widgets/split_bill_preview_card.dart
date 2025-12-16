// lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';

/// Card displaying split bill preview with breakdown
class SplitBillPreviewCard extends StatelessWidget {
  final double totalAmount;
  final int totalMembers;
  final List<MemberPaymentBreakdown> breakdown;

  const SplitBillPreviewCard({
    super.key,
    required this.totalAmount,
    required this.totalMembers,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    if (totalMembers == 0) {
      return const SizedBox.shrink();
    }

    final splitAmount = totalAmount / totalMembers;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with calculator icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Split Bill Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary cards
          Row(
            children: [
              // Total Amount
              Expanded(
                child: _InfoCard(
                  label: 'Total Amount',
                  value: '\$${totalAmount.toStringAsFixed(2)}',
                  color: Colors.grey[400]!,
                ),
              ),
              const SizedBox(width: 12),

              // Total Members
              Expanded(
                child: _InfoCard(
                  label: 'Total Members',
                  value: '$totalMembers ${totalMembers == 1 ? 'person' : 'people'}',
                  color: Colors.grey[400]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Each Person Pays (highlighted)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Each Person Pays',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${splitAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Breakdown section
          const Text(
            'Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Breakdown list
          ...breakdown.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: member.isOwner
                                ? const Color(0xFF6C63FF)
                                : Colors.grey[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.name,
                          style: TextStyle(
                            color: member.isOwner ? Colors.white : Colors.grey[300],
                            fontSize: 14,
                            fontWeight: member.isOwner
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${member.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: member.isOwner
                            ? const Color(0xFF6C63FF)
                            : Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Small info card for summary
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
