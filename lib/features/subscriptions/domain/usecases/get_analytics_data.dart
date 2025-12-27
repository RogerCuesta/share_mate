// lib/features/subscriptions/domain/usecases/get_analytics_data.dart

import 'package:dartz/dartz.dart';

import '../entities/analytics_data.dart';
import '../entities/time_range.dart';
import '../failures/subscription_failure.dart';
import '../repositories/subscription_repository.dart';

/// Use case: Get analytics data for dashboard
///
/// Fetches comprehensive analytics including:
/// - Overview stats (monthly cost, subscription count, members, average)
/// - Spending trends by month
/// - Spending by subscription
/// - Payment analytics (on-time rate, avg days, top payers, overdue)
class GetAnalyticsData {
  final SubscriptionRepository _repository;

  GetAnalyticsData(this._repository);

  /// Get analytics data for a specific user and time range
  Future<Either<SubscriptionFailure, AnalyticsData>> call({
    required String userId,
    required TimeRange timeRange,
  }) async {
    // Validate user ID
    if (userId.isEmpty) {
      return const Left(
        SubscriptionFailure.invalidData('User ID cannot be empty'),
      );
    }

    // Delegate to repository
    return _repository.getAnalyticsData(
      userId: userId,
      timeRange: timeRange,
    );
  }
}
