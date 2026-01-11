import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';

/// Use case to get all active subscriptions for a user
///
/// Returns a list of subscriptions with status = active.
class GetActiveSubscriptions {

  GetActiveSubscriptions(this._repository);
  final SubscriptionRepository _repository;

  /// Execute the use case
  ///
  /// [userId] - ID of the user to get subscriptions for
  ///
  /// Returns list of [Subscription] entities if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<Subscription>>> call(
    String userId,
  ) async {
    // Validate input
    if (userId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('User ID cannot be empty'),
      );
    }

    // Delegate to repository
    return _repository.getActiveSubscriptions(userId);
  }
}
