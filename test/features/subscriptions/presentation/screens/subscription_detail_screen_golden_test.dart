import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detail summary first golden', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final subscription = Subscription(
      id: 'sub-netflix',
      name: 'Netflix',
      color: '#E50914',
      totalCost: 15.99,
      billingCycle: BillingCycle.monthly,
      dueDate: DateTime(2026, 3, 20),
      ownerId: 'owner',
      createdAt: DateTime(2026, 1, 1),
      sharedWith: const ['u1', 'u2'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubscriptionDetailSummaryHero(subscription: subscription),
                const SizedBox(height: 16),
                const SubscriptionDetailSyncStatusCard(
                  syncStatus: SyncStatus(
                    kind: SyncStatusKind.synced,
                    pendingCount: 0,
                    terminalCount: 0,
                    lastSuccessfulSyncAt: null,
                  ),
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
        '../../../../goldens/phase6/subscription_detail_screen_summary_first.png',
      ),
    );
  });
}
