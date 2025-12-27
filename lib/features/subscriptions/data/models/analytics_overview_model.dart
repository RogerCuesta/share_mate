// lib/features/subscriptions/data/models/analytics_overview_model.dart

import '../../domain/entities/analytics_overview.dart';

/// Data model for AnalyticsOverview
class AnalyticsOverviewModel {
  final double totalMonthlyCost;
  final int totalActiveSubscriptions;
  final int totalMembers;
  final double averageCostPerSubscription;

  const AnalyticsOverviewModel({
    required this.totalMonthlyCost,
    required this.totalActiveSubscriptions,
    required this.totalMembers,
    required this.averageCostPerSubscription,
  });

  /// Convert to domain entity
  AnalyticsOverview toEntity() {
    return AnalyticsOverview(
      totalMonthlyCost: totalMonthlyCost,
      totalActiveSubscriptions: totalActiveSubscriptions,
      totalMembers: totalMembers,
      averageCostPerSubscription: averageCostPerSubscription,
    );
  }

  /// Create from domain entity
  factory AnalyticsOverviewModel.fromEntity(AnalyticsOverview entity) {
    return AnalyticsOverviewModel(
      totalMonthlyCost: entity.totalMonthlyCost,
      totalActiveSubscriptions: entity.totalActiveSubscriptions,
      totalMembers: entity.totalMembers,
      averageCostPerSubscription: entity.averageCostPerSubscription,
    );
  }

  /// Create from JSON
  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverviewModel(
      totalMonthlyCost: (json['total_monthly_cost'] as num).toDouble(),
      totalActiveSubscriptions: json['total_active_subscriptions'] as int,
      totalMembers: json['total_members'] as int,
      averageCostPerSubscription: (json['average_cost_per_subscription'] as num).toDouble(),
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'total_monthly_cost': totalMonthlyCost,
      'total_active_subscriptions': totalActiveSubscriptions,
      'total_members': totalMembers,
      'average_cost_per_subscription': averageCostPerSubscription,
    };
  }
}
