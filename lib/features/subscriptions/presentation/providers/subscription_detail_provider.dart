// lib/features/subscriptions/presentation/providers/subscription_detail_provider.dart
import 'package:flutter/foundation.dart';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_detail_provider.g.dart';

/// Provider for fetching subscription details by ID
///
/// Returns a [Subscription] entity if found.
/// Throws [SubscriptionFailure] if operation fails (handled by AsyncValue).
///
/// Auto-disposes when not in use.
/// Uses family pattern with subscriptionId parameter.
@riverpod
Future<Subscription> subscriptionDetail(
  SubscriptionDetailRef ref,
  String subscriptionId,
) async {
  debugPrint('🔍 [SubscriptionDetail] Fetching subscription: $subscriptionId');

  final getSubscriptionDetails = ref.watch(getSubscriptionDetailsProvider);
  final result = await getSubscriptionDetails(subscriptionId);

  return result.fold(
    (failure) {
      debugPrint('❌ [SubscriptionDetail] Failed to fetch: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (subscription) {
      debugPrint('✅ [SubscriptionDetail] Subscription found: ${subscription.name}');
      return subscription;
    },
  );
}

/// Provider for fetching subscription members by subscription ID
///
/// Returns a list of [SubscriptionMember] entities.
/// Throws [SubscriptionFailure] if operation fails (handled by AsyncValue).
///
/// Auto-disposes when not in use.
/// Uses family pattern with subscriptionId parameter.
@riverpod
Future<List<SubscriptionMember>> subscriptionMembers(
  SubscriptionMembersRef ref,
  String subscriptionId,
) async {
  debugPrint('🔍 [SubscriptionMembers] Fetching members for: $subscriptionId');

  final repository = ref.watch(subscriptionRepositoryProvider);
  final result = await repository.getSubscriptionMembers(subscriptionId);

  return result.fold(
    (failure) {
      debugPrint('❌ [SubscriptionMembers] Failed to fetch: ${failure.toString()}');
      throw failure; // AsyncValue will catch and show error
    },
    (members) {
      debugPrint('✅ [SubscriptionMembers] Found ${members.length} members');
      return members;
    },
  );
}

/// Provider for calculating subscription statistics
///
/// Computes stats based on subscription and members data:
/// - Total members count (including owner)
/// - Paid/unpaid members count
/// - Collected and remaining amounts
/// - Owner's share calculation
///
/// Auto-refreshes when subscription or members data changes.
@riverpod
class SubscriptionStats extends _$SubscriptionStats {
  @override
  Future<SubscriptionStatsData> build(String subscriptionId) async {
    debugPrint('📊 [SubscriptionStats] Calculating stats for: $subscriptionId');

    // Watch both subscription and members providers
    final subscription =
        await ref.watch(subscriptionDetailProvider(subscriptionId).future);
    final members =
        await ref.watch(subscriptionMembersProvider(subscriptionId).future);

    // Calculate stats
    final totalMembers = members.length + 1; // +1 for owner
    final paidMembers = members.where((m) => m.hasPaid).length;
    final unpaidMembers = members.where((m) => !m.hasPaid).length;

    final collectedAmount = members
        .where((m) => m.hasPaid)
        .fold<double>(0.0, (sum, m) => sum + m.amountToPay);

    // Remaining = total cost - collected amount
    // This includes both unpaid members AND owner's share (since owner hasn't "paid" themselves)
    final remainingAmount = subscription.totalCost - collectedAmount;

    // Calculate owner's share (with proper rounding)
    final splitAmount = subscription.totalCost / totalMembers;
    final floorAmount = (splitAmount * 100).floor() / 100;
    final yourShare = subscription.totalCost - (floorAmount * members.length);

    debugPrint('📊 [SubscriptionStats] Stats calculated:');
    debugPrint('   Total Members: $totalMembers');
    debugPrint('   Paid: $paidMembers, Unpaid: $unpaidMembers');
    debugPrint('   Collected: \$${collectedAmount.toStringAsFixed(2)}');
    debugPrint('   Remaining: \$${remainingAmount.toStringAsFixed(2)}');
    debugPrint('   Your Share: \$${yourShare.toStringAsFixed(2)}');

    return SubscriptionStatsData(
      totalMembers: totalMembers,
      paidMembers: paidMembers,
      unpaidMembers: unpaidMembers,
      collectedAmount: collectedAmount,
      remainingAmount: remainingAmount,
      yourShare: yourShare,
    );
  }
}

/// Data class for subscription statistics
///
/// Holds computed statistics for a subscription including:
/// - Member counts (total, paid, unpaid)
/// - Financial totals (collected, remaining, owner's share)
class SubscriptionStatsData {
  const SubscriptionStatsData({
    required this.totalMembers,
    required this.paidMembers,
    required this.unpaidMembers,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.yourShare,
  });

  /// Total number of members (including owner)
  final int totalMembers;

  /// Number of members who have paid
  final int paidMembers;

  /// Number of members who haven't paid yet
  final int unpaidMembers;

  /// Total amount collected from paid members
  final double collectedAmount;

  /// Total amount still owed by unpaid members
  final double remainingAmount;

  /// Owner's calculated share (includes remainder from rounding)
  final double yourShare;

  @override
  String toString() {
    return 'SubscriptionStatsData('
        'totalMembers: $totalMembers, '
        'paidMembers: $paidMembers, '
        'unpaidMembers: $unpaidMembers, '
        'collectedAmount: \$${collectedAmount.toStringAsFixed(2)}, '
        'remainingAmount: \$${remainingAmount.toStringAsFixed(2)}, '
        'yourShare: \$${yourShare.toStringAsFixed(2)}'
        ')';
  }
}
