// lib/features/subscriptions/presentation/providers/payment_stats_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_stats.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_stats_provider.g.dart';

/// Provider for fetching payment statistics for a subscription
///
/// Retrieves aggregated analytics including:
/// - Total payment count
/// - Total amounts (paid vs unpaid)
/// - Unique payer count
/// - Payment method breakdown
///
/// Returns a [PaymentStats] entity if successful.
/// Throws [SubscriptionFailure] if operation fails (handled by AsyncValue).
///
/// Auto-disposes when not in use.
/// Uses family pattern with subscriptionId parameter.
@riverpod
Future<PaymentStats> paymentStats(
  PaymentStatsRef ref,
  String subscriptionId, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  debugPrint('📊 [PaymentStats] Fetching stats for: $subscriptionId');
  if (startDate != null || endDate != null) {
    debugPrint('   Date range: $startDate to $endDate');
  }

  final getPaymentStats = ref.watch(getPaymentStatsProvider);
  final result = await getPaymentStats(
    subscriptionId: subscriptionId,
    startDate: startDate,
    endDate: endDate,
  );

  return result.fold(
    (failure) {
      debugPrint('❌ [PaymentStats] Failed to fetch: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (stats) {
      debugPrint('✅ [PaymentStats] Stats retrieved:');
      debugPrint('   Total Payments: ${stats.totalPayments}');
      debugPrint('   Amount Paid: \$${stats.totalAmountPaid.toStringAsFixed(2)}');
      debugPrint('   Amount Unpaid: \$${stats.totalAmountUnpaid.toStringAsFixed(2)}');
      debugPrint('   Unique Payers: ${stats.uniquePayers}');
      debugPrint('   Payment Methods: ${stats.paymentMethods}');
      return stats;
    },
  );
}
