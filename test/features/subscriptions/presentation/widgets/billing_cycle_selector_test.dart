import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/billing_cycle_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches billing cycle option', (tester) async {
    var selected = BillingCycle.monthly;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return BillingCycleSelector(
                selectedCycle: selected,
                onCycleSelected: (next) {
                  setState(() => selected = next);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Monthly'), findsOneWidget);
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(selected, BillingCycle.yearly);
  });

  testWidgets('legacy BillingSycleSelector remains usable', (tester) async {
    var selected = BillingCycle.monthly;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BillingSycleSelector(
            selectedCycle: selected,
            onCycleSelected: (next) => selected = next,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Yearly'));
    await tester.pump();
    expect(selected, BillingCycle.yearly);
  });
}
