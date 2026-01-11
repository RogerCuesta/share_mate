// lib/features/subscriptions/data/models/analytics_data_model.dart

import 'package:flutter_project_agents/features/subscriptions/data/models/analytics_overview_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/monthly_spending_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_analytics_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_spending_model.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_data.dart';

/// Data model for AnalyticsData
class AnalyticsDataModel {

  const AnalyticsDataModel({
    required this.overview,
    required this.spendingTrends,
    required this.subscriptionSpending,
    required this.paymentAnalytics,
  });

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
  final AnalyticsOverviewModel overview;
  final List<MonthlySpendingModel> spendingTrends;
  final List<SubscriptionSpendingModel> subscriptionSpending;
  final PaymentAnalyticsModel paymentAnalytics;

  /// Convert to domain entity
  AnalyticsData toEntity() {
    return AnalyticsData(
      overview: overview.toEntity(),
      spendingTrends: spendingTrends.map((model) => model.toEntity()).toList(),
      subscriptionSpending: subscriptionSpending.map((model) => model.toEntity()).toList(),
      paymentAnalytics: paymentAnalytics.toEntity(),
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
