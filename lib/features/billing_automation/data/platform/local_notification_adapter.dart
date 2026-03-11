import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';

abstract class LocalNotificationAdapter {
  Future<void> scheduleReminder(BillingReminderPlan plan);

  Future<void> cancelReminder(int notificationId);
}

class NoopLocalNotificationAdapter implements LocalNotificationAdapter {
  const NoopLocalNotificationAdapter();

  @override
  Future<void> cancelReminder(int notificationId) async {}

  @override
  Future<void> scheduleReminder(BillingReminderPlan plan) async {}
}
