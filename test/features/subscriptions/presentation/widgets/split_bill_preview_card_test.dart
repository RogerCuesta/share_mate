import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/split_bill_preview_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders split summary and breakdown rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SplitBillPreviewCard(
            totalAmount: 30,
            totalMembers: 3,
            splitAmount: 10,
            breakdown: [
              MemberSplit(name: 'Ana', amount: 10),
              MemberSplit(name: 'Bob', amount: 10),
              MemberSplit(name: 'Cara', amount: 10),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Split Bill Preview'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Cara'), findsOneWidget);
  });
}
