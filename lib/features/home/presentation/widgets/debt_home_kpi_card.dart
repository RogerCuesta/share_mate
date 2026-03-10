import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';

class DebtHomeKpiCard extends StatelessWidget {
  const DebtHomeKpiCard({
    required this.snapshot,
    super.key,
  });

  final DebtHomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hasDebt = snapshot.hasDebt;
    final accentColor = hasDebt
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF26A69A);

    return Container(
      key: const Key('debt-home-kpi-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deuda total a favor',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currency(snapshot.totalPendingDebt),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasDebt ? 'Pendiente del ciclo actual' : 'Todo al dia',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currency(double value) => '\$${value.toStringAsFixed(2)}';
}
