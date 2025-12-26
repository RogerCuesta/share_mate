// lib/features/subscriptions/presentation/providers/payment_stats_provider.dart

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
  print('📊 [PaymentStats] Fetching stats for: $subscriptionId');
  if (startDate != null || endDate != null) {
    print('   Date range: $startDate to $endDate');
  }

  final getPaymentStats = ref.watch(getPaymentStatsProvider);
  final result = await getPaymentStats(
    subscriptionId: subscriptionId,
    startDate: startDate,
    endDate: endDate,
  );

  return result.fold(
    (failure) {
      print('❌ [PaymentStats] Failed to fetch: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (stats) {
      print('✅ [PaymentStats] Stats retrieved:');
      print('   Total Payments: ${stats.totalPayments}');
      print('   Amount Paid: \$${stats.totalAmountPaid.toStringAsFixed(2)}');
      print('   Amount Unpaid: \$${stats.totalAmountUnpaid.toStringAsFixed(2)}');
      print('   Unique Payers: ${stats.uniquePayers}');
      print('   Payment Methods: ${stats.paymentMethods}');
      return stats;
    },
  );
}
