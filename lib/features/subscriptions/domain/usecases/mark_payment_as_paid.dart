import 'package:dartz/dartz.dart';

import '../entities/subscription_member.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to mark a member's payment as paid
///
/// Updates a subscription member's payment status to paid.
class MarkPaymentAsPaid {
  final SubscriptionRepository _repository;

  MarkPaymentAsPaid(this._repository);

  /// Execute the use case
  ///
  /// [memberId] - ID of the subscription member
  /// [paymentDate] - Date when the payment was made (optional, defaults to now)
  ///
  /// Returns updated [SubscriptionMember] entity if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, SubscriptionMember>> call({
    required String memberId,
    DateTime? paymentDate,
  }) async {
    // Validate input
    if (memberId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Member ID cannot be empty'),
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
      memberId: memberId,
      paymentDate: effectivePaymentDate,
    );
  }
}
