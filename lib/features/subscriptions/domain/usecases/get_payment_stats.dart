// lib/features/subscriptions/domain/usecases/get_payment_stats.dart

import 'package:dartz/dartz.dart';

import '../entities/payment_stats.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case for retrieving payment statistics for a subscription
///
/// Retrieves aggregated analytics including:
/// - Total payment count
/// - Total amounts (paid vs unpaid)
/// - Unique payer count
/// - Payment method breakdown
///
/// Optional date range filters can be applied to analyze specific periods.
class GetPaymentStats {
  final SubscriptionRepository _repository;

  GetPaymentStats(this._repository);

  /// Execute the use case
  ///
  /// Returns [PaymentStats] with aggregated data if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, PaymentStats>> call({
    required String subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getPaymentStats(
      subscriptionId: subscriptionId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
