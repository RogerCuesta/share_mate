import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/core/sync/sync_logger.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/analytics_data_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/analytics_overview_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/monthly_spending_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/monthly_stats_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_analytics_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_history_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_spending_model.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/time_range.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when subscription remote operations fail
class SubscriptionRemoteException implements Exception {
  SubscriptionRemoteException(this.message);
  final String message;

  @override
  String toString() => 'SubscriptionRemoteException: $message';
}

class PaymentSyncMemberCycleContext {
  const PaymentSyncMemberCycleContext({
    required this.cycleDueDate,
    required this.hasPaid,
  });

  final DateTime cycleDueDate;
  final bool hasPaid;
}

class BillingCycleResetSnapshot {
  const BillingCycleResetSnapshot({
    required this.batchId,
    required this.subscriptionId,
    required this.previousDueDate,
    required this.nextDueDate,
    required this.resetAt,
    required this.processedMemberCount,
  });

  factory BillingCycleResetSnapshot.fromJson(Map<String, dynamic> json) {
    return BillingCycleResetSnapshot(
      batchId: json['batch_id'] as String,
      subscriptionId: json['subscription_id'] as String,
      previousDueDate: DateTime.parse(json['previous_due_date'] as String),
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      resetAt: DateTime.parse(json['reset_at'] as String),
      processedMemberCount:
          (json['processed_member_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String batchId;
  final String subscriptionId;
  final DateTime previousDueDate;
  final DateTime nextDueDate;
  final DateTime resetAt;
  final int processedMemberCount;
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
    String? idempotencyKey,
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
    String? idempotencyKey,
  });

  /// Fetch authoritative cycle context used for offline sync conflict preflight.
  Future<PaymentSyncMemberCycleContext> getPaymentSyncMemberCycleContext({
    required String subscriptionId,
    required String memberId,
  });

  /// Persist non-PII audit metadata for deterministic sync conflict outcomes.
  Future<void> recordPaymentSyncConflictAudit({
    required String operationId,
    required String subscriptionId,
    required String memberId,
    required String action,
    required String terminalReason,
    required DateTime queuedCycleDueDate,
    required DateTime backendCycleDueDate,
    required int retryCount,
    required String idempotencyKey,
  });

  /// Fetch latest backend-driven billing cycle reset visible to the owner.
  Future<BillingCycleResetSnapshot?> getLatestBillingCycleReset({
    String? subscriptionId,
  });

  /// Get payment history for a subscription
  Future<List<PaymentHistoryModel>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
    int? limit,
  });

  /// Get payment statistics using RPC function
  Future<PaymentStats> getPaymentStats({
    required String subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get analytics data (overview + spending trends + payment analytics)
  Future<AnalyticsDataModel> getAnalyticsData({
    required String userId,
    required TimeRange timeRange,
  });
}

/// Implementation of SubscriptionRemoteDataSource using Supabase
class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSourceImpl({
    SupabaseClient? client,
    SyncLogger syncLogger = const SyncLogger(
      scope: 'SubscriptionRemoteDataSource',
    ),
  })  : _client = client ?? SupabaseService.client,
        _syncLogger = syncLogger;
  final SupabaseClient _client;
  final SyncLogger _syncLogger;

  @override
  Future<List<SubscriptionModel>> getSubscriptions(String userId) async {
    try {
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Fetching subscriptions for user: $userId');

      // 1. Fetch subscriptions
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      debugPrint(
          '📦 [SubscriptionRemoteDS] Supabase response: ${response.length} subscriptions');

      final data = response as List<dynamic>;
      final subscriptions = <SubscriptionModel>[];

      // 2. For each subscription, fetch members and populate sharedWith
      for (final item in data) {
        final json = Map<String, dynamic>.from(item as Map);
        final subscriptionId = json['id'] as String;
        debugPrint(
            '   📋 Processing subscription: ${json['name']} (ID: $subscriptionId)');

        try {
          // Fetch members for this subscription
          final membersResponse = await _client
              .from('subscription_members')
              .select('user_id')
              .eq('subscription_id', subscriptionId);

          final members = membersResponse as List<dynamic>;
          debugPrint(
              '   👥 Found ${members.length} members for ${json['name']}');

          // Add shared_with to JSON before parsing
          json['shared_with'] = members
              .map((member) => (member as Map<String, dynamic>)['user_id'])
              .whereType<String>()
              .toList();

          subscriptions.add(SubscriptionModel.fromJson(json));
        } catch (memberError) {
          debugPrint(
              '   ⚠️ Error fetching members for $subscriptionId: $memberError');
          // Continue with empty shared_with if members query fails
          json['shared_with'] = <String>[];
          subscriptions.add(SubscriptionModel.fromJson(json));
        }
      }

      debugPrint(
          '✅ [SubscriptionRemoteDS] Successfully fetched ${subscriptions.length} subscriptions');
      return subscriptions;
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching subscriptions: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch subscriptions: ${e.toString()}',
      );
    }
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String subscriptionId) async {
    try {
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Fetching subscription by ID: $subscriptionId');

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', subscriptionId)
          .single();

      debugPrint(
          '📦 [SubscriptionRemoteDS] Found subscription: ${response['name']}');

      final json = Map<String, dynamic>.from(response as Map);

      // Fetch members for this subscription
      try {
        final membersResponse = await _client
            .from('subscription_members')
            .select('user_id')
            .eq('subscription_id', subscriptionId);

        debugPrint('   👥 Found ${(membersResponse as List).length} members');

        // Add shared_with to JSON before parsing
        json['shared_with'] = (membersResponse as List<dynamic>)
            .map((member) => (member as Map<String, dynamic>)['user_id'])
            .whereType<String>()
            .toList();
      } catch (memberError) {
        debugPrint('   ⚠️ Error fetching members: $memberError');
        json['shared_with'] = <String>[];
      }

      debugPrint('✅ [SubscriptionRemoteDS] Successfully fetched subscription');
      return SubscriptionModel.fromJson(json);
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching subscription: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SubscriptionMemberModel>> getMembers(String userId) async {
    try {
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Fetching members for user: $userId');

      // First, get all subscriptions owned by the user
      final subscriptions = await getSubscriptions(userId);
      final subscriptionIds = subscriptions.map((s) => s.id).toList();

      if (subscriptionIds.isEmpty) {
        debugPrint(
            '   ℹ️ No subscriptions found, returning empty members list');
        return [];
      }

      debugPrint(
          '   📋 Fetching members for ${subscriptionIds.length} subscriptions');

      // Then, get all members for those subscriptions
      final response = await _client
          .from('subscription_members')
          .select()
          .inFilter('subscription_id', subscriptionIds)
          .order('created_at', ascending: false);

      debugPrint(
          '📦 [SubscriptionRemoteDS] Supabase response: ${(response as List).length} members');

      final data = response as List<dynamic>;
      final members = data
          .map((json) =>
              SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint(
          '✅ [SubscriptionRemoteDS] Successfully fetched ${members.length} members');
      return members;
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching members: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Fetching members for subscription: $subscriptionId');

      final response = await _client
          .from('subscription_members')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('created_at', ascending: false);

      debugPrint(
          '📦 [SubscriptionRemoteDS] Supabase response: ${(response as List).length} members');

      final data = response as List<dynamic>;
      final members = data
          .map((json) =>
              SubscriptionMemberModel.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint(
          '✅ [SubscriptionRemoteDS] Successfully fetched ${members.length} members');
      return members;
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching subscription members: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch subscription members: ${e.toString()}',
      );
    }
  }

  @override
  Future<MonthlyStatsModel> calculateMonthlyStats(String userId) async {
    try {
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Calculating monthly stats for user: $userId');

      // Get all active subscriptions
      final subscriptions = await getSubscriptions(userId);
      final activeSubscriptions =
          subscriptions.where((s) => s.status == 'active').toList();

      debugPrint(
          '   📊 Found ${activeSubscriptions.length} active subscriptions');

      // Get all members
      final members = await getMembers(userId);
      debugPrint('   👥 Found ${members.length} total members');

      // Calculate stats
      final totalMonthlyCost = activeSubscriptions.fold<double>(
        0,
        (sum, sub) {
          // Convert yearly to monthly if needed
          final monthlyCost =
              sub.billingCycle == 'yearly' ? sub.totalCost / 12 : sub.totalCost;
          return sum + monthlyCost;
        },
      );

      final now = DateTime.now();
      final unpaidMembers = members.where((m) => !m.hasPaid).toList();
      final paidMembers = members.where((m) => m.hasPaid).toList();

      debugPrint('   💰 Unpaid members: ${unpaidMembers.length}');
      debugPrint('   ✅ Paid members: ${paidMembers.length}');

      final pendingToCollect = unpaidMembers.fold<double>(
        0,
        (sum, member) => sum + member.amountToPay,
      );

      final collectedAmount = paidMembers.fold<double>(
        0,
        (sum, member) => sum + member.amountToPay,
      );

      final overduePaymentsCount =
          unpaidMembers.where((m) => m.dueDate.isBefore(now)).length;

      debugPrint('   ⚠️ Overdue payments: $overduePaymentsCount');

      final stats = MonthlyStatsModel(
        totalMonthlyCost: totalMonthlyCost,
        pendingToCollect: pendingToCollect,
        activeSubscriptionsCount: activeSubscriptions.length,
        overduePaymentsCount: overduePaymentsCount,
        collectedAmount: collectedAmount,
        paidMembersCount: paidMembers.length,
        unpaidMembersCount: unpaidMembers.length,
      );

      debugPrint(
          '✅ [SubscriptionRemoteDS] Stats calculated: \$${totalMonthlyCost.toStringAsFixed(2)} monthly, \$${pendingToCollect.toStringAsFixed(2)} pending');
      return stats;
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error calculating monthly stats: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Creating subscription: ${subscription.name}');

      // Remove shared_with before sending to Supabase
      final jsonData = subscription.toJson()..remove('shared_with');

      debugPrint('   📤 Sending data to Supabase: ${jsonData.keys.join(', ')}');

      final response = await _client
          .from('subscriptions')
          .insert(jsonData)
          .select()
          .single();

      debugPrint(
          '📦 [SubscriptionRemoteDS] Supabase response: ${response['id']}');

      final json = Map<String, dynamic>.from(response as Map);
      json['shared_with'] = <String>[]; // New subscription has no members yet

      debugPrint('✅ [SubscriptionRemoteDS] Successfully created subscription');
      return SubscriptionModel.fromJson(json);
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error creating subscription: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Updating subscription: ${subscription.name} (ID: ${subscription.id})');

      // Only send updatable fields (exclude id, created_at, updated_at, shared_with)
      final updateData = {
        'name': subscription.name,
        'icon_url': subscription.iconUrl,
        'color': subscription.color,
        'total_cost': subscription.totalCost,
        'billing_cycle': subscription.billingCycle,
        'due_date': subscription.dueDate.toIso8601String(),
        'billing_anchor_day': subscription.billingAnchorDay,
        'status': subscription.status,
        // owner_id should not change, but include it for safety
        'owner_id': subscription.ownerId,
      };

      debugPrint('   📤 Sending updated data to Supabase');

      final response = await _client
          .from('subscriptions')
          .update(updateData)
          .eq('id', subscription.id)
          .select()
          .single();

      debugPrint('📦 [SubscriptionRemoteDS] Supabase response received');

      final json = response;

      // Fetch current members
      try {
        final membersResponse = await _client
            .from('subscription_members')
            .select('user_id')
            .eq('subscription_id', subscription.id);

        json['shared_with'] = (membersResponse as List<dynamic>)
            .map((member) => (member as Map<String, dynamic>)['user_id'])
            .whereType<String>()
            .toList();
      } catch (memberError) {
        debugPrint('   ⚠️ Error fetching members after update: $memberError');
        json['shared_with'] = <String>[];
      }

      debugPrint('✅ [SubscriptionRemoteDS] Successfully updated subscription');
      return SubscriptionModel.fromJson(json);
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error updating subscription: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to update subscription: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      debugPrint(
          '🔍 [SubscriptionRemoteDS] Deleting subscription: $subscriptionId');

      // Note: CASCADE DELETE is configured in Supabase, so members will be auto-deleted
      // But we'll delete members explicitly for clarity
      debugPrint('   🗑️ Deleting members first...');
      await _client
          .from('subscription_members')
          .delete()
          .eq('subscription_id', subscriptionId);

      debugPrint('   🗑️ Deleting subscription...');
      await _client.from('subscriptions').delete().eq('id', subscriptionId);

      debugPrint('✅ [SubscriptionRemoteDS] Successfully deleted subscription');
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error deleting subscription: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      _syncLogger.logSync(
        event: 'remote_update_payment_status_started',
        operationId: memberId,
        actionType: hasPaid ? 'paid' : 'unpaid',
        metadata: {
          'layer': 'remote_datasource',
          'has_payment_date': paymentDate != null,
        },
      );

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

      final member = SubscriptionMemberModel.fromJson(response);
      _syncLogger.logSync(
        event: 'remote_update_payment_status_completed',
        operationId: memberId,
        actionType: hasPaid ? 'paid' : 'unpaid',
        metadata: {'layer': 'remote_datasource'},
      );
      return member;
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_update_payment_status_postgrest_exception',
        operationId: memberId,
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );
      throw SubscriptionRemoteException(
        'Database error updating payment status: ${e.message}',
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_update_payment_status_exception',
        operationId: memberId,
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );
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
      _syncLogger.logSync(
        event: 'remote_add_member_started',
        actionType: 'member_create',
        metadata: {'layer': 'remote_datasource'},
      );
      debugPrint('🔍 [SubscriptionRemoteDS] Adding member: ${member.userName}');
      debugPrint('   📋 Subscription linked');
      debugPrint(
          '   💰 Amount to pay: \$${member.amountToPay.toStringAsFixed(2)}');

      final payload = member.toJson();
      payload['user_email'] = _normalizeOptionalEmail(
        payload['user_email'] as String?,
      );

      final response = await _client
          .from('subscription_members')
          .insert(payload)
          .select()
          .single();

      debugPrint(
          '📦 [SubscriptionRemoteDS] Supabase response: ${response['id']}');

      final addedMember = SubscriptionMemberModel.fromJson(response);

      _syncLogger.logSync(
        event: 'remote_add_member_completed',
        actionType: 'member_create',
        metadata: {'layer': 'remote_datasource'},
      );
      debugPrint('✅ [SubscriptionRemoteDS] Successfully added member');
      return addedMember;
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error adding member: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to add member: ${e.toString()}',
      );
    }
  }

  String? _normalizeOptionalEmail(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  double _normalizeCurrency(double value) {
    return (value * 100).round() / 100;
  }

  @override
  Future<void> removeMember(String memberId) async {
    try {
      _syncLogger.logSync(
        event: 'remote_remove_member_started',
        operationId: memberId,
        actionType: 'member_remove',
        metadata: {'layer': 'remote_datasource'},
      );
      debugPrint('🔍 [SubscriptionRemoteDS] Removing member');

      await _client.from('subscription_members').delete().eq('id', memberId);

      _syncLogger.logSync(
        event: 'remote_remove_member_completed',
        operationId: memberId,
        actionType: 'member_remove',
        metadata: {'layer': 'remote_datasource'},
      );
      debugPrint('✅ [SubscriptionRemoteDS] Successfully removed member');
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error removing member: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
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
      _syncLogger.logSync(
        event: 'remote_update_member_amount_started',
        operationId: memberId,
        actionType: 'member_amount_update',
        metadata: {
          'layer': 'remote_datasource',
          'reset_payment': hasPaid != null,
        },
      );

      // Build update data conditionally
      final updateData = <String, dynamic>{
        'amount_to_pay': _normalizeCurrency(amountToPay),
        if (hasPaid != null) 'has_paid': hasPaid,
      };

      final response = await _client
          .from('subscription_members')
          .update(updateData)
          .eq('id', memberId)
          .select()
          .single();

      _syncLogger.logSync(
        event: 'remote_update_member_amount_completed',
        operationId: memberId,
        actionType: 'member_amount_update',
        metadata: {
          'layer': 'remote_datasource',
          'reset_payment': hasPaid != null,
        },
      );

      return SubscriptionMemberModel.fromJson(response);
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_update_member_amount_postgrest_exception',
        operationId: memberId,
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );
      throw SubscriptionRemoteException(
        'Database error updating member amount: ${e.message}',
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_update_member_amount_exception',
        operationId: memberId,
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );
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
    String? idempotencyKey,
  }) async {
    try {
      _syncLogger
        ..logSync(
          event: 'remote_mark_paid_started',
          actionType: 'paid',
          metadata: {'layer': 'remote_datasource'},
        )
        // Call atomic RPC function (single transaction).
        ..logSync(
          event: 'remote_mark_paid_rpc_call',
          actionType: 'paid',
          metadata: {'layer': 'remote_datasource', 'rpc': 'atomic_paid'},
        );
      final response = await _client
          .rpc('mark_payment_as_paid_atomic', params: {
            'p_subscription_id': subscriptionId,
            'p_member_id': memberId,
            'p_amount': amount,
            'p_payment_date': paymentDate.toIso8601String(),
            'p_marked_by': markedBy,
            'p_notes': notes,
            'p_payment_method': 'cash', // Default payment method
            if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
          })
          .select()
          .single();

      _syncLogger.logSync(
        event: 'remote_mark_paid_rpc_success',
        actionType: 'paid',
        metadata: {'layer': 'remote_datasource'},
      );

      // RPC returns denormalized data
      final paymentHistoryId = response['payment_history_id'] as String;
      final memberName = response['member_name'] as String;
      final subscriptionName = response['subscription_name'] as String;

      _syncLogger.logSync(
        event: 'remote_mark_paid_completed',
        actionType: 'paid',
        metadata: {'layer': 'remote_datasource'},
      );

      // Construct PaymentHistoryModel (temporarily using fromJson pattern until model is updated)
      // TODO: Update to use new constructor with denormalized fields after FASE 2/3
      return PaymentHistoryModel.fromJson({
        'id': paymentHistoryId,
        'subscription_id': subscriptionId,
        'member_id': memberId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'marked_by': markedBy,
        'action': 'paid',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        // New denormalized fields (will be ignored for now)
        'member_name': memberName,
        'subscription_name': subscriptionName,
        'payment_method': 'cash',
      });
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_mark_paid_postgrest_exception',
        operationId: 'remote_mark_paid_postgrest_exception',
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );
      throw SubscriptionRemoteException(
        'Database error marking payment as paid: ${e.message}',
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_mark_paid_exception',
        operationId: 'remote_mark_paid_exception',
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );
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
      _syncLogger
        ..logSync(
          event: 'remote_mark_all_started',
          actionType: 'paid_bulk',
          metadata: {'layer': 'remote_datasource'},
        )
        ..logSync(
          event: 'remote_mark_all_rpc_call',
          actionType: 'paid_bulk',
          metadata: {
            'layer': 'remote_datasource',
            'rpc': 'mark_all_payments_as_paid_atomic',
          },
        );
      final response =
          await _client.rpc('mark_all_payments_as_paid_atomic', params: {
        'p_subscription_id': subscriptionId,
        'p_payment_date': paymentDate.toIso8601String(),
        'p_marked_by': markedBy,
        'p_notes': notes,
        'p_payment_method': 'cash',
      });

      final count = response is int
          ? response
          : response is num
              ? response.toInt()
              : 0;

      _syncLogger.logSync(
        event: 'remote_mark_all_completed',
        actionType: 'paid_bulk',
        metadata: {
          'layer': 'remote_datasource',
          'updated_count': count,
        },
      );

      return count;
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_mark_all_postgrest_exception',
        operationId: 'remote_mark_all_postgrest_exception',
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );
      throw SubscriptionRemoteException(
        'Database error marking all payments as paid: ${e.message}',
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_mark_all_exception',
        operationId: 'remote_mark_all_exception',
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );
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
    String? idempotencyKey,
  }) async {
    try {
      _syncLogger
        ..logSync(
          event: 'remote_unmark_started',
          actionType: 'unpaid',
          metadata: {'layer': 'remote_datasource'},
        )
        // Call atomic RPC function (single transaction).
        ..logSync(
          event: 'remote_unmark_rpc_call',
          actionType: 'unpaid',
          metadata: {'layer': 'remote_datasource', 'rpc': 'atomic_unmark'},
        );
      final paymentHistoryId =
          await _client.rpc('unmark_payment_atomic', params: {
        'p_subscription_id': subscriptionId,
        'p_member_id': memberId,
        'p_amount': amount,
        'p_payment_date': paymentDate.toIso8601String(),
        'p_marked_by': markedBy,
        'p_notes': notes,
        if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
      }) as String;

      _syncLogger.logSync(
        event: 'remote_unmark_rpc_success',
        operationId: paymentHistoryId,
        actionType: 'unpaid',
        metadata: {'layer': 'remote_datasource'},
      );

      // Fetch denormalized names for the response
      // (RPC should ideally return these, but for now we fetch them)
      final memberData = await _client
          .from('subscription_members')
          .select('user_name')
          .eq('id', memberId)
          .single();

      final subscriptionData = await _client
          .from('subscriptions')
          .select('name')
          .eq('id', subscriptionId)
          .single();

      _syncLogger.logSync(
        event: 'remote_unmark_completed',
        operationId: paymentHistoryId,
        actionType: 'unpaid',
        metadata: {'layer': 'remote_datasource'},
      );

      // Construct PaymentHistoryModel (temporarily using fromJson pattern until model is updated)
      // TODO: Update to use new constructor with denormalized fields after FASE 2/3
      return PaymentHistoryModel.fromJson({
        'id': paymentHistoryId,
        'subscription_id': subscriptionId,
        'member_id': memberId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'marked_by': markedBy,
        'action': 'unpaid',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        // New denormalized fields (will be ignored for now)
        'member_name': memberData['user_name'] as String,
        'subscription_name': subscriptionData['name'] as String,
      });
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_unmark_postgrest_exception',
        operationId: 'remote_unmark_postgrest_exception',
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );
      throw SubscriptionRemoteException(
        'Database error unmarking payment: ${e.message}',
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_unmark_exception',
        operationId: 'remote_unmark_exception',
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );
      throw SubscriptionRemoteException(
        'Failed to unmark payment: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentSyncMemberCycleContext> getPaymentSyncMemberCycleContext({
    required String subscriptionId,
    required String memberId,
  }) async {
    try {
      final response = await _client
          .from('subscription_members')
          .select('due_date, has_paid')
          .eq('id', memberId)
          .eq('subscription_id', subscriptionId)
          .single();
      final cycleDueDate = DateTime.parse(response['due_date'] as String);
      return PaymentSyncMemberCycleContext(
        cycleDueDate: cycleDueDate,
        hasPaid: response['has_paid'] as bool? ?? false,
      );
    } on PostgrestException catch (e) {
      throw SubscriptionRemoteException(
        'Database error fetching sync cycle context: ${e.message}',
      );
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to fetch sync cycle context: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> recordPaymentSyncConflictAudit({
    required String operationId,
    required String subscriptionId,
    required String memberId,
    required String action,
    required String terminalReason,
    required DateTime queuedCycleDueDate,
    required DateTime backendCycleDueDate,
    required int retryCount,
    required String idempotencyKey,
  }) async {
    try {
      await _client.rpc(
        'record_payment_sync_conflict_audit',
        params: {
          'p_operation_id': operationId,
          'p_subscription_id': subscriptionId,
          'p_member_id': memberId,
          'p_action': action,
          'p_terminal_reason': terminalReason,
          'p_queued_cycle_due_date': queuedCycleDueDate.toIso8601String(),
          'p_backend_cycle_due_date': backendCycleDueDate.toIso8601String(),
          'p_retry_count': retryCount,
          'p_idempotency_key': idempotencyKey,
        },
      );
    } on PostgrestException catch (e) {
      throw SubscriptionRemoteException(
        'Database error recording sync conflict audit: ${e.message}',
      );
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to record sync conflict audit: ${e.toString()}',
      );
    }
  }

  @override
  Future<BillingCycleResetSnapshot?> getLatestBillingCycleReset({
    String? subscriptionId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_latest_billing_cycle_reset',
        params: {
          if (subscriptionId != null) 'p_subscription_id': subscriptionId,
        },
      );
      if (response == null) {
        return null;
      }

      final raw = switch (response) {
        final List<dynamic> rows when rows.isEmpty => null,
        final List<dynamic> rows => rows.first,
        _ => response,
      };
      if (raw == null) {
        return null;
      }

      return BillingCycleResetSnapshot.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
    } on PostgrestException catch (e) {
      throw SubscriptionRemoteException(
        'Database error fetching billing cycle reset: ${e.message}',
      );
    } catch (e) {
      throw SubscriptionRemoteException(
        'Failed to fetch billing cycle reset: ${e.toString()}',
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
      _syncLogger.logSync(
        event: 'remote_get_payment_history_started',
        operationId: subscriptionId,
        actionType: 'payment_history_fetch',
        metadata: {
          'layer': 'remote_datasource',
          'filter_enabled': memberId != null,
          'limit_enabled': limit != null,
        },
      );

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
      final finalQuery =
          limit != null ? orderedQuery.limit(limit) : orderedQuery;

      final response = await finalQuery;

      final history = (response as List<dynamic>)
          .map((json) =>
              PaymentHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _syncLogger.logSync(
        event: 'remote_get_payment_history_completed',
        operationId: subscriptionId,
        actionType: 'payment_history_fetch',
        metadata: {
          'layer': 'remote_datasource',
          'record_count': history.length,
        },
      );

      return history;
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_get_payment_history_postgrest_exception',
        operationId: subscriptionId,
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );
      throw SubscriptionRemoteException(
        'Database error fetching payment history: ${e.message}',
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_get_payment_history_exception',
        operationId: subscriptionId,
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );
      throw SubscriptionRemoteException(
        'Failed to fetch payment history: ${e.toString()}',
      );
    }
  }

  /// Get payment statistics using RPC function
  ///
  /// Calls the `get_payment_history_stats` RPC function to retrieve
  /// aggregated payment statistics for a subscription.
  @override
  Future<PaymentStats> getPaymentStats({
    required String subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _syncLogger
        ..logSync(
          event: 'remote_get_payment_stats_started',
          operationId: subscriptionId,
          actionType: 'payment_stats_fetch',
          metadata: {
            'layer': 'remote_datasource',
            'start_window_applied': startDate != null,
            'end_window_applied': endDate != null,
          },
        )
        // Call RPC function for aggregated stats.
        ..logSync(
          event: 'remote_get_payment_stats_rpc_call',
          operationId: subscriptionId,
          actionType: 'payment_stats_fetch',
          metadata: {'layer': 'remote_datasource'},
        );
      final response = await _client.rpc('get_payment_history_stats', params: {
        'p_subscription_id': subscriptionId,
        'p_start_date': startDate?.toIso8601String(),
        'p_end_date': endDate?.toIso8601String(),
      }).single();

      _syncLogger.logSync(
        event: 'remote_get_payment_stats_rpc_success',
        operationId: subscriptionId,
        actionType: 'payment_stats_fetch',
        metadata: {'layer': 'remote_datasource'},
      );

      // Parse response from RPC
      final totalPayments = response['total_payments'] as int? ?? 0;
      final totalAmountPaid =
          (response['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
      final totalAmountUnpaid =
          (response['total_amount_unpaid'] as num?)?.toDouble() ?? 0.0;
      final uniquePayers = response['unique_payers'] as int? ?? 0;

      // Parse payment methods JSONB
      final paymentMethodsJson =
          response['payment_methods'] as Map<String, dynamic>?;
      final paymentMethods = <String, int>{};

      if (paymentMethodsJson != null) {
        paymentMethodsJson.forEach((key, value) {
          if (value != null) {
            paymentMethods[key] = (value as num).toInt();
          }
        });
      }

      final stats = PaymentStats(
        totalPayments: totalPayments,
        totalAmountPaid: totalAmountPaid,
        totalAmountUnpaid: totalAmountUnpaid,
        uniquePayers: uniquePayers,
        paymentMethods: paymentMethods,
      );

      _syncLogger.logSync(
        event: 'remote_get_payment_stats_completed',
        operationId: subscriptionId,
        actionType: 'payment_stats_fetch',
        metadata: {
          'layer': 'remote_datasource',
          'total_payments': totalPayments,
          'unique_payers': uniquePayers,
        },
      );

      return stats;
    } on PostgrestException catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_get_payment_stats_postgrest_exception',
        operationId: subscriptionId,
        terminalReason: 'remote_database_error',
        errorClass: 'postgrest',
        errorCode: e.code,
      );

      // Return empty stats on error instead of throwing
      debugPrint('⚠️  Returning empty stats due to error');
      return PaymentStats.empty();
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'remote_get_payment_stats_exception',
        operationId: subscriptionId,
        terminalReason: 'remote_unexpected_error',
        errorClass: e.runtimeType.toString(),
      );

      // Return empty stats on error instead of throwing
      debugPrint('⚠️  Returning empty stats due to error');
      return PaymentStats.empty();
    }
  }

  @override
  Future<AnalyticsDataModel> getAnalyticsData({
    required String userId,
    required TimeRange timeRange,
  }) async {
    try {
      debugPrint('🔍 [SubscriptionRemoteDS] Fetching analytics data');
      debugPrint('   User: $userId');
      debugPrint('   Time Range: ${timeRange.displayName}');

      // Get start date based on time range
      final startDate = timeRange.getStartDate();
      debugPrint(
          '   Start Date: ${startDate?.toIso8601String() ?? "All time"}');

      // Parallel queries for better performance
      final results = await Future.wait([
        _getAnalyticsOverview(userId),
        _getSpendingTrends(userId, startDate),
        _getSubscriptionSpending(userId, startDate),
        _getPaymentAnalytics(userId, startDate),
      ]);

      final overview = results[0] as AnalyticsOverviewModel;
      final spendingTrends = results[1] as List<MonthlySpendingModel>;
      final subscriptionSpending =
          results[2] as List<SubscriptionSpendingModel>;
      final paymentAnalytics = results[3] as PaymentAnalyticsModel;

      final analyticsData = AnalyticsDataModel(
        overview: overview,
        spendingTrends: spendingTrends,
        subscriptionSpending: subscriptionSpending,
        paymentAnalytics: paymentAnalytics,
      );

      debugPrint(
          '✅ [SubscriptionRemoteDS] Analytics data fetched successfully');
      return analyticsData;
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ [SubscriptionRemoteDS] PostgrestException: ${e.message} (Code: ${e.code})');
      throw SubscriptionRemoteException(
        'Database error fetching analytics: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [SubscriptionRemoteDS] Unexpected error: $e');
      throw SubscriptionRemoteException(
        'Failed to fetch analytics: ${e.toString()}',
      );
    }
  }

  /// Get analytics overview (total monthly cost, active subscriptions, members, avg cost)
  Future<AnalyticsOverviewModel> _getAnalyticsOverview(String userId) async {
    // Fetch subscriptions and members
    final subscriptions = await getSubscriptions(userId);
    final members = await getMembers(userId);

    // Calculate overview stats
    final activeSubscriptions =
        subscriptions.where((s) => s.status == 'active').toList();

    final totalMonthlyCost = activeSubscriptions.fold<double>(
      0,
      (sum, sub) {
        final monthlyCost =
            sub.billingCycle == 'yearly' ? sub.totalCost / 12 : sub.totalCost;
        return sum + monthlyCost;
      },
    );

    final totalMembers = members.length;

    final averageCostPerSubscription = activeSubscriptions.isEmpty
        ? 0.0
        : totalMonthlyCost / activeSubscriptions.length;

    return AnalyticsOverviewModel(
      totalMonthlyCost: totalMonthlyCost,
      totalActiveSubscriptions: activeSubscriptions.length,
      totalMembers: totalMembers,
      averageCostPerSubscription: averageCostPerSubscription,
    );
  }

  /// Get spending trends grouped by month from payment_history
  Future<List<MonthlySpendingModel>> _getSpendingTrends(
    String userId,
    DateTime? startDate,
  ) async {
    // Query payment_history for paid payments
    var queryBuilder = _client
        .from('payment_history')
        .select('payment_date, amount')
        .eq('action', 'paid');

    if (startDate != null) {
      queryBuilder =
          queryBuilder.gte('payment_date', startDate.toIso8601String());
    }

    final data = await queryBuilder;

    // Group by month in Flutter
    final monthlyMap = <DateTime, _MonthlySpendingAccumulator>{};

    for (final record in data) {
      final paymentDate = DateTime.parse(record['payment_date'] as String);
      final amount = (record['amount'] as num).toDouble();

      // Create month key (first day of month)
      final monthKey = DateTime(paymentDate.year, paymentDate.month);

      if (monthlyMap.containsKey(monthKey)) {
        monthlyMap[monthKey]!.amountPaid += amount;
        monthlyMap[monthKey]!.paymentCount++;
      } else {
        monthlyMap[monthKey] = _MonthlySpendingAccumulator(
          month: monthKey,
          amountPaid: amount,
          paymentCount: 1,
        );
      }
    }

    // Convert to models and sort by date
    final spendingTrends = monthlyMap.values
        .map((acc) => MonthlySpendingModel(
              month: acc.month,
              amountPaid: acc.amountPaid,
              paymentCount: acc.paymentCount,
            ))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    return spendingTrends;
  }

  /// Get subscription spending (total amount paid per subscription)
  Future<List<SubscriptionSpendingModel>> _getSubscriptionSpending(
    String userId,
    DateTime? startDate,
  ) async {
    // Get user's subscriptions first to get subscription details
    final subscriptions = await getSubscriptions(userId);
    final subscriptionMap = {for (final s in subscriptions) s.id: s};

    // Query payment_history for paid payments
    var queryBuilder = _client
        .from('payment_history')
        .select('subscription_id, subscription_name, amount')
        .eq('action', 'paid');

    if (startDate != null) {
      queryBuilder =
          queryBuilder.gte('payment_date', startDate.toIso8601String());
    }

    final data = await queryBuilder;

    // Group by subscription_id
    final subscriptionSpendingMap =
        <String, _SubscriptionSpendingAccumulator>{};

    for (final record in data) {
      final subscriptionId = record['subscription_id'] as String;
      final subscriptionName =
          record['subscription_name'] as String? ?? 'Unknown';
      final amount = (record['amount'] as num).toDouble();

      if (subscriptionSpendingMap.containsKey(subscriptionId)) {
        subscriptionSpendingMap[subscriptionId]!.totalAmountPaid += amount;
        subscriptionSpendingMap[subscriptionId]!.paymentCount++;
      } else {
        // Get color from subscription if available
        final subscription = subscriptionMap[subscriptionId];
        final color = subscription?.color ?? '#6C63FF'; // Default purple

        subscriptionSpendingMap[subscriptionId] =
            _SubscriptionSpendingAccumulator(
          subscriptionId: subscriptionId,
          subscriptionName: subscriptionName,
          totalAmountPaid: amount,
          paymentCount: 1,
          color: color,
        );
      }
    }

    // Convert to models, sort by amount (descending), and take top 10
    final subscriptionSpending = subscriptionSpendingMap.values
        .map((acc) => SubscriptionSpendingModel(
              subscriptionId: acc.subscriptionId,
              subscriptionName: acc.subscriptionName,
              totalAmountPaid: acc.totalAmountPaid,
              paymentCount: acc.paymentCount,
              color: acc.color,
            ))
        .toList()
      ..sort((a, b) => b.totalAmountPaid.compareTo(a.totalAmountPaid));

    // Return top 10 subscriptions
    return subscriptionSpending.take(10).toList();
  }

  /// Get payment analytics (on-time rate, avg days, top payers, overdue)
  Future<PaymentAnalyticsModel> _getPaymentAnalytics(
    String userId,
    DateTime? startDate,
  ) async {
    // Get all members to calculate overdue amount
    final members = await getMembers(userId);

    // Query payment_history with join to subscription_members for due_date
    var queryBuilder = _client
        .from('payment_history')
        .select(
            'payment_date, member_id, member_name, amount, subscription_members!inner(due_date)')
        .eq('action', 'paid');

    if (startDate != null) {
      queryBuilder =
          queryBuilder.gte('payment_date', startDate.toIso8601String());
    }

    final historyData = await queryBuilder;

    if (historyData.isEmpty) {
      // No payment history - calculate only overdue amount
      final now = DateTime.now();
      final overdueAmount = members
          .where((m) => !m.hasPaid && m.dueDate.isBefore(now))
          .fold<double>(0, (sum, m) => sum + m.amountToPay);

      return PaymentAnalyticsModel(
        onTimePaymentRate: 0,
        averageDaysToPayment: 0,
        topPayers: [],
        overdueAmount: overdueAmount,
      );
    }

    // Calculate on-time payment rate and average days to payment
    var onTimeCount = 0;
    var totalDaysToPayment = 0;
    final payerMap = <String, _TopPayerAccumulator>{};

    for (final record in historyData) {
      final paymentDate = DateTime.parse(record['payment_date'] as String);
      final memberData = record['subscription_members'] as Map<String, dynamic>;
      final dueDate = DateTime.parse(memberData['due_date'] as String);
      final memberId = record['member_id'] as String;
      final memberName = record['member_name'] as String? ?? 'Unknown';
      final amount = (record['amount'] as num).toDouble();

      // Calculate days to payment (negative = early, positive = late)
      final daysToPayment = paymentDate.difference(dueDate).inDays;
      totalDaysToPayment += daysToPayment;

      if (daysToPayment <= 0) {
        onTimeCount++;
      }

      // Track top payers
      if (payerMap.containsKey(memberId)) {
        payerMap[memberId]!.paymentCount++;
        payerMap[memberId]!.totalPaid += amount;
      } else {
        payerMap[memberId] = _TopPayerAccumulator(
          memberName: memberName,
          paymentCount: 1,
          totalPaid: amount,
        );
      }
    }

    final onTimeRate = (onTimeCount / historyData.length) * 100;
    final avgDays = totalDaysToPayment / historyData.length;

    // Get top 3 payers
    final topPayersList = payerMap.values
        .map((acc) => TopPayerModel(
              memberName: acc.memberName,
              paymentCount: acc.paymentCount,
              totalPaid: acc.totalPaid,
            ))
        .toList()
      ..sort((a, b) => b.paymentCount.compareTo(a.paymentCount));

    final topPayers = topPayersList.take(3).toList();

    // Calculate overdue amount from members
    final now = DateTime.now();
    final overdueAmount = members
        .where((m) => !m.hasPaid && m.dueDate.isBefore(now))
        .fold<double>(0, (sum, m) => sum + m.amountToPay);

    return PaymentAnalyticsModel(
      onTimePaymentRate: onTimeRate,
      averageDaysToPayment: avgDays,
      topPayers: topPayers,
      overdueAmount: overdueAmount,
    );
  }
}

// ========== Helper Classes for Accumulation ==========

class _MonthlySpendingAccumulator {
  _MonthlySpendingAccumulator({
    required this.month,
    required this.amountPaid,
    required this.paymentCount,
  });
  final DateTime month;
  double amountPaid;
  int paymentCount;
}

class _SubscriptionSpendingAccumulator {
  _SubscriptionSpendingAccumulator({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.totalAmountPaid,
    required this.paymentCount,
    required this.color,
  });
  final String subscriptionId;
  final String subscriptionName;
  double totalAmountPaid;
  int paymentCount;
  final String color;
}

class _TopPayerAccumulator {
  _TopPayerAccumulator({
    required this.memberName,
    required this.paymentCount,
    required this.totalPaid,
  });
  final String memberName;
  int paymentCount;
  double totalPaid;
}
