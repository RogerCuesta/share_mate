import 'package:flutter/material.dart';
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
    final urgency = hasCandidate ? _urgencyCopy(dueDate!, nowDate) : 'Todo al dia';
    final urgencyColor = hasCandidate
        ? _urgencyTone(dueDate!, nowDate)
        : const Color(0xFF26A69A);

    return Container(
      key: const Key('next-collection-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proximo cobro',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (hasCandidate) ...[
            Text(
              candidate.subscriptionName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currency(candidate.pendingAmount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const Text(
              '\$0.00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No hay cobros pendientes.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              urgency,
              style: TextStyle(
                color: urgencyColor,
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

  Color _urgencyTone(DateTime dueDate, DateTime today) {
    if (dueDate.isBefore(today)) {
      return const Color(0xFFEF5350);
    }
    final remainingDays = dueDate.difference(today).inDays;
    if (remainingDays <= 3) {
      return const Color(0xFFFFB74D);
    }
    return const Color(0xFF42A5F5);
  }
}
