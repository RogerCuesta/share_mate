import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final debtHomeSnapshotProvider =
    FutureProvider.autoDispose<DebtHomeSnapshot>((ref) async {
      final pendingPayments = await ref.watch(pendingPaymentsProvider.future);
      final activeSubscriptions =
          await ref.watch(activeSubscriptionsProvider.future);

      return buildDebtHomeSnapshot(
        pendingPayments: pendingPayments,
        activeSubscriptions: activeSubscriptions,
      );
    });

Map<String, double> pendingAmountBySubscription(
  List<SubscriptionMember> pendingPayments,
) {
  final grouped = <String, double>{};

  for (final member in pendingPayments) {
    if (member.hasPaid) {
      continue;
    }
    grouped.update(
      member.subscriptionId,
      (current) => current + member.amountToPay,
      ifAbsent: () => member.amountToPay,
    );
  }

  return grouped;
}

List<NextCollectionCandidate> buildNextCollectionCandidates({
  required List<SubscriptionMember> pendingPayments,
  required List<Subscription> activeSubscriptions,
  DateTime? now,
}) {
  final pendingBySubscription = pendingAmountBySubscription(pendingPayments);
  final subscriptionsById = {
    for (final subscription in activeSubscriptions) subscription.id: subscription,
  };
  final today = _toDateOnly(now ?? DateTime.now());
  final candidates = <NextCollectionCandidate>[];

  for (final entry in pendingBySubscription.entries) {
    final subscription = subscriptionsById[entry.key];
    if (subscription == null) {
      continue;
    }
    final dueDate = _toDateOnly(subscription.dueDate);
    candidates.add(
      NextCollectionCandidate(
        subscriptionId: subscription.id,
        subscriptionName: subscription.name,
        dueDate: dueDate,
        pendingAmount: entry.value,
        isOverdue: dueDate.isBefore(today),
      ),
    );
  }

  return candidates;
}

NextCollectionCandidate? selectNextCollectionCandidate(
  List<NextCollectionCandidate> candidates,
) {
  if (candidates.isEmpty) {
    return null;
  }

  final sorted = [...candidates]
    ..sort((a, b) {
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }

      final dueDateComparison = a.dueDate.compareTo(b.dueDate);
      if (dueDateComparison != 0) {
        return dueDateComparison;
      }

      final amountComparison = b.pendingAmount.compareTo(a.pendingAmount);
      if (amountComparison != 0) {
        return amountComparison;
      }

      return a.subscriptionId.compareTo(b.subscriptionId);
    });

  return sorted.first;
}

DebtHomeSnapshot buildDebtHomeSnapshot({
  required List<SubscriptionMember> pendingPayments,
  required List<Subscription> activeSubscriptions,
  DateTime? now,
}) {
  final totalPendingDebt = pendingPayments
      .where((member) => !member.hasPaid)
      .fold<double>(0, (sum, member) => sum + member.amountToPay);

  if (totalPendingDebt <= 0) {
    return const DebtHomeSnapshot.debtFree();
  }

  final candidates = buildNextCollectionCandidates(
    pendingPayments: pendingPayments,
    activeSubscriptions: activeSubscriptions,
    now: now,
  );

  return DebtHomeSnapshot(
    totalPendingDebt: totalPendingDebt,
    nextCollection: selectNextCollectionCandidate(candidates),
  );
}

DateTime _toDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
