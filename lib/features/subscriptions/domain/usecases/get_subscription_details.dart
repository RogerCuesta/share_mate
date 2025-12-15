import 'package:dartz/dartz.dart';

import '../entities/subscription.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to get details of a specific subscription
///
/// Returns full subscription information including members and payment status.
class GetSubscriptionDetails {
  final SubscriptionRepository _repository;

  GetSubscriptionDetails(this._repository);

  /// Execute the use case
  ///
  /// [subscriptionId] - ID of the subscription to retrieve
  ///
  /// Returns [Subscription] entity if successful.
  /// Returns [SubscriptionFailure.notFound] if subscription doesn't exist.
  Future<Either<SubscriptionFailure, Subscription>> call(
    String subscriptionId,
  ) async {
    // Validate input
    if (subscriptionId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Subscription ID cannot be empty'),
      );
    }

    // Delegate to repository
    return _repository.getSubscriptionById(subscriptionId);
  }
}
