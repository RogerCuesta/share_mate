// lib/features/subscriptions/data/models/analytics_data_model.dart

import '../../domain/entities/analytics_data.dart';
import 'analytics_overview_model.dart';
import 'monthly_spending_model.dart';
import 'payment_analytics_model.dart';
import 'subscription_spending_model.dart';

/// Data model for AnalyticsData
class AnalyticsDataModel {
  final AnalyticsOverviewModel overview;
  final List<MonthlySpendingModel> spendingTrends;
  final List<SubscriptionSpendingModel> subscriptionSpending;
  final PaymentAnalyticsModel paymentAnalytics;

  const AnalyticsDataModel({
    required this.overview,
    required this.spendingTrends,
    required this.subscriptionSpending,
    required this.paymentAnalytics,
  });

  /// Convert to domain entity
  AnalyticsData toEntity() {
    return AnalyticsData(
      overview: overview.toEntity(),
      spendingTrends: spendingTrends.map((model) => model.toEntity()).toList(),
      subscriptionSpending: subscriptionSpending.map((model) => model.toEntity()).toList(),
      paymentAnalytics: paymentAnalytics.toEntity(),
    );
  }

  /// Create from domain entity
  factory AnalyticsDataModel.fromEntity(AnalyticsData entity) {
    return AnalyticsDataModel(
      overview: AnalyticsOverviewModel.fromEntity(entity.overview),
      spendingTrends: entity.spendingTrends
          .map((spending) => MonthlySpendingModel.fromEntity(spending))
          .toList(),
      subscriptionSpending: entity.subscriptionSpending
          .map((spending) => SubscriptionSpendingModel.fromEntity(spending))
          .toList(),
      paymentAnalytics: PaymentAnalyticsModel.fromEntity(entity.paymentAnalytics),
    );
  }

  /// Create from JSON
  factory AnalyticsDataModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsDataModel(
      overview: AnalyticsOverviewModel.fromJson(json['overview'] as Map<String, dynamic>),
      spendingTrends: (json['spending_trends'] as List<dynamic>)
          .map((item) => MonthlySpendingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subscriptionSpending: (json['subscription_spending'] as List<dynamic>)
          .map((item) => SubscriptionSpendingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      paymentAnalytics: PaymentAnalyticsModel.fromJson(json['payment_analytics'] as Map<String, dynamic>),
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'overview': overview.toJson(),
      'spending_trends': spendingTrends.map((model) => model.toJson()).toList(),
      'subscription_spending': subscriptionSpending.map((model) => model.toJson()).toList(),
      'payment_analytics': paymentAnalytics.toJson(),
    };
  }
}
