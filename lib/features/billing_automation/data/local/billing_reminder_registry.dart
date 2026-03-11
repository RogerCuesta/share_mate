import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/billing_automation/data/platform/local_notification_adapter.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';
import 'package:hive_ce/hive.dart';

class BillingReminderRegistry {
  BillingReminderRegistry();

  static const String boxName = 'billing_reminder_registry';

  Future<List<BillingReminderRegistryEntry>> getEntries() async {
    try {
      final box = await _openBox();
      return box.values
          .map(
            (value) => BillingReminderRegistryEntry.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList()
        ..sort((left, right) => left.reminderKey.compareTo(right.reminderKey));
    } catch (e) {
      throw BillingReminderRegistryException(
        'Failed to load billing reminder registry: ${e.toString()}',
      );
    }
  }

  Future<void> saveEntries(
      Iterable<BillingReminderRegistryEntry> entries) async {
    try {
      HiveService.ensureWritesAllowed('Billing reminder registry save');
      final box = await _openBox();
      final payload = <String, Map<String, dynamic>>{
        for (final entry in entries) entry.reminderKey: entry.toJson(),
      };
      await box.putAll(payload);
    } catch (e) {
      throw BillingReminderRegistryException(
        'Failed to save billing reminder registry entries: ${e.toString()}',
      );
    }
  }

  Future<void> removeEntries(Iterable<String> reminderKeys) async {
    try {
      HiveService.ensureWritesAllowed('Billing reminder registry remove');
      final keys = reminderKeys.toSet().toList();
      if (keys.isEmpty) {
        return;
      }

      final box = await _openBox();
      await box.deleteAll(keys);
    } catch (e) {
      throw BillingReminderRegistryException(
        'Failed to remove billing reminder registry entries: ${e.toString()}',
      );
    }
  }

  Future<void> clear() async {
    try {
      HiveService.ensureWritesAllowed('Billing reminder registry clear');
      final box = await _openBox();
      await box.clear();
    } catch (e) {
      throw BillingReminderRegistryException(
        'Failed to clear billing reminder registry: ${e.toString()}',
      );
    }
  }

  Future<BillingReminderRegistrySyncResult> syncPlans({
    required Iterable<BillingReminderPlan> desiredPlans,
    required String timezoneId,
    required LocalNotificationAdapter notificationAdapter,
  }) async {
    final existingEntries = await getEntries();
    final diff = BillingReminderRegistryDiff.build(
      existingEntries: existingEntries,
      desiredPlans: desiredPlans,
      timezoneId: timezoneId,
    );

    for (final entry in diff.toCancel) {
      await notificationAdapter.cancelReminder(entry.notificationId);
    }

    for (final plan in diff.toCreate) {
      await notificationAdapter.scheduleReminder(plan);
    }

    await removeEntries(diff.toCancel.map((entry) => entry.reminderKey));
    await saveEntries(
      diff.toCreate.map(
        (plan) => BillingReminderRegistryEntry.fromPlan(
          plan,
          timezoneId: timezoneId,
        ),
      ),
    );

    return BillingReminderRegistrySyncResult(
      created: diff.toCreate.length,
      kept: diff.toKeep.length,
      cancelled: diff.toCancel.length,
    );
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }

    return HiveService.openBox<dynamic>(boxName, encrypted: true);
  }
}

class BillingReminderRegistryDiff {
  BillingReminderRegistryDiff({
    required this.toCreate,
    required this.toKeep,
    required this.toCancel,
  });

  factory BillingReminderRegistryDiff.build({
    required Iterable<BillingReminderRegistryEntry> existingEntries,
    required Iterable<BillingReminderPlan> desiredPlans,
    required String timezoneId,
  }) {
    final existingByKey = <String, BillingReminderRegistryEntry>{
      for (final entry in existingEntries) entry.reminderKey: entry,
    };
    final desiredByKey = <String, BillingReminderPlan>{
      for (final plan in desiredPlans) plan.reminderKey: plan,
    };

    final toCreate = <BillingReminderPlan>[];
    final toKeep = <BillingReminderRegistryEntry>[];
    final toCancel = <BillingReminderRegistryEntry>[];

    for (final existing in existingByKey.values) {
      final desired = desiredByKey[existing.reminderKey];
      if (desired == null) {
        toCancel.add(existing);
        continue;
      }

      final expectedEntry = BillingReminderRegistryEntry.fromPlan(
        desired,
        timezoneId: timezoneId,
      );
      if (existing.matches(expectedEntry)) {
        toKeep.add(existing);
      } else {
        toCancel.add(existing);
        toCreate.add(desired);
      }
    }

    for (final desired in desiredByKey.values) {
      if (!existingByKey.containsKey(desired.reminderKey)) {
        toCreate.add(desired);
      }
    }

    toCreate
        .sort((left, right) => left.reminderKey.compareTo(right.reminderKey));
    toKeep.sort((left, right) => left.reminderKey.compareTo(right.reminderKey));
    toCancel
        .sort((left, right) => left.reminderKey.compareTo(right.reminderKey));

    return BillingReminderRegistryDiff(
      toCreate: toCreate,
      toKeep: toKeep,
      toCancel: toCancel,
    );
  }

  final List<BillingReminderPlan> toCreate;
  final List<BillingReminderRegistryEntry> toKeep;
  final List<BillingReminderRegistryEntry> toCancel;
}

class BillingReminderRegistryEntry {
  BillingReminderRegistryEntry({
    required this.subscriptionId,
    required this.cycleDueDate,
    required this.notificationId,
    required this.scheduledAt,
    required this.timezoneId,
  });

  factory BillingReminderRegistryEntry.fromPlan(
    BillingReminderPlan plan, {
    required String timezoneId,
  }) {
    return BillingReminderRegistryEntry(
      subscriptionId: plan.subscriptionId,
      cycleDueDate: plan.cycleDueDate,
      notificationId: plan.notificationId,
      scheduledAt: plan.scheduledAt,
      timezoneId: timezoneId,
    );
  }

  factory BillingReminderRegistryEntry.fromJson(Map<String, dynamic> json) {
    return BillingReminderRegistryEntry(
      subscriptionId: json['subscriptionId'] as String,
      cycleDueDate: DateTime.parse(json['cycleDueDate'] as String),
      notificationId: (json['notificationId'] as num).toInt(),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      timezoneId: json['timezoneId'] as String,
    );
  }

  final String subscriptionId;
  final DateTime cycleDueDate;
  final int notificationId;
  final DateTime scheduledAt;
  final String timezoneId;

  String get reminderKey => BillingReminderPlan.buildReminderKey(
        subscriptionId: subscriptionId,
        cycleDueDate: cycleDueDate,
      );

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'cycleDueDate': cycleDueDate.toIso8601String(),
      'notificationId': notificationId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'timezoneId': timezoneId,
    };
  }

  bool matches(BillingReminderRegistryEntry other) {
    return subscriptionId == other.subscriptionId &&
        cycleDueDate.isAtSameMomentAs(other.cycleDueDate) &&
        notificationId == other.notificationId &&
        scheduledAt.isAtSameMomentAs(other.scheduledAt) &&
        timezoneId == other.timezoneId;
  }
}

class BillingReminderRegistrySyncResult {
  const BillingReminderRegistrySyncResult({
    required this.created,
    required this.kept,
    required this.cancelled,
  });

  final int created;
  final int kept;
  final int cancelled;
}

class BillingReminderRegistryException implements Exception {
  BillingReminderRegistryException(this.message);

  final String message;

  @override
  String toString() => 'BillingReminderRegistryException: $message';
}
