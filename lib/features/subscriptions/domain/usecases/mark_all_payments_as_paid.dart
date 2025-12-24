import 'package:dartz/dartz.dart';

import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to mark all pending payments as paid for a subscription
///
/// Creates payment history records for all members with pending payments
/// in a subscription. This is a bulk operation for convenience when all
/// members have paid their share.
class MarkAllPaymentsAsPaid {
  final SubscriptionRepository _repository;

  MarkAllPaymentsAsPaid(this._repository);

  /// Execute the use case
  ///
  /// [subscriptionId] - ID of the subscription
  /// [paymentDate] - Date when the payments were made (optional, defaults to now)
  /// [markedBy] - ID of the user marking these payments (usually the owner)
  /// [notes] - Optional notes about the bulk payment operation
  ///
  /// Returns the count of payments marked if successful.
  /// Returns [SubscriptionFailure] if validation or operation fails.
  Future<Either<SubscriptionFailure, int>> call({
    required String subscriptionId,
    DateTime? paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    // Validate subscription ID
    if (subscriptionId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Subscription ID cannot be empty'),
      );
    }

    // Validate markedBy
    if (markedBy.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Marked by user ID cannot be empty'),
      );
    }

    final effectivePaymentDate = paymentDate ?? DateTime.now();

    // Validate payment date is not in the future
    if (effectivePaymentDate.isAfter(DateTime.now())) {
      return const Left(
        SubscriptionFailure.invalidData('Payment date cannot be in the future'),
      );
    }

    // Delegate to repository
    return _repository.markAllPaymentsAsPaid(
      subscriptionId: subscriptionId,
      paymentDate: effectivePaymentDate,
      markedBy: markedBy,
      notes: notes,
    );
  }
}
