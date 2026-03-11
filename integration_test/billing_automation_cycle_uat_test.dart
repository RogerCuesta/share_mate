import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/billing_automation/data/local/billing_reminder_registry.dart';
import 'package:flutter_project_agents/features/billing_automation/data/platform/local_notification_adapter.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_reminder_scheduler.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('Billing automation cycle UAT', () {
    late Directory hiveDir;
    late List<int> encryptionKey;
    late BillingReminderRegistry registry;
    late RecordingNotificationAdapter adapter;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'billing_automation_cycle_uat',
      );
      Hive.init(hiveDir.path);
      encryptionKey = Hive.generateSecureKey();
      HiveService.clearKeyFailureSafeModeForTesting();
      HiveService.overrideEncryptionKeyProviderForTesting(
        () async => encryptionKey,
      );
      registry = BillingReminderRegistry();
      adapter = RecordingNotificationAdapter();
    });

    tearDown(() async {
      HiveService.overrideEncryptionKeyProviderForTesting(null);
      HiveService.clearKeyFailureSafeModeForTesting();
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    testWidgets(
      'schedules once across app start and resume and keeps reset feedback non-blocking',
      (tester) async {
        final subscription = Subscription(
          id: 'sub-1',
          name: 'Netflix',
          color: '#E50914',
          totalCost: 15.99,
          billingCycle: BillingCycle.monthly,
          dueDate: DateTime(2026, 4, 10, 10),
          ownerId: 'owner-1',
          createdAt: DateTime(2026),
        );

        final orchestrator = BillingAutomationOrchestrator(
          scheduler: const BillingReminderScheduler(),
          registry: registry,
          notificationAdapter: adapter,
          loadSubscriptions: () async => [subscription],
          loadSettings: () async => const AppSettings(),
          loadTimezoneId: () async => 'Europe/Madrid',
          publishHealth: (_) {},
          now: () => DateTime(2026, 4, 9, 8),
        );

        final firstRun = await orchestrator.run(reason: 'app_start');
        final secondRun = await orchestrator.run(reason: 'app_resume');

        expect(firstRun.createdCount, 1);
        expect(firstRun.scheduledCount, 1);
        expect(secondRun.keptCount, 1);
        expect(secondRun.scheduledCount, 1);
        expect(adapter.scheduledIds, hasLength(1));

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: _ReconciliationHarness(),
            ),
          ),
        );

        container.read(paymentReconciliationProvider.notifier).emit(
              reason: PaymentReconciliationReason.backendCycleReset,
              emittedAt: DateTime(2026, 4, 10, 8),
            );
        await tester.pump();

        expect(
          find.text('New billing cycle started. Pending payments were refreshed.'),
          findsOneWidget,
        );
      },
    );
  });
}

class _ReconciliationHarness extends ConsumerWidget {
  const _ReconciliationHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PaymentReconciliationSignal?>(
      paymentReconciliationProvider,
      (previous, next) {
        if (next == null || previous?.sequence == next.sequence) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(paymentReconciliationMessage(next.reason)),
            ),
          );
      },
    );

    return const Scaffold(
      body: SizedBox.expand(),
    );
  }
}

class RecordingNotificationAdapter implements LocalNotificationAdapter {
  final List<int> scheduledIds = <int>[];

  @override
  Future<void> cancelReminder(int notificationId) async {}

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<void> scheduleReminder(BillingReminderPlan plan) async {
    scheduledIds.add(plan.notificationId);
  }
}
