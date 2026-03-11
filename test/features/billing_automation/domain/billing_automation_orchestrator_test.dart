import 'dart:io';

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/billing_automation/data/local/billing_reminder_registry.dart';
import 'package:flutter_project_agents/features/billing_automation/data/platform/local_notification_adapter.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_reminder_scheduler.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('BillingAutomationOrchestrator', () {
    late Directory hiveDir;
    late List<int> encryptionKey;
    late BillingReminderRegistry registry;
    late RecordingNotificationAdapter adapter;
    late BillingAutomationHealth publishedHealth;

    Subscription buildSubscription({
      required String id,
      required DateTime dueDate,
      SubscriptionStatus status = SubscriptionStatus.active,
    }) {
      return Subscription(
        id: id,
        name: 'Netflix',
        color: '#E50914',
        totalCost: 15.99,
        billingCycle: BillingCycle.monthly,
        dueDate: dueDate,
        ownerId: 'owner-1',
        createdAt: DateTime(2025),
        status: status,
      );
    }

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'billing_automation_orchestrator_test',
      );
      Hive.init(hiveDir.path);
      encryptionKey = Hive.generateSecureKey();
      HiveService.clearKeyFailureSafeModeForTesting();
      HiveService.overrideEncryptionKeyProviderForTesting(
        () async => encryptionKey,
      );
      registry = BillingReminderRegistry();
      adapter = RecordingNotificationAdapter();
      publishedHealth = const BillingAutomationHealth.initial();
    });

    tearDown(() async {
      HiveService.overrideEncryptionKeyProviderForTesting(null);
      HiveService.clearKeyFailureSafeModeForTesting();
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('schedules reminders when enabled and permission is granted',
        () async {
      final orchestrator = BillingAutomationOrchestrator(
        scheduler: const BillingReminderScheduler(),
        registry: registry,
        notificationAdapter: adapter,
        loadSubscriptions: () async => [
          buildSubscription(
            id: 'sub-1',
            dueDate: DateTime(2026, 4, 10, 10),
          ),
        ],
        loadSettings: () async => const AppSettings(),
        loadTimezoneId: () async => 'Europe/Madrid',
        publishHealth: (health) => publishedHealth = health,
        now: () => DateTime(2026, 4, 9, 8),
      );

      final result = await orchestrator.run(reason: 'app_start');

      expect(result.scheduledCount, 1);
      expect(result.issue, BillingAutomationIssue.none);
      expect(adapter.scheduledIds, hasLength(1));
      expect(publishedHealth.lastRunReason, 'app_start');
    });

    test('clears reminders when reminders are disabled', () async {
      final seedOrchestrator = BillingAutomationOrchestrator(
        scheduler: const BillingReminderScheduler(),
        registry: registry,
        notificationAdapter: adapter,
        loadSubscriptions: () async => [
          buildSubscription(
            id: 'sub-1',
            dueDate: DateTime(2026, 4, 10, 10),
          ),
        ],
        loadSettings: () async => const AppSettings(),
        loadTimezoneId: () async => 'Europe/Madrid',
        publishHealth: (_) {},
        now: () => DateTime(2026, 4, 9, 8),
      );
      await seedOrchestrator.run(reason: 'seed');
      adapter.reset();

      final orchestrator = BillingAutomationOrchestrator(
        scheduler: const BillingReminderScheduler(),
        registry: registry,
        notificationAdapter: adapter,
        loadSubscriptions: () async => const [],
        loadSettings: () async => const AppSettings(
          paymentRemindersEnabled: false,
        ),
        loadTimezoneId: () async => 'Europe/Madrid',
        publishHealth: (health) => publishedHealth = health,
        now: () => DateTime(2026, 4, 9, 8),
      );

      final result = await orchestrator.run(reason: 'settings_off');

      expect(result.issue, BillingAutomationIssue.remindersDisabled);
      expect(result.scheduledCount, 0);
      expect(adapter.cancelledIds, hasLength(1));
      expect(await registry.getEntries(), isEmpty);
    });

    test('surfaces permission-denied health without scheduling', () async {
      adapter.permissionStatus = NotificationPermissionStatus.denied;
      final orchestrator = BillingAutomationOrchestrator(
        scheduler: const BillingReminderScheduler(),
        registry: registry,
        notificationAdapter: adapter,
        loadSubscriptions: () async => [
          buildSubscription(
            id: 'sub-1',
            dueDate: DateTime(2026, 4, 10, 10),
          ),
        ],
        loadSettings: () async => const AppSettings(),
        loadTimezoneId: () async => 'Europe/Madrid',
        publishHealth: (health) => publishedHealth = health,
        now: () => DateTime(2026, 4, 9, 8),
      );

      final result = await orchestrator.run(reason: 'app_resume');

      expect(result.issue, BillingAutomationIssue.permissionDenied);
      expect(result.scheduledCount, 0);
      expect(adapter.scheduledIds, isEmpty);
      expect(publishedHealth.needsAttention, isTrue);
    });
  });
}

class RecordingNotificationAdapter implements LocalNotificationAdapter {
  final List<int> scheduledIds = <int>[];
  final List<int> cancelledIds = <int>[];
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.granted;

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelledIds.add(notificationId);
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<void> scheduleReminder(BillingReminderPlan plan) async {
    scheduledIds.add(plan.notificationId);
  }

  void reset() {
    scheduledIds.clear();
    cancelledIds.clear();
  }
}
