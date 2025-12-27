// lib/features/subscriptions/data/models/subscription_spending_model.dart

import '../../domain/entities/subscription_spending.dart';

/// Data model for SubscriptionSpending
class SubscriptionSpendingModel {
  final String subscriptionId;
  final String subscriptionName;
  final double totalAmountPaid;
  final int paymentCount;
  final String color;

  const SubscriptionSpendingModel({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.totalAmountPaid,
    required this.paymentCount,
    required this.color,
  });

  /// Convert to domain entity
  SubscriptionSpending toEntity() {
    return SubscriptionSpending(
      subscriptionId: subscriptionId,
      subscriptionName: subscriptionName,
      totalAmountPaid: totalAmountPaid,
      paymentCount: paymentCount,
      color: color,
    );
  }

  /// Create from domain entity
  factory SubscriptionSpendingModel.fromEntity(SubscriptionSpending entity) {
    return SubscriptionSpendingModel(
      subscriptionId: entity.subscriptionId,
      subscriptionName: entity.subscriptionName,
      totalAmountPaid: entity.totalAmountPaid,
      paymentCount: entity.paymentCount,
      color: entity.color,
    );
  }

  /// Create from JSON (aggregated data)
  factory SubscriptionSpendingModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionSpendingModel(
      subscriptionId: json['subscription_id'] as String,
      subscriptionName: json['subscription_name'] as String,
      totalAmountPaid: (json['total_amount_paid'] as num).toDouble(),
      paymentCount: json['payment_count'] as int,
      color: json['color'] as String,
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'subscription_id': subscriptionId,
      'subscription_name': subscriptionName,
      'total_amount_paid': totalAmountPaid,
      'payment_count': paymentCount,
      'color': color,
    };
  }
}
