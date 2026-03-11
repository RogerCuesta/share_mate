import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  unknown,
}

abstract class LocalNotificationAdapter {
  Future<void> scheduleReminder(BillingReminderPlan plan);

  Future<void> cancelReminder(int notificationId);

  Future<NotificationPermissionStatus> getPermissionStatus();

  Future<void> openPermissionSettings();
}

class NoopLocalNotificationAdapter implements LocalNotificationAdapter {
  const NoopLocalNotificationAdapter();

  @override
  Future<void> cancelReminder(int notificationId) async {}

  @override
  Future<void> scheduleReminder(BillingReminderPlan plan) async {}

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    return NotificationPermissionStatus.unknown;
  }

  @override
  Future<void> openPermissionSettings() async {}
}
