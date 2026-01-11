// lib/features/subscriptions/domain/entities/payment_analytics.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_analytics.freezed.dart';

/// Payment analytics data for insights
@freezed
class PaymentAnalytics with _$PaymentAnalytics {
  const factory PaymentAnalytics({
    /// Percentage of payments made on or before due date
    required double onTimePaymentRate,

    /// Average days between due_date and payment_date
    /// Negative = early, Positive = late
    required double averageDaysToPayment,

    /// Top 3 most reliable payers by payment count
    required List<TopPayer> topPayers,

    /// Total amount overdue (unpaid members where due_date < now)
    required double overdueAmount,
  }) = _PaymentAnalytics;

  const PaymentAnalytics._();

  /// Create empty analytics
  factory PaymentAnalytics.empty() => const PaymentAnalytics(
        onTimePaymentRate: 0,
        averageDaysToPayment: 0,
        topPayers: [],
        overdueAmount: 0,
      );

  /// Check if there are any overdue payments
  bool get hasOverduePayments => overdueAmount > 0;

  /// Get on-time rate as formatted string (e.g., "95.5%")
  String get onTimeRateFormatted => '${onTimePaymentRate.toStringAsFixed(1)}%';

  /// Get average days as formatted string
  String get avgDaysFormatted {
    if (averageDaysToPayment == 0) return 'On time';
    if (averageDaysToPayment < 0) {
      return '${averageDaysToPayment.abs().toStringAsFixed(0)} days early';
    }
    return '${averageDaysToPayment.toStringAsFixed(0)} days late';
  }
}

/// Top payer data for analytics
@freezed
class TopPayer with _$TopPayer {
  const factory TopPayer({
    /// Member name
    required String memberName,

    /// Number of payments made
    required int paymentCount,

    /// Total amount paid
    required double totalPaid,
  }) = _TopPayer;

  const TopPayer._();

  /// Get formatted total paid (e.g., "$123.45")
  String get totalPaidFormatted => '\$${totalPaid.toStringAsFixed(2)}';
}
