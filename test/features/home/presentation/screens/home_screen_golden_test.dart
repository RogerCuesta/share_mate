import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/debt_home_kpi_card.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/next_collection_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home first fold golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final snapshot = DebtHomeSnapshot(
      totalPendingDebt: 148.50,
      nextCollection: NextCollectionCandidate(
        subscriptionId: 'netflix',
        subscriptionName: 'Netflix',
        dueDate: DateTime(2026, 3, 20),
        pendingAmount: 38,
        isOverdue: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                DebtHomeKpiCard(snapshot: snapshot),
                const SizedBox(height: 16),
                NextCollectionCard(snapshot: snapshot, now: DateTime(2026, 3, 17)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('../../../../goldens/phase6/home_screen_first_fold.png'),
    );
  });
}
