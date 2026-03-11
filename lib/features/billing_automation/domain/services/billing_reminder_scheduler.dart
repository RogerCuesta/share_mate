import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/models/billing_reminder_plan.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/routing/app_router.dart';

class BillingReminderScheduler {
  const BillingReminderScheduler({
    DateTime Function()? now,
  }) : _now = now ?? _defaultNow;

  final DateTime Function() _now;

  List<BillingReminderPlan> buildPlans(
    Iterable<Subscription> subscriptions, {
    DateTime? asOf,
  }) {
    final reference = (asOf ?? _now()).toLocal();
    final plans = subscriptions
        .map((subscription) => buildPlan(subscription, asOf: reference))
        .whereType<BillingReminderPlan>()
        .toList()
      ..sort(_comparePlans);

    return plans;
  }

  BillingReminderPlan? buildPlan(
    Subscription subscription, {
    DateTime? asOf,
  }) {
    if (!subscription.status.isActive) {
      return null;
    }

    final cycleDueDate = subscription.dueDate.toLocal();
    final scheduledAt = cycleDueDate.subtract(const Duration(hours: 24));
    final reference = (asOf ?? _now()).toLocal();

    if (scheduledAt.isBefore(reference)) {
      return null;
    }

    final payload = buildPayload(
      subscriptionId: subscription.id,
      cycleDueDate: cycleDueDate,
    );

    return BillingReminderPlan(
      subscriptionId: subscription.id,
      subscriptionName: subscription.name,
      subscriptionCost: subscription.totalCost,
      cycleDueDate: cycleDueDate,
      scheduledAt: scheduledAt,
      payload: payload,
      notificationId: buildNotificationId(
        subscriptionId: subscription.id,
        cycleDueDate: cycleDueDate,
      ),
    );
  }

  static String buildPayload({
    required String subscriptionId,
    required DateTime cycleDueDate,
  }) {
    final uri = Uri(
      path: subscriptionDetailPath(subscriptionId),
      queryParameters: <String, String>{
        'source': billingReminderSource,
        'cycleDueDate': cycleDueDate.toIso8601String(),
      },
    );

    return uri.toString();
  }

  static BillingReminderNavigationPayload parsePayload(String payload) {
    final uri = Uri.parse(payload);

    return BillingReminderNavigationPayload(
      routePath: uri.path,
      subscriptionId: uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '',
      source: uri.queryParameters['source'] ?? '',
      cycleDueDate: uri.queryParameters['cycleDueDate'] != null
          ? DateTime.parse(uri.queryParameters['cycleDueDate']!)
          : null,
    );
  }

  static String subscriptionDetailPath(String subscriptionId) {
    return AppRoutes.subscriptionDetailPath(subscriptionId);
  }

  static int buildNotificationId({
    required String subscriptionId,
    required DateTime cycleDueDate,
  }) {
    final digest = sha1.convert(
      utf8.encode(
        BillingReminderPlan.buildReminderKey(
          subscriptionId: subscriptionId,
          cycleDueDate: cycleDueDate,
        ),
      ),
    );

    final bytes = digest.bytes;
    final value =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];

    return value & 0x7fffffff;
  }

  static int _comparePlans(
    BillingReminderPlan left,
    BillingReminderPlan right,
  ) {
    final scheduledAtComparison = left.scheduledAt.compareTo(right.scheduledAt);
    if (scheduledAtComparison != 0) {
      return scheduledAtComparison;
    }

    return left.reminderKey.compareTo(right.reminderKey);
  }

  static DateTime _defaultNow() => DateTime.now();
}

class BillingReminderNavigationPayload {
  const BillingReminderNavigationPayload({
    required this.routePath,
    required this.subscriptionId,
    required this.source,
    this.cycleDueDate,
  });

  final String routePath;
  final String subscriptionId;
  final String source;
  final DateTime? cycleDueDate;
}

const billingReminderSource = 'billing_reminder';
