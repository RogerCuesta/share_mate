import 'package:dartz/dartz.dart';

import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to delete a subscription
///
/// Deletes a subscription and all associated member records.
class DeleteSubscription {
  final SubscriptionRepository _repository;

  DeleteSubscription(this._repository);

  /// Execute the use case
  ///
  /// [subscriptionId] - ID of the subscription to delete
  ///
  /// Returns [Unit] if successful.
  /// Returns [SubscriptionFailure.notFound] if subscription doesn't exist.
  /// Returns [SubscriptionFailure.invalidData] if ID is empty.
  Future<Either<SubscriptionFailure, Unit>> call(String subscriptionId) async {
    // Validate input
    if (subscriptionId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('Subscription ID cannot be empty'),
      );
    }

    // Delegate to repository
    return _repository.deleteSubscription(subscriptionId);
  }
}
