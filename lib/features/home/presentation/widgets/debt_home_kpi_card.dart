import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_status_badge.dart';
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
    return AppSectionCard(
      key: const Key('debt-home-kpi-card'),
      tone: hasDebt ? AppSectionCardTone.accent : AppSectionCardTone.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deuda total a favor',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _currency(snapshot.totalPendingDebt),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          AppStatusBadge(
            label: hasDebt ? 'Pendiente del ciclo actual' : 'Todo al dia',
            tone: hasDebt ? AppStatusTone.warning : AppStatusTone.synced,
          ),
        ],
      ),
    );
  }

  String _currency(double value) => '\$${value.toStringAsFixed(2)}';
}
