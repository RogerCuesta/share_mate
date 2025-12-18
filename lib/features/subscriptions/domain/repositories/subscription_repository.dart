import 'package:dartz/dartz.dart';

import '../entities/monthly_stats.dart';
import '../entities/subscription.dart';
import '../entities/subscription_member.dart';
import '../failures/subscription_failure.dart';

/// Repository interface for subscription operations
///
/// This interface defines all subscription-related data operations.
/// Implementations should handle both local (Hive) and remote (Supabase) data sources.
abstract class SubscriptionRepository {
  /// Get monthly statistics for a user
  ///
  /// Returns [MonthlyStats] containing total costs, pending collections, etc.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, MonthlyStats>> getMonthlyStats(
    String userId,
  );

  /// Get all active subscriptions for a user
  ///
  /// Returns a list of [Subscription] entities with status = active.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<Subscription>>> getActiveSubscriptions(
    String userId,
  );

  /// Get all subscriptions for a user (including cancelled/paused)
  ///
  /// Returns a list of all [Subscription] entities regardless of status.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<Subscription>>> getAllSubscriptions(
    String userId,
  );

  /// Get subscription by ID
  ///
  /// Returns [Subscription] entity if found.
  /// Returns [SubscriptionFailure.notFound] if subscription doesn't exist.
  Future<Either<SubscriptionFailure, Subscription>> getSubscriptionById(
    String subscriptionId,
  );

  /// Get pending payments for a user
  ///
  /// Returns a list of [SubscriptionMember] entities where hasPaid = false.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>> getPendingPayments(
    String userId,
  );

  /// Get all members for a specific subscription
  ///
  /// Returns a list of [SubscriptionMember] entities for the subscription.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>> getSubscriptionMembers(
    String subscriptionId,
  );

  /// Create a new subscription
  ///
  /// Creates a new [Subscription] entity.
  /// Returns the created subscription if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, Subscription>> createSubscription(
    Subscription subscription,
  );

  /// Update an existing subscription
  ///
  /// Updates a [Subscription] entity.
  /// Returns the updated subscription if successful.
  /// Returns [SubscriptionFailure.notFound] if subscription doesn't exist.
  Future<Either<SubscriptionFailure, Subscription>> updateSubscription(
    Subscription subscription,
  );

  /// Delete a subscription
  ///
  /// Deletes a subscription and all associated members.
  /// Returns [Unit] if successful.
  /// Returns [SubscriptionFailure.notFound] if subscription doesn't exist.
  Future<Either<SubscriptionFailure, Unit>> deleteSubscription(
    String subscriptionId,
  );

  /// Mark a member's payment as paid
  ///
  /// Updates a [SubscriptionMember] to mark payment as complete.
  /// Returns the updated member if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, SubscriptionMember>> markPaymentAsPaid({
    required String memberId,
    required DateTime paymentDate,
  });

  /// Add a member to a subscription
  ///
  /// Creates a new [SubscriptionMember] for the subscription.
  /// Returns the created member if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, SubscriptionMember>> addMemberToSubscription({
    required String subscriptionId,
    required String userId,
    required String userName,
    required String userEmail,
    String? userAvatar,
  });

  /// Remove a member from a subscription
  ///
  /// Deletes a [SubscriptionMember] from the subscription.
  /// Returns [Unit] if successful.
  /// Returns [SubscriptionFailure.notFound] if member doesn't exist.
  Future<Either<SubscriptionFailure, Unit>> removeMemberFromSubscription(
    String memberId,
  );
}
