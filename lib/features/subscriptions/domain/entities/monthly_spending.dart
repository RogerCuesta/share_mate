// lib/features/subscriptions/domain/entities/monthly_spending.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'monthly_spending.freezed.dart';

/// Monthly spending data for analytics trends chart
@freezed
class MonthlySpending with _$MonthlySpending {
  const factory MonthlySpending({
    /// First day of the month
    required DateTime month,

    /// Total amount paid in this month (sum of payment_history WHERE action='paid')
    required double amountPaid,

    /// Number of payments made in this month
    required int paymentCount,
  }) = _MonthlySpending;

  const MonthlySpending._();

  /// Get formatted month label (e.g., "Jan 2024")
  String get monthLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  /// Get short month label for charts (e.g., "Jan")
  String get shortMonthLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month.month - 1];
  }
}
