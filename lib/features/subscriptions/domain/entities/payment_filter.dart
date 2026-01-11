// lib/features/subscriptions/domain/entities/payment_filter.dart

import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_filter.freezed.dart';

/// Value object for filtering payment history records
///
/// Provides flexible filtering options for payment history queries:
/// - Search by member name
/// - Filter by payment action (paid/unpaid)
/// - Filter by date range
/// - Filter by payment method
@freezed
class PaymentFilter with _$PaymentFilter {
  const factory PaymentFilter({
    /// Filter by member name (case-insensitive partial match)
    String? memberName,

    /// Filter by payment action (paid or unpaid)
    PaymentAction? action,

    /// Filter by payment date range (inclusive start date)
    DateTime? startDate,

    /// Filter by payment date range (inclusive end date)
    DateTime? endDate,

    /// Filter by payment method ('cash', 'transfer', 'card', etc.)
    String? paymentMethod,
  }) = _PaymentFilter;

  const PaymentFilter._();

  /// Factory for creating a filter with no active filters (show all)
  factory PaymentFilter.none() => const PaymentFilter();

  /// Factory for filtering only paid payments
  factory PaymentFilter.paidOnly() => const PaymentFilter(
        action: PaymentAction.paid,
      );

  /// Factory for filtering only unpaid payments
  factory PaymentFilter.unpaidOnly() => const PaymentFilter(
        action: PaymentAction.unpaid,
      );

  /// Factory for filtering by date range
  factory PaymentFilter.dateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      PaymentFilter(
        startDate: startDate,
        endDate: endDate,
      );

  /// Factory for filtering by this month
  factory PaymentFilter.thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return PaymentFilter(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Factory for filtering by last 30 days
  factory PaymentFilter.last30Days() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return PaymentFilter(
      startDate: thirtyDaysAgo,
      endDate: now,
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      memberName != null ||
      action != null ||
      startDate != null ||
      endDate != null ||
      paymentMethod != null;

  /// Get count of active filters
  int get activeFilterCount {
    var count = 0;
    if (memberName != null && memberName!.isNotEmpty) count++;
    if (action != null) count++;
    if (startDate != null || endDate != null) count++;
    if (paymentMethod != null) count++;
    return count;
  }

  /// Get human-readable description of active filters
  String get description {
    if (!hasActiveFilters) return 'All payments';

    final filters = <String>[];

    if (memberName != null && memberName!.isNotEmpty) {
      filters.add('Name: "$memberName"');
    }

    if (action != null) {
      filters.add(action == PaymentAction.paid ? 'Paid only' : 'Unpaid only');
    }

    if (startDate != null && endDate != null) {
      filters.add(
        'Date: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
      );
    } else if (startDate != null) {
      filters.add('After: ${_formatDate(startDate!)}');
    } else if (endDate != null) {
      filters.add('Before: ${_formatDate(endDate!)}');
    }

    if (paymentMethod != null) {
      filters.add('Method: $paymentMethod');
    }

    return filters.join(' • ');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
