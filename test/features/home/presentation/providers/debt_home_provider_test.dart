import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('debtHomeSnapshotProvider', () {
    test('returns explicit debt-free state when no pending debt exists',
        () async {
      final container = ProviderContainer(
        overrides: [
          pendingPaymentsProvider.overrideWith((ref) async => []),
          activeSubscriptionsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(debtHomeSnapshotProvider.future);
      expect(snapshot.totalPendingDebt, 0);
      expect(snapshot.isDebtFree, isTrue);
      expect(snapshot.hasDebt, isFalse);
      expect(snapshot.nextCollection, isNull);
    });

    test('aggregates pending member amounts and selects overdue subscription',
        () async {
      final container = ProviderContainer(
        overrides: [
          pendingPaymentsProvider.overrideWith(
            (ref) async => [
              _member(
                id: 'm-1',
                subscriptionId: 'sub-1',
                amountToPay: 14,
                dueDate: DateTime(2026, 4, 30),
              ),
              _member(
                id: 'm-2',
                subscriptionId: 'sub-1',
                amountToPay: 6,
                dueDate: DateTime(2026, 4, 30),
              ),
              _member(
                id: 'm-3',
                subscriptionId: 'sub-2',
                amountToPay: 8,
                dueDate: DateTime(2026, 4, 30),
              ),
            ],
          ),
          activeSubscriptionsProvider.overrideWith(
            (ref) async => [
              _subscription(
                id: 'sub-1',
                name: 'Netflix',
                dueDate: DateTime(2026, 3, 1),
              ),
              _subscription(
                id: 'sub-2',
                name: 'Spotify',
                dueDate: DateTime(2099, 3, 10),
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(debtHomeSnapshotProvider.future);
      expect(snapshot.totalPendingDebt, 28);
      expect(snapshot.hasDebt, isTrue);
      expect(snapshot.nextCollection?.subscriptionId, 'sub-1');
      expect(snapshot.nextCollection?.pendingAmount, 20);
    });

    test('keeps total debt even when no active subscription match exists',
        () async {
      final container = ProviderContainer(
        overrides: [
          pendingPaymentsProvider.overrideWith(
            (ref) async => [
              _member(
                id: 'm-1',
                subscriptionId: 'sub-missing',
                amountToPay: 12,
              ),
            ],
          ),
          activeSubscriptionsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(debtHomeSnapshotProvider.future);
      expect(snapshot.totalPendingDebt, 12);
      expect(snapshot.hasDebt, isTrue);
      expect(snapshot.nextCollection, isNull);
    });

    test('prefers nearest due date and higher pending amount on ties',
        () async {
      final now = DateTime(2026, 3, 10);
      final container = ProviderContainer(
        overrides: [
          pendingPaymentsProvider.overrideWith(
            (ref) async => [
              _member(
                id: 'm-1',
                subscriptionId: 'sub-far',
                amountToPay: 25,
                dueDate: DateTime(2026, 4, 1),
              ),
              _member(
                id: 'm-2',
                subscriptionId: 'sub-near-low',
                amountToPay: 9,
                dueDate: DateTime(2026, 3, 13),
              ),
              _member(
                id: 'm-3',
                subscriptionId: 'sub-near-high',
                amountToPay: 14,
                dueDate: DateTime(2026, 3, 13),
              ),
            ],
          ),
          activeSubscriptionsProvider.overrideWith(
            (ref) async => [
              _subscription(
                id: 'sub-far',
                name: 'Annual Tool',
                dueDate: DateTime(2026, 4, 1),
              ),
              _subscription(
                id: 'sub-near-low',
                name: 'Streaming Lite',
                dueDate: DateTime(2026, 3, 13),
              ),
              _subscription(
                id: 'sub-near-high',
                name: 'Streaming Pro',
                dueDate: DateTime(2026, 3, 13),
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = buildDebtHomeSnapshot(
        pendingPayments: await container.read(pendingPaymentsProvider.future),
        activeSubscriptions:
            await container.read(activeSubscriptionsProvider.future),
        now: now,
      );

      expect(snapshot.totalPendingDebt, 48);
      expect(snapshot.nextCollection?.subscriptionId, 'sub-near-high');
      expect(snapshot.nextCollection?.pendingAmount, 14);
      expect(snapshot.nextCollection?.isOverdue, isFalse);
    });
  });
}

Subscription _subscription({
  required String id,
  required String name,
  required DateTime dueDate,
}) {
  return Subscription(
    id: id,
    name: name,
    color: '#000000',
    totalCost: 10,
    billingCycle: BillingCycle.monthly,
    dueDate: dueDate,
    ownerId: 'owner-1',
    createdAt: DateTime(2026, 1, 1),
  );
}

SubscriptionMember _member({
  required String id,
  required String subscriptionId,
  required double amountToPay,
  DateTime? dueDate,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: subscriptionId,
    userId: 'user-$id',
    userName: 'User $id',
    amountToPay: amountToPay,
    dueDate: dueDate ?? DateTime(2026, 3, 15),
    createdAt: DateTime(2026, 1, 1),
  );
}
