import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Use case to mark a single member's payment as paid
///
/// Creates a payment history record when a subscription member's payment
/// is marked as paid. This provides an audit trail for all payment actions.
class MarkPaymentAsPaid {

  MarkPaymentAsPaid(this._repository);
  final SubscriptionRepository _repository;

  /// Execute the use case
  ///
  /// [subscriptionId] - ID of the subscription
  /// [memberId] - ID of the subscription member
  /// [amount] - Amount that was paid
  /// [paymentDate] - Date when the payment was made (optional, defaults to now)
  /// [markedBy] - ID of the user marking this payment (usually the owner)
  /// [notes] - Optional notes about the payment
  ///
  /// Returns created [PaymentHistory] entity if successful.
  /// Returns [SubscriptionFailure] if validation or creation fails.
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
    return _repository.markPaymentAsPaid(
      subscriptionId: subscriptionId,
      memberId: memberId,
      amount: amount,
      paymentDate: effectivePaymentDate,
      markedBy: markedBy,
      notes: notes,
    );
  }
}
