import 'package:dartz/dartz.dart';

import '../entities/subscription.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to update an existing subscription
///
/// Validates subscription data and updates the subscription entity.
class UpdateSubscription {
  final SubscriptionRepository _repository;

  UpdateSubscription(this._repository);

  /// Execute the use case
  ///
  /// [subscription] - The subscription entity with updated data
  ///
  /// Returns updated [Subscription] entity if successful.
  /// Returns [SubscriptionFailure.notFound] if subscription doesn't exist.
  /// Returns [SubscriptionFailure.invalidData] if validation fails.
  Future<Either<SubscriptionFailure, Subscription>> call(
    Subscription subscription,
  ) async {
    // Validate subscription data
    final validationError = _validateSubscription(subscription);
    if (validationError != null) {
      return Left(SubscriptionFailure.invalidData(validationError));
    }

    // Delegate to repository
    return _repository.updateSubscription(subscription);
  }

  /// Validate subscription business rules
  String? _validateSubscription(Subscription subscription) {
    if (subscription.id.isEmpty) {
      return 'Subscription ID cannot be empty';
    }

    if (subscription.name.isEmpty) {
      return 'Subscription name cannot be empty';
    }

    if (subscription.name.length < 2) {
      return 'Subscription name must be at least 2 characters';
    }

    if (subscription.totalCost <= 0) {
      return 'Subscription cost must be greater than zero';
    }

    if (subscription.ownerId.isEmpty) {
      return 'Owner ID cannot be empty';
    }

    // Validate hex color format
    final colorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!colorRegex.hasMatch(subscription.color)) {
      return 'Invalid color format (expected hex color like #FF0000)';
    }

    return null;
  }
}
