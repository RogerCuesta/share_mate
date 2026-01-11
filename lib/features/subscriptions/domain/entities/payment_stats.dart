// lib/features/subscriptions/domain/entities/payment_stats.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_stats.freezed.dart';

/// Value object for payment history statistics
///
/// Provides aggregated analytics for payment history:
/// - Total count of payments
/// - Total amounts (paid vs unpaid)
/// - Unique payer count
/// - Payment method breakdown
@freezed
class PaymentStats with _$PaymentStats {
  const factory PaymentStats({
    /// Total number of 'paid' actions in history
    required int totalPayments,

    /// Sum of all amounts with action='paid'
    required double totalAmountPaid,

    /// Sum of all amounts with action='unpaid'
    required double totalAmountUnpaid,

    /// Count of unique members who have made payments
    required int uniquePayers,

    /// Breakdown of payment methods: {'cash': 5, 'transfer': 3, 'card': 2}
    required Map<String, int> paymentMethods,
  }) = _PaymentStats;

  const PaymentStats._();

  /// Factory for empty stats (no payment history)
  factory PaymentStats.empty() => const PaymentStats(
        totalPayments: 0,
        totalAmountPaid: 0,
        totalAmountUnpaid: 0,
        uniquePayers: 0,
        paymentMethods: {},
      );

  /// Calculate net amount (paid - unpaid)
  double get netAmount => totalAmountPaid - totalAmountUnpaid;

  /// Check if there are any payments
  bool get hasPayments => totalPayments > 0;

  /// Get most used payment method
  String? get mostUsedPaymentMethod {
    if (paymentMethods.isEmpty) return null;

    var maxCount = 0;
    String? maxMethod;

    for (final entry in paymentMethods.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxMethod = entry.key;
      }
    }

    return maxMethod;
  }

  /// Get payment method usage percentage
  double getPaymentMethodPercentage(String method) {
    if (totalPayments == 0 || !paymentMethods.containsKey(method)) {
      return 0;
    }

    return (paymentMethods[method]! / totalPayments) * 100;
  }

  /// Get human-readable summary
  String get summary {
    if (!hasPayments) return 'No payments recorded yet';

    return '$totalPayments payments • \$${totalAmountPaid.toStringAsFixed(2)} collected';
  }
}
