import 'dart:io';

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/billing_automation/data/local/billing_reminder_registry.dart';
import 'package:flutter_project_agents/features/billing_automation/data/platform/local_notification_adapter.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('BillingReminderRegistry', () {
    late Directory hiveDir;
    late List<int> encryptionKey;
    late BillingReminderRegistry registry;
    late RecordingLocalNotificationAdapter adapter;

    BillingReminderPlan buildPlan({
      required String subscriptionId,
      required DateTime dueDate,
      DateTime? scheduledAt,
    }) {
      return BillingReminderPlan(
        subscriptionId: subscriptionId,
        subscriptionName: 'Service $subscriptionId',
        subscriptionCost: 9.99,
        cycleDueDate: dueDate,
        scheduledAt: scheduledAt ?? dueDate.subtract(const Duration(hours: 24)),
        payload: '/subscription/$subscriptionId',
        notificationId: dueDate.millisecondsSinceEpoch ~/ 1000,
      );
    }

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'billing_reminder_registry_test',
      );
      Hive.init(hiveDir.path);
      encryptionKey = Hive.generateSecureKey();
      HiveService.clearKeyFailureSafeModeForTesting();
      HiveService.overrideEncryptionKeyProviderForTesting(
        () async => encryptionKey,
      );

      registry = BillingReminderRegistry();
      adapter = RecordingLocalNotificationAdapter();
    });

    tearDown(() async {
      HiveService.overrideEncryptionKeyProviderForTesting(null);
      HiveService.clearKeyFailureSafeModeForTesting();
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('persists registry entries with scheduling metadata', () async {
      final plan = buildPlan(
        subscriptionId: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );

      final result = await registry.syncPlans(
        desiredPlans: [plan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );

      final entries = await registry.getEntries();

      expect(result.created, 1);
      expect(result.kept, 0);
      expect(result.cancelled, 0);
      expect(entries, hasLength(1));
      expect(entries.single.subscriptionId, 'sub-1');
      expect(entries.single.notificationId, plan.notificationId);
      expect(entries.single.scheduledAt, plan.scheduledAt);
      expect(entries.single.timezoneId, 'Europe/Madrid');
      expect(adapter.scheduledIds, equals([plan.notificationId]));
      expect(adapter.cancelledIds, isEmpty);
    });

    test('keeps identical reminders idempotently across repeated runs',
        () async {
      final plan = buildPlan(
        subscriptionId: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );

      await registry.syncPlans(
        desiredPlans: [plan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );
      adapter.reset();

      final result = await registry.syncPlans(
        desiredPlans: [plan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );

      expect(result.created, 0);
      expect(result.kept, 1);
      expect(result.cancelled, 0);
      expect(adapter.scheduledIds, isEmpty);
      expect(adapter.cancelledIds, isEmpty);
    });

    test(
        'cancels stale reminders and creates replacements when schedule changes',
        () async {
      final originalPlan = buildPlan(
        subscriptionId: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );
      final updatedPlan = buildPlan(
        subscriptionId: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
        scheduledAt: DateTime(2026, 4, 9, 11),
      );

      await registry.syncPlans(
        desiredPlans: [originalPlan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );
      adapter.reset();

      final result = await registry.syncPlans(
        desiredPlans: [updatedPlan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );

      final entries = await registry.getEntries();

      expect(result.created, 1);
      expect(result.kept, 0);
      expect(result.cancelled, 1);
      expect(adapter.cancelledIds, equals([originalPlan.notificationId]));
      expect(adapter.scheduledIds, equals([updatedPlan.notificationId]));
      expect(entries.single.scheduledAt, updatedPlan.scheduledAt);
    });

    test('cancels reminders that are no longer desired', () async {
      final plan = buildPlan(
        subscriptionId: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );

      await registry.syncPlans(
        desiredPlans: [plan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );
      adapter.reset();

      final result = await registry.syncPlans(
        desiredPlans: const [],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );

      final entries = await registry.getEntries();

      expect(result.created, 0);
      expect(result.kept, 0);
      expect(result.cancelled, 1);
      expect(entries, isEmpty);
      expect(adapter.cancelledIds, equals([plan.notificationId]));
    });

    test('recreates reminders when the timezone changes', () async {
      final plan = buildPlan(
        subscriptionId: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );

      await registry.syncPlans(
        desiredPlans: [plan],
        timezoneId: 'Europe/Madrid',
        notificationAdapter: adapter,
      );
      adapter.reset();

      final result = await registry.syncPlans(
        desiredPlans: [plan],
        timezoneId: 'America/New_York',
        notificationAdapter: adapter,
      );

      final entries = await registry.getEntries();

      expect(result.created, 1);
      expect(result.kept, 0);
      expect(result.cancelled, 1);
      expect(entries.single.timezoneId, 'America/New_York');
      expect(adapter.cancelledIds, equals([plan.notificationId]));
      expect(adapter.scheduledIds, equals([plan.notificationId]));
    });
  });
}

class RecordingLocalNotificationAdapter implements LocalNotificationAdapter {
  final List<int> scheduledIds = <int>[];
  final List<int> cancelledIds = <int>[];

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelledIds.add(notificationId);
  }

  @override
  Future<void> scheduleReminder(BillingReminderPlan plan) async {
    scheduledIds.add(plan.notificationId);
  }

  void reset() {
    scheduledIds.clear();
    cancelledIds.clear();
  }
}
