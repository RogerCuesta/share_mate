import 'package:flutter_project_agents/features/billing_automation/data/local/billing_reminder_registry.dart';
import 'package:flutter_project_agents/features/billing_automation/data/platform/local_notification_adapter.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_reminder_scheduler.dart';
import 'package:flutter_project_agents/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';

typedef LoadBillingSubscriptions = Future<List<Subscription>> Function();
typedef LoadBillingSettings = Future<AppSettings> Function();
typedef LoadBillingTimezone = Future<String> Function();
typedef PublishBillingAutomationHealth = void Function(
  BillingAutomationHealth health,
);

class BillingAutomationOrchestrator {
  BillingAutomationOrchestrator({
    required BillingReminderScheduler scheduler,
    required BillingReminderRegistry registry,
    required LocalNotificationAdapter notificationAdapter,
    required LoadBillingSubscriptions loadSubscriptions,
    required LoadBillingSettings loadSettings,
    required LoadBillingTimezone loadTimezoneId,
    required PublishBillingAutomationHealth publishHealth,
    DateTime Function()? now,
  })  : _scheduler = scheduler,
        _registry = registry,
        _notificationAdapter = notificationAdapter,
        _loadSubscriptions = loadSubscriptions,
        _loadSettings = loadSettings,
        _loadTimezoneId = loadTimezoneId,
        _publishHealth = publishHealth,
        _now = now ?? DateTime.now;

  final BillingReminderScheduler _scheduler;
  final BillingReminderRegistry _registry;
  final LocalNotificationAdapter _notificationAdapter;
  final LoadBillingSubscriptions _loadSubscriptions;
  final LoadBillingSettings _loadSettings;
  final LoadBillingTimezone _loadTimezoneId;
  final PublishBillingAutomationHealth _publishHealth;
  final DateTime Function() _now;

  Future<BillingAutomationHealth> run({
    required String reason,
  }) async {
    final settings = await _loadSettings();
    final permissionStatus = await _notificationAdapter.getPermissionStatus();
    final timezoneId = await _loadTimezoneId();

    if (!settings.paymentRemindersEnabled) {
      await _cancelAllScheduledReminders();
      final health = BillingAutomationHealth(
        remindersEnabled: false,
        permissionStatus: permissionStatus,
        scheduledCount: 0,
        timezoneId: timezoneId,
        lastRunAt: _now(),
        lastRunReason: reason,
        issue: BillingAutomationIssue.remindersDisabled,
      );
      _publishHealth(health);
      return health;
    }

    if (permissionStatus == NotificationPermissionStatus.denied) {
      await _cancelAllScheduledReminders();
      final health = BillingAutomationHealth(
        remindersEnabled: true,
        permissionStatus: permissionStatus,
        scheduledCount: 0,
        timezoneId: timezoneId,
        lastRunAt: _now(),
        lastRunReason: reason,
        issue: BillingAutomationIssue.permissionDenied,
      );
      _publishHealth(health);
      return health;
    }

    final subscriptions = await _loadSubscriptions();
    final plans = _scheduler.buildPlans(subscriptions, asOf: _now());
    final syncResult = await _registry.syncPlans(
      desiredPlans: plans,
      timezoneId: timezoneId,
      notificationAdapter: _notificationAdapter,
    );

    final health = BillingAutomationHealth(
      remindersEnabled: true,
      permissionStatus: permissionStatus,
      scheduledCount: plans.length,
      timezoneId: timezoneId,
      lastRunAt: _now(),
      lastRunReason: reason,
      createdCount: syncResult.created,
      keptCount: syncResult.kept,
      cancelledCount: syncResult.cancelled,
    );
    _publishHealth(health);
    return health;
  }

  Future<BillingAutomationHealth> clearAll({
    required String reason,
  }) async {
    final permissionStatus = await _notificationAdapter.getPermissionStatus();
    final timezoneId = await _loadTimezoneId();
    await _cancelAllScheduledReminders();
    final health = BillingAutomationHealth(
      remindersEnabled: false,
      permissionStatus: permissionStatus,
      scheduledCount: 0,
      timezoneId: timezoneId,
      lastRunAt: _now(),
      lastRunReason: reason,
      issue: BillingAutomationIssue.remindersDisabled,
    );
    _publishHealth(health);
    return health;
  }

  Future<void> openPermissionSettings() async {
    await _notificationAdapter.openPermissionSettings();
  }

  Future<void> _cancelAllScheduledReminders() async {
    final entries = await _registry.getEntries();
    for (final entry in entries) {
      await _notificationAdapter.cancelReminder(entry.notificationId);
    }
    await _registry.clear();
  }
}

enum BillingAutomationIssue {
  none,
  remindersDisabled,
  permissionDenied,
}

class BillingAutomationHealth {
  const BillingAutomationHealth({
    required this.remindersEnabled,
    required this.permissionStatus,
    required this.scheduledCount,
    required this.timezoneId,
    required this.lastRunAt,
    required this.lastRunReason,
    this.issue = BillingAutomationIssue.none,
    this.createdCount = 0,
    this.keptCount = 0,
    this.cancelledCount = 0,
  });

  const BillingAutomationHealth.initial()
      : remindersEnabled = true,
        permissionStatus = NotificationPermissionStatus.unknown,
        scheduledCount = 0,
        timezoneId = '',
        lastRunAt = null,
        lastRunReason = 'not_started',
        issue = BillingAutomationIssue.none,
        createdCount = 0,
        keptCount = 0,
        cancelledCount = 0;

  final bool remindersEnabled;
  final NotificationPermissionStatus permissionStatus;
  final int scheduledCount;
  final String timezoneId;
  final DateTime? lastRunAt;
  final String lastRunReason;
  final BillingAutomationIssue issue;
  final int createdCount;
  final int keptCount;
  final int cancelledCount;

  bool get needsAttention =>
      issue == BillingAutomationIssue.permissionDenied ||
      issue == BillingAutomationIssue.remindersDisabled;

  String get statusLabel {
    switch (issue) {
      case BillingAutomationIssue.permissionDenied:
        return 'Reminder permission needed';
      case BillingAutomationIssue.remindersDisabled:
        return 'Reminders off';
      case BillingAutomationIssue.none:
        return scheduledCount == 0 ? 'No reminders scheduled' : 'Reminders ready';
    }
  }

  String get detailLabel {
    switch (issue) {
      case BillingAutomationIssue.permissionDenied:
        return 'Enable notifications to schedule payment reminders.';
      case BillingAutomationIssue.remindersDisabled:
        return 'Payment reminders are currently disabled.';
      case BillingAutomationIssue.none:
        return 'Scheduled reminders: $scheduledCount';
    }
  }
}
