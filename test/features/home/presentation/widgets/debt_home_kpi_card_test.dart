import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/debt_home_kpi_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebtHomeKpiCard', () {
    testWidgets('renders total debt with debt-focused copy', (tester) async {
      const snapshot = DebtHomeSnapshot(
        totalPendingDebt: 48.5,
        nextCollection: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebtHomeKpiCard(snapshot: snapshot),
          ),
        ),
      );

      expect(find.byKey(const Key('debt-home-kpi-card')), findsOneWidget);
      expect(find.text('Deuda total a favor'), findsOneWidget);
      expect(find.text('\$48.50'), findsOneWidget);
      expect(find.text('Pendiente del ciclo actual'), findsOneWidget);
    });

    testWidgets('renders todo al dia state for debt-free snapshot', (tester) async {
      const snapshot = DebtHomeSnapshot.debtFree();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebtHomeKpiCard(snapshot: snapshot),
          ),
        ),
      );

      expect(find.text('\$0.00'), findsOneWidget);
      expect(find.text('Todo al dia'), findsOneWidget);
    });
  });
}
