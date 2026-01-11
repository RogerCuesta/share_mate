import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscriptions_provider.g.dart';

/// Provider for monthly statistics
///
/// Fetches and caches monthly stats for the current user.
/// Stats include: total cost, pending collections, overdue payments, etc.
///
/// Auto-disposes when not in use.
/// Throws SubscriptionFailure on error (handled by AsyncValue).
@riverpod
Future<MonthlyStats> monthlyStats(MonthlyStatsRef ref) async {
  // Get current user ID from auth provider
  final authState = ref.watch(authProvider);

  return authState.maybeWhen(
    authenticated: (user) async {
      final useCase = ref.watch(getMonthlyStatsProvider);
      final result = await useCase(user.id);

      return result.fold(
        (failure) => throw failure, // AsyncValue will catch and show error
        (stats) => stats,
      );
    },
    orElse: () {
      // If not authenticated, return empty stats
      return const MonthlyStats(
        totalMonthlyCost: 0,
        pendingToCollect: 0,
        activeSubscriptionsCount: 0,
        overduePaymentsCount: 0,
      );
    },
  );
}

/// Provider for active subscriptions
///
/// Fetches and caches active subscriptions for the current user.
/// Only returns subscriptions with status = active.
///
/// Auto-disposes when not in use.
/// Throws SubscriptionFailure on error (handled by AsyncValue).
@riverpod
Future<List<Subscription>> activeSubscriptions(
  ActiveSubscriptionsRef ref,
) async {
  // Get current user ID from auth provider
  final authState = ref.watch(authProvider);

  return authState.maybeWhen(
    authenticated: (user) async {
      final useCase = ref.watch(getActiveSubscriptionsProvider);
      final result = await useCase(user.id);

      return result.fold(
        (failure) => throw failure, // AsyncValue will catch and show error
        (subscriptions) => subscriptions,
      );
    },
    orElse: () => [], // If not authenticated, return empty list
  );
}

/// Provider for pending payments
///
/// Fetches and caches subscription members who haven't paid yet.
/// Useful for showing "Action Required" section in home screen.
///
/// Auto-disposes when not in use.
/// Throws SubscriptionFailure on error (handled by AsyncValue).
@riverpod
Future<List<SubscriptionMember>> pendingPayments(
  PendingPaymentsRef ref,
) async {
  // Get current user ID from auth provider
  final authState = ref.watch(authProvider);

  return authState.maybeWhen(
    authenticated: (user) async {
      final useCase = ref.watch(getPendingPaymentsProvider);
      final result = await useCase(user.id);

      return result.fold(
        (failure) => throw failure, // AsyncValue will catch and show error
        (payments) => payments,
      );
    },
    orElse: () => [], // If not authenticated, return empty list
  );
}

/// Provider for overdue payments
///
/// Computed provider that filters pending payments to show only overdue ones.
/// Depends on pendingPaymentsProvider.
@riverpod
Future<List<SubscriptionMember>> overduePayments(
  OverduePaymentsRef ref,
) async {
  final allPending = await ref.watch(pendingPaymentsProvider.future);

  // Filter to only show overdue payments
  return allPending.where((member) => member.isOverdue).toList();
}

/// Provider for a specific subscription by ID
///
/// Fetches details of a single subscription.
/// Uses .family to accept subscriptionId parameter.
///
/// Auto-disposes when not in use.
@riverpod
Future<Subscription> subscriptionDetails(
  SubscriptionDetailsRef ref,
  String subscriptionId,
) async {
  final useCase = ref.watch(getSubscriptionDetailsProvider);
  final result = await useCase(subscriptionId);

  return result.fold(
    (failure) => throw failure,
    (subscription) => subscription,
  );
}

/// Provider for selected bottom navigation index
///
/// Manages the currently selected tab in the bottom navigation bar.
/// Defaults to 0 (Home).
///
/// Usage:
/// - Read: `ref.watch(selectedBottomNavIndexProvider)`
/// - Update: `ref.read(selectedBottomNavIndexProvider.notifier).setIndex(1)`
@riverpod
class SelectedBottomNavIndex extends _$SelectedBottomNavIndex {
  @override
  int build() => 0; // Home by default

  /// Set the selected bottom navigation index
  void setIndex(int index) {
    state = index;
  }
}
