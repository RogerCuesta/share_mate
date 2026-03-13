import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/create_subscription_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Add Subscription form sections', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateSubscriptionScreen(),
        ),
      ),
    );

    expect(find.text('Add Subscription'), findsOneWidget);
    expect(find.text('Service Name'), findsOneWidget);
    expect(find.text('Total Price'), findsOneWidget);
    expect(find.text('Billing Cycle'), findsWidgets);
  });
}
