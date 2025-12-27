// lib/features/subscriptions/domain/entities/analytics_overview.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_overview.freezed.dart';

/// Overview statistics for analytics dashboard
@freezed
class AnalyticsOverview with _$AnalyticsOverview {
  const factory AnalyticsOverview({
    /// Total monthly cost (sum of all active subscriptions normalized to monthly)
    required double totalMonthlyCost,

    /// Number of active subscriptions
    required int totalActiveSubscriptions,

    /// Total number of members across all subscriptions
    required int totalMembers,

    /// Average cost per subscription
    required double averageCostPerSubscription,
  }) = _AnalyticsOverview;

  const AnalyticsOverview._();

  /// Create empty overview
  factory AnalyticsOverview.empty() => const AnalyticsOverview(
        totalMonthlyCost: 0,
        totalActiveSubscriptions: 0,
        totalMembers: 0,
        averageCostPerSubscription: 0,
      );

  /// Check if there are any active subscriptions
  bool get hasSubscriptions => totalActiveSubscriptions > 0;

  /// Get formatted monthly cost (e.g., "$123.45")
  String get monthlyCostFormatted => '\$${totalMonthlyCost.toStringAsFixed(2)}';

  /// Get formatted average cost (e.g., "$12.34")
  String get avgCostFormatted =>
      '\$${averageCostPerSubscription.toStringAsFixed(2)}';
}
