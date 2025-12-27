// lib/features/subscriptions/data/models/monthly_spending_model.dart

import '../../domain/entities/monthly_spending.dart';

/// Data model for MonthlySpending
class MonthlySpendingModel {
  final DateTime month;
  final double amountPaid;
  final int paymentCount;

  const MonthlySpendingModel({
    required this.month,
    required this.amountPaid,
    required this.paymentCount,
  });

  /// Convert to domain entity
  MonthlySpending toEntity() {
    return MonthlySpending(
      month: month,
      amountPaid: amountPaid,
      paymentCount: paymentCount,
    );
  }

  /// Create from domain entity
  factory MonthlySpendingModel.fromEntity(MonthlySpending entity) {
    return MonthlySpendingModel(
      month: entity.month,
      amountPaid: entity.amountPaid,
      paymentCount: entity.paymentCount,
    );
  }

  /// Create from JSON (used when fetching from Supabase)
  factory MonthlySpendingModel.fromJson(Map<String, dynamic> json) {
    return MonthlySpendingModel(
      month: json['month'] is DateTime
          ? json['month'] as DateTime
          : DateTime.parse(json['month'] as String),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      paymentCount: json['payment_count'] as int,
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'amount_paid': amountPaid,
      'payment_count': paymentCount,
    };
  }
}
