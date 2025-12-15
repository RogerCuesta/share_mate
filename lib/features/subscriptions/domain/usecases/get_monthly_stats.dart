import 'package:dartz/dartz.dart';

import '../entities/monthly_stats.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case to get monthly statistics for a user's subscriptions
///
/// Returns [MonthlyStats] containing total costs, pending collections,
/// overdue payments, and other monthly metrics.
class GetMonthlyStats {
  final SubscriptionRepository _repository;

  GetMonthlyStats(this._repository);

  /// Execute the use case
  ///
  /// [userId] - ID of the user to get stats for
  ///
  /// Returns [MonthlyStats] if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, MonthlyStats>> call(String userId) async {
    // Validate input
    if (userId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('User ID cannot be empty'),
      );
    }

    // Delegate to repository
    return _repository.getMonthlyStats(userId);
  }
}
