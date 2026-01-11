import 'package:freezed_annotation/freezed_annotation.dart';

part 'monthly_stats.freezed.dart';

/// Monthly statistics for user's subscriptions
@freezed
class MonthlyStats with _$MonthlyStats {
  const factory MonthlyStats({
    /// Total monthly cost of all active subscriptions
    required double totalMonthlyCost,

    /// Total amount pending to collect from members
    required double pendingToCollect,

    /// Number of active subscriptions
    required int activeSubscriptionsCount,

    /// Number of overdue payments from members
    required int overduePaymentsCount,

    /// Total amount already collected this month
    @Default(0.0) double collectedAmount,

    /// Number of members who have paid
    @Default(0) int paidMembersCount,

    /// Number of members who haven't paid yet
    @Default(0) int unpaidMembersCount,
  }) = _MonthlyStats;

  const MonthlyStats._();

  /// Calculate the percentage of payments collected
  double get collectionRate {
    final totalExpected = pendingToCollect + collectedAmount;
    if (totalExpected == 0) return 0;
    return (collectedAmount / totalExpected) * 100;
  }

  /// Check if there are any overdue payments
  bool get hasOverduePayments => overduePaymentsCount > 0;

  /// Check if all expected payments have been collected
  bool get isFullyCollected {
    return pendingToCollect == 0 && unpaidMembersCount == 0;
  }

  /// Get the total expected income (collected + pending)
  double get totalExpectedIncome => collectedAmount + pendingToCollect;

  /// Get average cost per subscription
  double get averageCostPerSubscription {
    if (activeSubscriptionsCount == 0) return 0;
    return totalMonthlyCost / activeSubscriptionsCount;
  }
}
