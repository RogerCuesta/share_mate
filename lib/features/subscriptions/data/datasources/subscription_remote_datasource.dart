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
      print('🔍 [SubscriptionRemoteDS] Fetching subscriptions for user: $userId');

      // 1. Fetch subscriptions
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      print('📦 [SubscriptionRemoteDS] Supabase response: ${response.length} subscriptions');

      final List<dynamic> data = response as List<dynamic>;
      final subscriptions = <SubscriptionModel>[];

      // 2. For each subscription, fetch members and populate sharedWith
      for (var json in data) {
        final subscriptionId = json['id'] as String;
        print('   📋 Processing subscription: ${json['name']} (ID: $subscriptionId)');

        try {
          // Fetch members for this subscription
          final membersResponse = await _client
              .from('subscription_members')
              .select('user_id')
              .eq('subscription_id', subscriptionId);

          print('   👥 Found ${(membersResponse as List).length} members for ${json['name']}');

          // Add shared_with to JSON before parsing
          json['shared_with'] = (membersResponse as List<dynamic>)
              .map((m) => m['user_id'] as String)
              .toList();

          subscriptions.add(
            SubscriptionModel.fromJson(json as Map<String, dynamic>),
          );
        } catch (memberError) {
          print('   ⚠️ Error fetching members for $subscriptionId: $memberError');
          // Continue with empty shared_with if members query fails
          json['shared_with'] = <String>[];
          subscriptions.add(
            SubscriptionModel.fromJson(json as Map<String, dynamic>),
          );
        }
      }

      print('✅ [SubscriptionRemoteDS] Successfully fetched ${subscriptions.length} subscriptions');
      return subscriptions;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching subscriptions: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch subscriptions: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String subscriptionId) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Fetching subscription by ID: $subscriptionId');

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', subscriptionId)
          .single();

      print('📦 [SubscriptionRemoteDS] Found subscription: ${response['name']}');

      final json = response as Map<String, dynamic>;

      // Fetch members for this subscription
      try {
        final membersResponse = await _client
            .from('subscription_members')
            .select('user_id')
            .eq('subscription_id', subscriptionId);

        print('   👥 Found ${(membersResponse as List).length} members');

        // Add shared_with to JSON before parsing
        json['shared_with'] = (membersResponse as List<dynamic>)
            .map((m) => m['user_id'] as String)
            .toList();
      } catch (memberError) {
        print('   ⚠️ Error fetching members: $memberError');
        json['shared_with'] = <String>[];
      }

      print('✅ [SubscriptionRemoteDS] Successfully fetched subscription');
      return SubscriptionModel.fromJson(json);
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching subscription: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionMemberModel>> getMembers(String userId) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Fetching members for user: $userId');

      // First, get all subscriptions owned by the user
      final subscriptions = await getSubscriptions(userId);
      final subscriptionIds = subscriptions.map((s) => s.id).toList();

      if (subscriptionIds.isEmpty) {
        print('   ℹ️ No subscriptions found, returning empty members list');
        return [];
      }

      print('   📋 Fetching members for ${subscriptionIds.length} subscriptions');

      // Then, get all members for those subscriptions
      final response = await _client
          .from('subscription_members')
          .select()
          .inFilter('subscription_id', subscriptionIds)
          .order('created_at', ascending: false);

      print('📦 [SubscriptionRemoteDS] Supabase response: ${(response as List).length} members');

      final List<dynamic> data = response as List<dynamic>;
      final members = data
          .map((json) =>
              SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [SubscriptionRemoteDS] Successfully fetched ${members.length} members');
      return members;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching members: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      print('🔍 [SubscriptionRemoteDS] Fetching members for subscription: $subscriptionId');

      final response = await _client
          .from('subscription_members')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('created_at', ascending: false);

      print('📦 [SubscriptionRemoteDS] Supabase response: ${(response as List).length} members');

      final List<dynamic> data = response as List<dynamic>;
      final members = data
          .map((json) =>
              SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [SubscriptionRemoteDS] Successfully fetched ${members.length} members');
      return members;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching subscription members: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch subscription members: ${e.toString()}',
      );
    }
  }

  @override
  Future<MonthlyStatsModel> calculateMonthlyStats(String userId) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Calculating monthly stats for user: $userId');

      // Get all active subscriptions
      final subscriptions = await getSubscriptions(userId);
      final activeSubscriptions = subscriptions
          .where((s) => s.status == 'active')
          .toList();

      print('   📊 Found ${activeSubscriptions.length} active subscriptions');

      // Get all members
      final members = await getMembers(userId);
      print('   👥 Found ${members.length} total members');

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

      print('   💰 Unpaid members: ${unpaidMembers.length}');
      print('   ✅ Paid members: ${paidMembers.length}');

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

      print('   ⚠️ Overdue payments: $overduePaymentsCount');

      final stats = MonthlyStatsModel(
        totalMonthlyCost: totalMonthlyCost,
        pendingToCollect: pendingToCollect,
        activeSubscriptionsCount: activeSubscriptions.length,
        overduePaymentsCount: overduePaymentsCount,
        collectedAmount: collectedAmount,
        paidMembersCount: paidMembers.length,
        unpaidMembersCount: unpaidMembers.length,
      );

      print('✅ [SubscriptionRemoteDS] Stats calculated: \$${totalMonthlyCost.toStringAsFixed(2)} monthly, \$${pendingToCollect.toStringAsFixed(2)} pending');
      return stats;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error calculating monthly stats: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      print('🔍 [SubscriptionRemoteDS] Creating subscription: ${subscription.name}');

      // Remove shared_with before sending to Supabase
      final jsonData = subscription.toJson();
      jsonData.remove('shared_with');

      print('   📤 Sending data to Supabase: ${jsonData.keys.join(', ')}');

      final response = await _client
          .from('subscriptions')
          .insert(jsonData)
          .select()
          .single();

      print('📦 [SubscriptionRemoteDS] Supabase response: ${response['id']}');

      final json = response as Map<String, dynamic>;
      json['shared_with'] = <String>[]; // New subscription has no members yet

      print('✅ [SubscriptionRemoteDS] Successfully created subscription');
      return SubscriptionModel.fromJson(json);
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error creating subscription: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      print('🔍 [SubscriptionRemoteDS] Updating subscription: ${subscription.name} (ID: ${subscription.id})');

      // Remove shared_with before sending to Supabase
      final jsonData = subscription.toJson();
      jsonData.remove('shared_with');

      print('   📤 Sending updated data to Supabase');

      final response = await _client
          .from('subscriptions')
          .update(jsonData)
          .eq('id', subscription.id)
          .select()
          .single();

      print('📦 [SubscriptionRemoteDS] Supabase response received');

      final json = response as Map<String, dynamic>;

      // Fetch current members
      try {
        final membersResponse = await _client
            .from('subscription_members')
            .select('user_id')
            .eq('subscription_id', subscription.id);

        json['shared_with'] = (membersResponse as List<dynamic>)
            .map((m) => m['user_id'] as String)
            .toList();
      } catch (memberError) {
        print('   ⚠️ Error fetching members after update: $memberError');
        json['shared_with'] = <String>[];
      }

      print('✅ [SubscriptionRemoteDS] Successfully updated subscription');
      return SubscriptionModel.fromJson(json);
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error updating subscription: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to update subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Deleting subscription: $subscriptionId');

      // Note: CASCADE DELETE is configured in Supabase, so members will be auto-deleted
      // But we'll delete members explicitly for clarity
      print('   🗑️ Deleting members first...');
      await _client
          .from('subscription_members')
          .delete()
          .eq('subscription_id', subscriptionId);

      print('   🗑️ Deleting subscription...');
      await _client.from('subscriptions').delete().eq('id', subscriptionId);

      print('✅ [SubscriptionRemoteDS] Successfully deleted subscription');
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error deleting subscription: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      print('🔍 [SubscriptionRemoteDS] Updating payment status for member: $memberId');
      print('   💳 Has paid: $hasPaid, Payment date: ${paymentDate?.toIso8601String() ?? 'null'}');

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

      print('📦 [SubscriptionRemoteDS] Supabase response received');

      final member = SubscriptionMemberModel.fromJson(response as Map<String, dynamic>);

      print('✅ [SubscriptionRemoteDS] Successfully updated payment status');
      return member;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error updating payment status: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      print('🔍 [SubscriptionRemoteDS] Adding member: ${member.userName}');
      print('   📋 Subscription ID: ${member.subscriptionId}');
      print('   💰 Amount to pay: \$${member.amountToPay.toStringAsFixed(2)}');

      final response = await _client
          .from('subscription_members')
          .insert(member.toJson())
          .select()
          .single();

      print('📦 [SubscriptionRemoteDS] Supabase response: ${response['id']}');

      final addedMember = SubscriptionMemberModel.fromJson(response as Map<String, dynamic>);

      print('✅ [SubscriptionRemoteDS] Successfully added member');
      return addedMember;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error adding member: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to add member: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> removeMember(String memberId) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Removing member: $memberId');

      await _client.from('subscription_members').delete().eq('id', memberId);

      print('✅ [SubscriptionRemoteDS] Successfully removed member');
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error removing member: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to remove member: ${e.toString()}',
      );
    }
  }
}
