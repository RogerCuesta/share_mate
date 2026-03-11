class BillingReminderPlan {
  BillingReminderPlan({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.subscriptionCost,
    required this.cycleDueDate,
    required this.scheduledAt,
    required this.payload,
    required this.notificationId,
  });

  final String subscriptionId;
  final String subscriptionName;
  final double subscriptionCost;
  final DateTime cycleDueDate;
  final DateTime scheduledAt;
  final String payload;
  final int notificationId;

  String get reminderKey => buildReminderKey(
        subscriptionId: subscriptionId,
        cycleDueDate: cycleDueDate,
      );

  static String buildReminderKey({
    required String subscriptionId,
    required DateTime cycleDueDate,
  }) {
    return '$subscriptionId|${cycleDueDate.toIso8601String()}';
  }
}
