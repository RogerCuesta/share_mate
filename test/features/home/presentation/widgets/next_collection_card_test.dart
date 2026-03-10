import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/next_collection_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NextCollectionCard', () {
    testWidgets('renders overdue candidate details with urgency copy',
        (tester) async {
      final snapshot = DebtHomeSnapshot(
        totalPendingDebt: 38,
        nextCollection: NextCollectionCandidate(
          subscriptionId: 'sub-netflix',
          subscriptionName: 'Netflix',
          dueDate: DateTime.utc(2026, 3, 8),
          pendingAmount: 38,
          isOverdue: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextCollectionCard(
              snapshot: snapshot,
              now: DateTime.utc(2026, 3, 10),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('next-collection-card')), findsOneWidget);
      expect(find.text('Proximo cobro'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('\$38.00'), findsOneWidget);
      expect(find.text('Vencido hace 2 dias'), findsOneWidget);
    });

    testWidgets('renders near-due urgency copy', (tester) async {
      final snapshot = DebtHomeSnapshot(
        totalPendingDebt: 18,
        nextCollection: NextCollectionCandidate(
          subscriptionId: 'sub-spotify',
          subscriptionName: 'Spotify',
          dueDate: DateTime.utc(2026, 3, 12),
          pendingAmount: 18,
          isOverdue: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextCollectionCard(
              snapshot: snapshot,
              now: DateTime.utc(2026, 3, 10),
            ),
          ),
        ),
      );

      expect(find.text('En 2 dias'), findsOneWidget);
    });

    testWidgets('renders todo al dia when next collection is not available',
        (tester) async {
      const snapshot = DebtHomeSnapshot.debtFree();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NextCollectionCard(snapshot: snapshot),
          ),
        ),
      );

      expect(find.text('Todo al dia'), findsOneWidget);
      expect(find.text('\$0.00'), findsOneWidget);
      expect(find.textContaining('Vencido'), findsNothing);
    });
  });
}
