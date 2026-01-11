// lib/features/subscriptions/domain/entities/analytics_data.dart

import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_overview.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_spending.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_analytics.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_spending.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_data.freezed.dart';

/// Complete analytics data for dashboard
@freezed
class AnalyticsData with _$AnalyticsData {
  const factory AnalyticsData({
    /// Overview statistics (4 cards)
    required AnalyticsOverview overview,

    /// Monthly spending trends for line chart
    required List<MonthlySpending> spendingTrends,

    /// Spending by subscription for bar/pie charts
    required List<SubscriptionSpending> subscriptionSpending,

    /// Payment analytics insights
    required PaymentAnalytics paymentAnalytics,
  }) = _AnalyticsData;

  const AnalyticsData._();

  /// Create empty analytics data
  factory AnalyticsData.empty() => AnalyticsData(
        overview: AnalyticsOverview.empty(),
        spendingTrends: const [],
        subscriptionSpending: const [],
        paymentAnalytics: PaymentAnalytics.empty(),
      );

  /// Check if there is any analytics data to display
  bool get hasData =>
      overview.hasSubscriptions ||
      spendingTrends.isNotEmpty ||
      subscriptionSpending.isNotEmpty;

  /// Get total spending across all subscriptions
  double get totalSpending => subscriptionSpending.fold<double>(
        0,
        (sum, item) => sum + item.totalAmountPaid,
      );
}
