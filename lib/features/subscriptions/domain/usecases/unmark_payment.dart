import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Use case to unmark a payment (undo a paid status)
///
/// Creates a payment history record with unpaid action when a payment
/// needs to be unmarked. This provides undo functionality and maintains
/// a complete audit trail of all payment status changes.
class UnmarkPayment {

  UnmarkPayment(this._repository);
  final SubscriptionRepository _repository;

  /// Execute the use case
  ///
  /// [subscriptionId] - ID of the subscription
  /// [memberId] - ID of the subscription member
  /// [amount] - Amount that was previously marked as paid
  /// [paymentDate] - Date when the unmark action occurred (optional, defaults to now)
  /// [markedBy] - ID of the user unmarking this payment (usually the owner)
  /// [notes] - Optional notes about why the payment is being unmarked
  ///
  /// Returns created [PaymentHistory] entity with unpaid action if successful.
  /// Returns [SubscriptionFailure] if validation or operation fails.
  Future<Either<SubscriptionFailure, PaymentHistory>> call({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy, DateTime? paymentDate,
    String? notes,
  }) async {
    // Validate subscription ID
    if (subscriptionId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Subscription ID cannot be empty'),
      );
    }

    // Validate member ID
    if (memberId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Member ID cannot be empty'),
      );
    }

    // Validate amount
    if (amount <= 0) {
      return const Left(
        SubscriptionFailure.invalidData('Payment amount must be greater than zero'),
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
    return _repository.unmarkPayment(
      subscriptionId: subscriptionId,
      memberId: memberId,
      amount: amount,
      paymentDate: effectivePaymentDate,
      markedBy: markedBy,
      notes: notes,
    );
  }
}
