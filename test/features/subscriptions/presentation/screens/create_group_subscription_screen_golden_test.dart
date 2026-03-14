import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_sticky_submit_bar.dart';
import 'package:flutter_project_agents/core/widgets/app_text_field.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/billing_cycle_selector.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/split_bill_preview_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create group default golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Group Subscription'),
                const SizedBox(height: 16),
                const AppTextField(
                  label: 'Service Name',
                  hintText: 'Netflix',
                ),
                const SizedBox(height: 12),
                const AppTextField(
                  label: 'Total Price',
                  hintText: '15.99',
                ),
                const SizedBox(height: 12),
                BillingCycleSelector(
                  selectedCycle: BillingCycle.monthly,
                  onCycleSelected: (_) {},
                ),
                const Spacer(),
                AppStickySubmitBar(
                  primaryLabel: 'Create',
                  secondaryLabel: 'Cancel',
                  onPrimaryPressed: () {},
                  onSecondaryPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../../../../goldens/phase6/create_group_subscription_screen_default.png',
      ),
    );
  });

  testWidgets('create group with members golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Create Group Subscription'),
                SizedBox(height: 16),
                SplitBillPreviewCard(
                  totalAmount: 30,
                  totalMembers: 3,
                  splitAmount: 10,
                  breakdown: [
                    MemberSplit(name: 'Ana', amount: 10),
                    MemberSplit(name: 'Bob', amount: 10),
                    MemberSplit(name: 'Cara', amount: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        '../../../../goldens/phase6/create_group_subscription_screen_with_members.png',
      ),
    );
  });
}
