import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Use case to get all pending payments for a user
///
/// Returns a list of subscription members who haven't paid yet.
class GetPendingPayments {

  GetPendingPayments(this._repository);
  final SubscriptionRepository _repository;

  /// Execute the use case
  ///
  /// [userId] - ID of the user to get pending payments for
  ///
  /// Returns list of [SubscriptionMember] entities with unpaid status.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>> call(
    String userId,
  ) async {
    // Validate input
    if (userId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('User ID cannot be empty'),
      );
    }

    // Delegate to repository
    return _repository.getPendingPayments(userId);
  }
}
