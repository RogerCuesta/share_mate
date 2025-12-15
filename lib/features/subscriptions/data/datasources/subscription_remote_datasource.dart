import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../models/monthly_stats_model.dart';
import '../models/subscription_member_model.dart';
import '../models/subscription_model.dart';

/// Exception thrown when subscription remote operations fail
class SubscriptionRemoteException implements Exception {
  final String message;
  SubscriptionRemoteException(this.message);

  @override
  String toString() => 'SubscriptionRemoteException: $message';
}

/// Remote data source for subscription operations using Supabase
abstract class SubscriptionRemoteDataSource {
  /// Get all subscriptions for a user
  Future<List<SubscriptionModel>> getSubscriptions(String userId);

  /// Get subscription by ID
  Future<SubscriptionModel> getSubscriptionById(String subscriptionId);

  /// Get all members for subscriptions owned by user
  Future<List<SubscriptionMemberModel>> getMembers(String userId);

  /// Get members for a specific subscription
  Future<List<SubscriptionMemberModel>> getSubscriptionMembers(
    String subscriptionId,
  );

  /// Calculate monthly statistics for user
  Future<MonthlyStatsModel> calculateMonthlyStats(String userId);

  /// Create a new subscription
  Future<SubscriptionModel> createSubscription(SubscriptionModel subscription);

  /// Update a subscription
  Future<SubscriptionModel> updateSubscription(SubscriptionModel subscription);

  /// Delete a subscription
  Future<void> deleteSubscription(String subscriptionId);

  /// Update payment status for a member
  Future<SubscriptionMemberModel> updatePaymentStatus({
    required String memberId,
    required bool hasPaid,
    DateTime? paymentDate,
  });

  /// Add a member to a subscription
  Future<SubscriptionMemberModel> addMember(SubscriptionMemberModel member);

  /// Remove a member from a subscription
  Future<void> removeMember(String memberId);
}

/// Implementation of SubscriptionRemoteDataSource using Supabase
class SubscriptionRemoteDataSourceImpl
    implements SubscriptionRemoteDataSource {
  final SupabaseClient _client;

  SubscriptionRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  @override
  Future<List<SubscriptionModel>> getSubscriptions(String userId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => SubscriptionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to fetch subscriptions: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String subscriptionId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', subscriptionId)
          .single();

      return SubscriptionModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to fetch subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionMemberModel>> getMembers(String userId) async {
    try {
      // First, get all subscriptions owned by the user
      final subscriptions = await getSubscriptions(userId);
      final subscriptionIds = subscriptions.map((s) => s.id).toList();

      if (subscriptionIds.isEmpty) {
        return [];
      }

      // Then, get all members for those subscriptions
      final response = await _client
          .from('subscription_members')
          .select()
          .inFilter('subscription_id', subscriptionIds)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to fetch members: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionMemberModel>> getSubscriptionMembers(
    String subscriptionId,
  ) async {
    try {
      final response = await _client
          .from('subscription_members')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to fetch subscription members: ${e.toString()}',
      );
    }
  }

  @override
  Future<MonthlyStatsModel> calculateMonthlyStats(String userId) async {
    try {
      // Get all active subscriptions
      final subscriptions = await getSubscriptions(userId);
      final activeSubscriptions = subscriptions
          .where((s) => s.status == 'active')
          .toList();

      // Get all members
      final members = await getMembers(userId);

      // Calculate stats
      final totalMonthlyCost = activeSubscriptions.fold<double>(
        0.0,
        (sum, sub) {
          // Convert yearly to monthly if needed
          final monthlyCost = sub.billingCycle == 'yearly'
              ? sub.totalCost / 12
              : sub.totalCost;
          return sum + monthlyCost;
        },
      );

      final now = DateTime.now();
      final unpaidMembers = members.where((m) => !m.hasPaid).toList();
      final paidMembers = members.where((m) => m.hasPaid).toList();

      final pendingToCollect = unpaidMembers.fold<double>(
        0.0,
        (sum, member) => sum + member.amountToPay,
      );

      final collectedAmount = paidMembers.fold<double>(
        0.0,
        (sum, member) => sum + member.amountToPay,
      );

      final overduePaymentsCount = unpaidMembers
          .where((m) => m.dueDate.isBefore(now))
          .length;

      return MonthlyStatsModel(
        totalMonthlyCost: totalMonthlyCost,
        pendingToCollect: pendingToCollect,
        activeSubscriptionsCount: activeSubscriptions.length,
        overduePaymentsCount: overduePaymentsCount,
        collectedAmount: collectedAmount,
        paidMembersCount: paidMembers.length,
        unpaidMembersCount: unpaidMembers.length,
      );
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to calculate monthly stats: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionModel> createSubscription(
    SubscriptionModel subscription,
  ) async {
    try {
      final response = await _client
          .from('subscriptions')
          .insert(subscription.toJson())
          .select()
          .single();

      return SubscriptionModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to create subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionModel> updateSubscription(
    SubscriptionModel subscription,
  ) async {
    try {
      final response = await _client
          .from('subscriptions')
          .update(subscription.toJson())
          .eq('id', subscription.id)
          .select()
          .single();

      return SubscriptionModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to update subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      // Delete members first (cascade delete)
      await _client
          .from('subscription_members')
          .delete()
          .eq('subscription_id', subscriptionId);

      // Then delete subscription
      await _client.from('subscriptions').delete().eq('id', subscriptionId);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to delete subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionMemberModel> updatePaymentStatus({
    required String memberId,
    required bool hasPaid,
    DateTime? paymentDate,
  }) async {
    try {
      final updateData = {
        'has_paid': hasPaid,
        if (paymentDate != null)
          'last_payment_date': paymentDate.toIso8601String(),
      };

      final response = await _client
          .from('subscription_members')
          .update(updateData)
          .eq('id', memberId)
          .select()
          .single();

      return SubscriptionMemberModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to update payment status: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionMemberModel> addMember(
    SubscriptionMemberModel member,
  ) async {
    try {
      final response = await _client
          .from('subscription_members')
          .insert(member.toJson())
          .select()
          .single();

      return SubscriptionMemberModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to add member: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> removeMember(String memberId) async {
    try {
      await _client.from('subscription_members').delete().eq('id', memberId);
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to remove member: ${e.toString()}',
      );
    }
  }
}
