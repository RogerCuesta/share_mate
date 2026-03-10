import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('debt next collection selectors', () {
    test('groups pending amount by subscription id', () {
      final pendingPayments = [
        _member(
          id: 'm-1',
          subscriptionId: 'sub-1',
          amountToPay: 12,
        ),
        _member(
          id: 'm-2',
          subscriptionId: 'sub-1',
          amountToPay: 8,
        ),
        _member(
          id: 'm-3',
          subscriptionId: 'sub-2',
          amountToPay: 15,
        ),
      ];

      final grouped = pendingAmountBySubscription(pendingPayments);
      expect(grouped['sub-1'], 20);
      expect(grouped['sub-2'], 15);
    });

    test('prioritizes overdue candidates before non-overdue', () {
      final selected = selectNextCollectionCandidate([
        NextCollectionCandidate(
          subscriptionId: 'sub-2',
          subscriptionName: 'Soon',
          dueDate: DateTime(2026, 3, 12),
          pendingAmount: 50,
          isOverdue: false,
        ),
        NextCollectionCandidate(
          subscriptionId: 'sub-1',
          subscriptionName: 'Overdue',
          dueDate: DateTime(2026, 3, 1),
          pendingAmount: 5,
          isOverdue: true,
        ),
      ]);

      expect(selected?.subscriptionId, 'sub-1');
    });

    test('selects nearest due date when no candidates are overdue', () {
      final selected = selectNextCollectionCandidate([
        NextCollectionCandidate(
          subscriptionId: 'sub-late',
          subscriptionName: 'Late',
          dueDate: DateTime(2026, 3, 20),
          pendingAmount: 100,
          isOverdue: false,
        ),
        NextCollectionCandidate(
          subscriptionId: 'sub-near',
          subscriptionName: 'Near',
          dueDate: DateTime(2026, 3, 11),
          pendingAmount: 1,
          isOverdue: false,
        ),
      ]);

      expect(selected?.subscriptionId, 'sub-near');
    });

    test('uses highest pending amount as tie-break for same due date', () {
      final selected = selectNextCollectionCandidate([
        NextCollectionCandidate(
          subscriptionId: 'sub-small',
          subscriptionName: 'Small',
          dueDate: DateTime(2026, 3, 11),
          pendingAmount: 15,
          isOverdue: false,
        ),
        NextCollectionCandidate(
          subscriptionId: 'sub-large',
          subscriptionName: 'Large',
          dueDate: DateTime(2026, 3, 11),
          pendingAmount: 30,
          isOverdue: false,
        ),
      ]);

      expect(selected?.subscriptionId, 'sub-large');
    });

    test('uses stable subscription-id fallback ordering', () {
      final selected = selectNextCollectionCandidate([
        NextCollectionCandidate(
          subscriptionId: 'sub-c',
          subscriptionName: 'C',
          dueDate: DateTime(2026, 3, 11),
          pendingAmount: 30,
          isOverdue: false,
        ),
        NextCollectionCandidate(
          subscriptionId: 'sub-a',
          subscriptionName: 'A',
          dueDate: DateTime(2026, 3, 11),
          pendingAmount: 30,
          isOverdue: false,
        ),
      ]);

      expect(selected?.subscriptionId, 'sub-a');
    });

    test('regression: same due date with mixed amounts picks highest first', () {
      final selected = selectNextCollectionCandidate([
        NextCollectionCandidate(
          subscriptionId: 'sub-2',
          subscriptionName: 'Two',
          dueDate: DateTime(2026, 3, 18),
          pendingAmount: 20,
          isOverdue: false,
        ),
        NextCollectionCandidate(
          subscriptionId: 'sub-1',
          subscriptionName: 'One',
          dueDate: DateTime(2026, 3, 18),
          pendingAmount: 45,
          isOverdue: false,
        ),
        NextCollectionCandidate(
          subscriptionId: 'sub-3',
          subscriptionName: 'Three',
          dueDate: DateTime(2026, 3, 18),
          pendingAmount: 5,
          isOverdue: false,
        ),
      ]);

      expect(selected?.subscriptionId, 'sub-1');
      expect(selected?.pendingAmount, 45);
    });

    test('builds candidates using subscription-level due date as canonical',
        () {
      final now = DateTime(2026, 3, 10, 16);
      final pendingPayments = [
        _member(
          id: 'm-1',
          subscriptionId: 'sub-1',
          amountToPay: 20,
          // Member due date is intentionally different from subscription date.
          dueDate: DateTime(2026, 3, 30),
        ),
      ];
      final subscriptions = [
        _subscription(
          id: 'sub-1',
          name: 'Netflix',
          dueDate: DateTime(2026, 3, 1),
        ),
      ];

      final candidates = buildNextCollectionCandidates(
        pendingPayments: pendingPayments,
        activeSubscriptions: subscriptions,
        now: now,
      );

      expect(candidates.single.isOverdue, isTrue);
      expect(candidates.single.dueDate, DateTime(2026, 3, 1));
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
