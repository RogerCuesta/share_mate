// lib/features/subscriptions/domain/entities/subscription_spending.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_spending.freezed.dart';

/// Spending data by subscription for analytics
@freezed
class SubscriptionSpending with _$SubscriptionSpending {
  const factory SubscriptionSpending({
    /// Subscription unique identifier
    required String subscriptionId,

    /// Subscription name (denormalized from payment_history)
    required String subscriptionName,

    /// Total amount paid for this subscription (sum WHERE action='paid')
    required double totalAmountPaid,

    /// Number of payments made for this subscription
    required int paymentCount,

    /// Subscription color for chart visualization
    required String color,
  }) = _SubscriptionSpending;

  const SubscriptionSpending._();

  /// Calculate percentage of total spending
  double getPercentage(double totalSpending) {
    if (totalSpending == 0) return 0;
    return (totalAmountPaid / totalSpending) * 100;
  }
}
