import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../models/monthly_stats_model.dart';
import '../models/payment_history_model.dart';
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

  /// Update member amount and optionally reset payment status
  Future<SubscriptionMemberModel> updateMemberAmount({
    required String memberId,
    required double amountToPay,
    bool? hasPaid, // null = don't update has_paid field
  });

  /// Mark a payment as paid (2-step transaction: update member + insert history)
  Future<PaymentHistoryModel> markPaymentAsPaid({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  });

  /// Mark all pending payments as paid for a subscription
  Future<int> markAllPaymentsAsPaid({
    required String subscriptionId,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  });

  /// Unmark a payment (undo paid status)
  Future<PaymentHistoryModel> unmarkPayment({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  });

  /// Get payment history for a subscription
  Future<List<PaymentHistoryModel>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
    int? limit,
  });
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

      final json = response;

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

      final json = response;
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

      // Only send updatable fields (exclude id, created_at, updated_at, shared_with)
      final updateData = {
        'name': subscription.name,
        'icon_url': subscription.iconUrl,
        'color': subscription.color,
        'total_cost': subscription.totalCost,
        'billing_cycle': subscription.billingCycle,
        'due_date': subscription.dueDate.toIso8601String(),
        'status': subscription.status,
        // owner_id should not change, but include it for safety
        'owner_id': subscription.ownerId,
      };

      print('   📤 Sending updated data to Supabase');

      final response = await _client
          .from('subscriptions')
          .update(updateData)
          .eq('id', subscription.id)
          .select()
          .single();

      print('📦 [SubscriptionRemoteDS] Supabase response received');

      final json = response;

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

      final member = SubscriptionMemberModel.fromJson(response);

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

      final addedMember = SubscriptionMemberModel.fromJson(response);

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

  @override
  Future<SubscriptionMemberModel> updateMemberAmount({
    required String memberId,
    required double amountToPay,
    bool? hasPaid,
  }) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Updating member amount: $memberId');
      print('   Amount: \$$amountToPay');
      if (hasPaid != null) {
        print('   Reset payment: $hasPaid');
      }

      // Build update data conditionally
      final updateData = <String, dynamic>{
        'amount_to_pay': amountToPay,
        if (hasPaid != null) 'has_paid': hasPaid,
      };

      final response = await _client
          .from('subscription_members')
          .update(updateData)
          .eq('id', memberId)
          .select()
          .single();

      print('✅ [SubscriptionRemoteDS] Successfully updated member amount');

      return SubscriptionMemberModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error updating member amount: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to update member amount: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentHistoryModel> markPaymentAsPaid({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Marking payment as paid');
      print('   Member: $memberId');
      print('   Amount: \$${amount.toStringAsFixed(2)}');
      print('   Payment Date: ${paymentDate.toIso8601String()}');

      // Generate UUID for payment history
      const uuid = Uuid();
      final historyId = uuid.v4();

      // Step 1: Update member payment status
      print('   📝 Step 1/2: Updating member payment status...');
      await _client
          .from('subscription_members')
          .update({
            'has_paid': true,
            'last_payment_date': paymentDate.toIso8601String(),
          })
          .eq('id', memberId);

      print('   ✅ Member updated');

      // Step 2: Insert payment history record
      print('   📝 Step 2/2: Creating payment history record...');
      final historyData = {
        'id': historyId,
        'subscription_id': subscriptionId,
        'member_id': memberId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'marked_by': markedBy,
        'action': 'paid',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('payment_history')
          .insert(historyData)
          .select()
          .single();

      print('✅ [SubscriptionRemoteDS] Payment marked as paid successfully');

      return PaymentHistoryModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error marking payment as paid: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to mark payment as paid: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> markAllPaymentsAsPaid({
    required String subscriptionId,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Marking all payments as paid');
      print('   Subscription: $subscriptionId');
      print('   Payment Date: ${paymentDate.toIso8601String()}');

      // Step 1: Get all unpaid members for this subscription
      print('   📝 Step 1/3: Fetching unpaid members...');
      final unpaidResponse = await _client
          .from('subscription_members')
          .select()
          .eq('subscription_id', subscriptionId)
          .eq('has_paid', false);

      final unpaidMembers = (unpaidResponse as List<dynamic>)
          .map((json) => SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('   📊 Found ${unpaidMembers.length} unpaid members');

      if (unpaidMembers.isEmpty) {
        print('   ℹ️ No unpaid members to update');
        return 0;
      }

      const uuid = Uuid();

      // Step 2: Update all members to paid
      print('   📝 Step 2/3: Updating all members to paid...');
      await _client
          .from('subscription_members')
          .update({
            'has_paid': true,
            'last_payment_date': paymentDate.toIso8601String(),
          })
          .eq('subscription_id', subscriptionId)
          .eq('has_paid', false);

      print('   ✅ All members updated');

      // Step 3: Insert payment history records for all members
      print('   📝 Step 3/3: Creating payment history records...');
      final historyRecords = unpaidMembers.map((member) {
        return {
          'id': uuid.v4(),
          'subscription_id': subscriptionId,
          'member_id': member.id,
          'amount': member.amountToPay,
          'payment_date': paymentDate.toIso8601String(),
          'marked_by': markedBy,
          'action': 'paid',
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _client.from('payment_history').insert(historyRecords);

      print('✅ [SubscriptionRemoteDS] Marked ${unpaidMembers.length} payments as paid');

      return unpaidMembers.length;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error marking all payments as paid: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to mark all payments as paid: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentHistoryModel> unmarkPayment({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Unmarking payment (undo)');
      print('   Member: $memberId');
      print('   Amount: \$${amount.toStringAsFixed(2)}');

      const uuid = Uuid();
      final historyId = uuid.v4();

      // Step 1: Update member to unpaid
      print('   📝 Step 1/2: Updating member to unpaid...');
      await _client
          .from('subscription_members')
          .update({
            'has_paid': false,
          })
          .eq('id', memberId);

      print('   ✅ Member updated');

      // Step 2: Insert payment history record with 'unpaid' action
      print('   📝 Step 2/2: Creating payment history record...');
      final historyData = {
        'id': historyId,
        'subscription_id': subscriptionId,
        'member_id': memberId,
        'amount': amount,
        'payment_date': paymentDate,
        'marked_by': markedBy,
        'action': 'unpaid',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('payment_history')
          .insert(historyData)
          .select()
          .single();

      print('✅ [SubscriptionRemoteDS] Payment unmarked successfully');

      return PaymentHistoryModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error unmarking payment: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to unmark payment: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<PaymentHistoryModel>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
    int? limit,
  }) async {
    try {
      print('🔍 [SubscriptionRemoteDS] Fetching payment history');
      print('   Subscription: $subscriptionId');
      if (memberId != null) {
        print('   Member filter: $memberId');
      }
      if (limit != null) {
        print('   Limit: $limit');
      }

      // Build query with filters
      var query = _client
          .from('payment_history')
          .select()
          .eq('subscription_id', subscriptionId);

      // Apply member filter if provided
      if (memberId != null) {
        query = query.eq('member_id', memberId);
      }

      // Apply ordering
      final orderedQuery = query.order('created_at', ascending: false);

      // Apply limit if provided
      final finalQuery = limit != null
          ? orderedQuery.limit(limit)
          : orderedQuery;

      final response = await finalQuery;

      final history = (response as List<dynamic>)
          .map((json) => PaymentHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [SubscriptionRemoteDS] Fetched ${history.length} payment history records');

      return history;
    } on PostgrestException catch (e) {
      print('❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching payment history: ${e.message}',
      );
    } catch (e) {
      print('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch payment history: ${e.toString()}',
      );
    }
  }
}
