import 'package:dartz/dartz.dart';

import '../entities/monthly_stats.dart';
import '../entities/payment_history.dart';
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
  /// Creates a [PaymentHistory] record and updates the [SubscriptionMember].
  /// Returns the created payment history if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, PaymentHistory>> markPaymentAsPaid({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  });

  /// Mark all pending payments as paid for a subscription
  ///
  /// Creates [PaymentHistory] records for all unpaid members in a subscription.
  /// Returns the count of payments marked if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, int>> markAllPaymentsAsPaid({
    required String subscriptionId,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  });

  /// Unmark a payment (undo a paid status)
  ///
  /// Creates a new [PaymentHistory] record with unpaid action and updates the member.
  /// Returns the created payment history if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, PaymentHistory>> unmarkPayment({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  });

  /// Get payment history for a subscription
  ///
  /// Returns a list of [PaymentHistory] records for the subscription.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, List<PaymentHistory>>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
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

  /// Update member amount and optionally reset payment status
  ///
  /// Updates a [SubscriptionMember]'s amount to pay and optionally resets payment status.
  /// Used when editing subscriptions to recalculate splits.
  /// Returns the updated member if successful.
  /// Returns [SubscriptionFailure] if operation fails.
  Future<Either<SubscriptionFailure, SubscriptionMember>> updateMemberAmount({
    required String memberId,
    required double newAmountToPay,
    bool resetPayment = false,
  });
}
