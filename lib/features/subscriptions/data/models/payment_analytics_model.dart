// lib/features/subscriptions/data/models/payment_analytics_model.dart

import '../../domain/entities/payment_analytics.dart';

/// Data model for PaymentAnalytics
class PaymentAnalyticsModel {
  final double onTimePaymentRate;
  final double averageDaysToPayment;
  final List<TopPayerModel> topPayers;
  final double overdueAmount;

  const PaymentAnalyticsModel({
    required this.onTimePaymentRate,
    required this.averageDaysToPayment,
    required this.topPayers,
    required this.overdueAmount,
  });

  /// Convert to domain entity
  PaymentAnalytics toEntity() {
    return PaymentAnalytics(
      onTimePaymentRate: onTimePaymentRate,
      averageDaysToPayment: averageDaysToPayment,
      topPayers: topPayers.map((m) => m.toEntity()).toList(),
      overdueAmount: overdueAmount,
    );
  }

  /// Create from domain entity
  factory PaymentAnalyticsModel.fromEntity(PaymentAnalytics entity) {
    return PaymentAnalyticsModel(
      onTimePaymentRate: entity.onTimePaymentRate,
      averageDaysToPayment: entity.averageDaysToPayment,
      topPayers: entity.topPayers.map((e) => TopPayerModel.fromEntity(e)).toList(),
      overdueAmount: entity.overdueAmount,
    );
  }

  /// Create from JSON
  factory PaymentAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return PaymentAnalyticsModel(
      onTimePaymentRate: (json['on_time_payment_rate'] as num).toDouble(),
      averageDaysToPayment: (json['average_days_to_payment'] as num).toDouble(),
      topPayers: (json['top_payers'] as List<dynamic>)
          .map((e) => TopPayerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      overdueAmount: (json['overdue_amount'] as num).toDouble(),
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'on_time_payment_rate': onTimePaymentRate,
      'average_days_to_payment': averageDaysToPayment,
      'top_payers': topPayers.map((e) => e.toJson()).toList(),
      'overdue_amount': overdueAmount,
    };
  }
}

/// Data model for TopPayer
class TopPayerModel {
  final String memberName;
  final int paymentCount;
  final double totalPaid;

  const TopPayerModel({
    required this.memberName,
    required this.paymentCount,
    required this.totalPaid,
  });

  /// Convert to domain entity
  TopPayer toEntity() {
    return TopPayer(
      memberName: memberName,
      paymentCount: paymentCount,
      totalPaid: totalPaid,
    );
  }

  /// Create from domain entity
  factory TopPayerModel.fromEntity(TopPayer entity) {
    return TopPayerModel(
      memberName: entity.memberName,
      paymentCount: entity.paymentCount,
      totalPaid: entity.totalPaid,
    );
  }

  /// Create from JSON
  factory TopPayerModel.fromJson(Map<String, dynamic> json) {
    return TopPayerModel(
      memberName: json['member_name'] as String,
      paymentCount: json['payment_count'] as int,
      totalPaid: (json['total_paid'] as num).toDouble(),
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'member_name': memberName,
      'payment_count': paymentCount,
      'total_paid': totalPaid,
    };
  }
}
