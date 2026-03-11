import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_reminder_scheduler.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingReminderScheduler', () {
    Subscription buildSubscription({
      required String id,
      required DateTime dueDate,
      SubscriptionStatus status = SubscriptionStatus.active,
      BillingCycle billingCycle = BillingCycle.monthly,
    }) {
      return Subscription(
        id: id,
        name: 'Netflix',
        color: '#E50914',
        totalCost: 15.99,
        billingCycle: billingCycle,
        dueDate: dueDate,
        ownerId: 'owner-1',
        createdAt: DateTime(2025, 1, 1),
        status: status,
      );
    }

    test('builds one deterministic plan per active subscription cycle', () {
      final scheduler = BillingReminderScheduler();
      final asOf = DateTime(2026, 4, 9, 9);
      final subscription = buildSubscription(
        id: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );

      final plan = scheduler.buildPlan(subscription, asOf: asOf);

      expect(plan, isNotNull);
      expect(plan!.subscriptionId, 'sub-1');
      expect(plan.cycleDueDate, DateTime(2026, 4, 10, 10));
      expect(plan.scheduledAt, DateTime(2026, 4, 9, 10));
      expect(plan.reminderKey, 'sub-1|2026-04-10T10:00:00.000');
      expect(
        plan.notificationId,
        BillingReminderScheduler.buildNotificationId(
          subscriptionId: 'sub-1',
          cycleDueDate: DateTime(2026, 4, 10, 10),
        ),
      );
    });

    test('drops reminder candidates that are already in the past', () {
      final scheduler = BillingReminderScheduler();
      final subscription = buildSubscription(
        id: 'sub-1',
        dueDate: DateTime(2026, 4, 10, 10),
      );

      final plan = scheduler.buildPlan(
        subscription,
        asOf: DateTime(2026, 4, 9, 10, 1),
      );

      expect(plan, isNull);
    });

    test('excludes paused and cancelled subscriptions', () {
      final scheduler = BillingReminderScheduler();
      final asOf = DateTime(2026, 4, 9, 9);

      final plans = scheduler.buildPlans([
        buildSubscription(
          id: 'active',
          dueDate: DateTime(2026, 4, 10, 10),
        ),
        buildSubscription(
          id: 'paused',
          dueDate: DateTime(2026, 4, 10, 10),
          status: SubscriptionStatus.paused,
        ),
        buildSubscription(
          id: 'cancelled',
          dueDate: DateTime(2026, 4, 10, 10),
          status: SubscriptionStatus.cancelled,
        ),
      ], asOf: asOf);

      expect(plans.map((plan) => plan.subscriptionId), equals(['active']));
    });

    test('keeps month and year boundary computation exact at T-24h', () {
      final scheduler = BillingReminderScheduler();
      final subscription = buildSubscription(
        id: 'year-boundary',
        dueDate: DateTime(2026, 1, 1, 8, 30),
        billingCycle: BillingCycle.yearly,
      );

      final plan = scheduler.buildPlan(
        subscription,
        asOf: DateTime(2025, 12, 30, 8, 29),
      );

      expect(plan, isNotNull);
      expect(plan!.scheduledAt, DateTime(2025, 12, 31, 8, 30));
      expect(plan.cycleDueDate, DateTime(2026, 1, 1, 8, 30));
    });

    test('encodes deep-link payload to the existing subscription detail route',
        () {
      final payload = BillingReminderScheduler.buildPayload(
        subscriptionId: 'sub-42',
        cycleDueDate: DateTime(2026, 7, 15, 9),
      );

      final parsed = BillingReminderScheduler.parsePayload(payload);

      expect(parsed.routePath, '/subscription/sub-42');
      expect(parsed.subscriptionId, 'sub-42');
      expect(parsed.source, billingReminderSource);
      expect(parsed.cycleDueDate, DateTime(2026, 7, 15, 9));
    });
  });
}
