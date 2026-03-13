import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_status_badge.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';

class NextCollectionCard extends StatelessWidget {
  const NextCollectionCard({
    required this.snapshot,
    this.now,
    super.key,
  });

  final DebtHomeSnapshot snapshot;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final candidate = snapshot.nextCollection;
    final nowDate = _dateOnly(now ?? DateTime.now());
    final hasCandidate = candidate != null;
    final dueDate = hasCandidate ? _dateOnly(candidate.dueDate) : null;
    final urgency =
        hasCandidate ? _urgencyCopy(dueDate!, nowDate) : 'Todo al dia';
    final tone =
        hasCandidate ? _urgencyTone(dueDate!, nowDate) : AppStatusTone.synced;

    return AppSectionCard(
      key: const Key('next-collection-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proximo cobro', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (hasCandidate) ...[
            Text(
              candidate.subscriptionName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _currency(candidate.pendingAmount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ] else ...[
            Text(
              r'$0.00',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'No hay cobros pendientes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          AppStatusBadge(label: urgency, tone: tone),
        ],
      ),
    );
  }

  String _currency(double value) => '\$${value.toStringAsFixed(2)}';

  DateTime _dateOnly(DateTime input) {
    return DateTime(input.year, input.month, input.day);
  }

  String _urgencyCopy(DateTime dueDate, DateTime today) {
    if (dueDate.isBefore(today)) {
      final days = today.difference(dueDate).inDays;
      return days == 1 ? 'Vencido hace 1 dia' : 'Vencido hace $days dias';
    }

    final remainingDays = dueDate.difference(today).inDays;
    if (remainingDays == 0) {
      return 'Hoy';
    }
    if (remainingDays == 1) {
      return 'En 1 dia';
    }
    return 'En $remainingDays dias';
  }

  AppStatusTone _urgencyTone(DateTime dueDate, DateTime today) {
    if (dueDate.isBefore(today)) {
      return AppStatusTone.error;
    }
    final remainingDays = dueDate.difference(today).inDays;
    if (remainingDays <= 3) {
      return AppStatusTone.warning;
    }
    return AppStatusTone.info;
  }
}
