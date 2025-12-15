import 'package:dartz/dartz.dart';

import '../entities/subscription.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to create a new subscription
///
/// Validates subscription data and creates a new subscription entity.
class CreateSubscription {
  final SubscriptionRepository _repository;

  CreateSubscription(this._repository);

  /// Execute the use case
  ///
  /// [subscription] - The subscription entity to create
  ///
  /// Returns created [Subscription] entity if successful.
  /// Returns [SubscriptionFailure] if validation or creation fails.
  Future<Either<SubscriptionFailure, Subscription>> call(
    Subscription subscription,
  ) async {
    // Validate subscription data
    final validationError = _validateSubscription(subscription);
    if (validationError != null) {
      return Left(SubscriptionFailure.invalidData(validationError));
    }

    // Delegate to repository
    return _repository.createSubscription(subscription);
  }

  /// Validate subscription business rules
  String? _validateSubscription(Subscription subscription) {
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

    if (subscription.dueDate.isBefore(DateTime.now())) {
      return 'Due date cannot be in the past';
    }

    // Validate hex color format
    final colorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!colorRegex.hasMatch(subscription.color)) {
      return 'Invalid color format (expected hex color like #FF0000)';
    }

    return null;
  }
}
