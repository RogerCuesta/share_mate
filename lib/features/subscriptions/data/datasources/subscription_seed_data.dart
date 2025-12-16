// lib/features/subscriptions/data/datasources/subscription_seed_data.dart

import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';

/// Seed data for testing the subscriptions UI
///
/// This class provides mock data for development and testing purposes.
/// Use this data in the repository before connecting to the real Supabase backend.
///
/// Usage:
/// ```dart
/// // In your repository implementation or provider:
/// final subscriptions = SubscriptionSeedData.getMockSubscriptions();
/// final pendingPayments = SubscriptionSeedData.getMockPendingPayments();
/// final stats = SubscriptionSeedData.getMockStats();
/// ```
class SubscriptionSeedData {
  /// Get mock subscriptions for testing
  ///
  /// Returns a list of 8 popular subscription services with realistic data:
  /// - Netflix, Spotify, Disney+, YouTube Premium, Amazon Prime
  /// - Apple Music, HBO Max, Adobe Creative Cloud
  static List<Subscription> getMockSubscriptions(String currentUserId) {
    final now = DateTime.now();

    return [
      // Netflix - Due in 24 days
      Subscription(
        id: 'sub_1',
        name: 'Netflix',
        iconUrl: null,
        color: '#E50914',
        totalCost: 15.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 24)),
        ownerId: currentUserId,
        sharedWith: ['user_2', 'user_3'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 90)),
      ),

      // Spotify - Due in 28 days
      Subscription(
        id: 'sub_2',
        name: 'Spotify',
        iconUrl: null,
        color: '#1DB954',
        totalCost: 9.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 28)),
        ownerId: currentUserId,
        sharedWith: ['user_2'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 60)),
      ),

      // Disney+ - Due in 15 days
      Subscription(
        id: 'sub_3',
        name: 'Disney+',
        iconUrl: null,
        color: '#0063E5',
        totalCost: 13.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 15)),
        ownerId: currentUserId,
        sharedWith: ['user_3', 'user_4'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 45)),
      ),

      // YouTube Premium - Due in 5 days
      Subscription(
        id: 'sub_4',
        name: 'YouTube Premium',
        iconUrl: null,
        color: '#FF0000',
        totalCost: 11.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 5)),
        ownerId: currentUserId,
        sharedWith: ['user_2', 'user_3', 'user_4'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 120)),
      ),

      // Amazon Prime - Due in 20 days
      Subscription(
        id: 'sub_5',
        name: 'Amazon Prime',
        iconUrl: null,
        color: '#00A8E1',
        totalCost: 14.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 20)),
        ownerId: currentUserId,
        sharedWith: ['user_5'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 180)),
      ),

      // Apple Music - Due in 12 days
      Subscription(
        id: 'sub_6',
        name: 'Apple Music',
        iconUrl: null,
        color: '#FA243C',
        totalCost: 10.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 12)),
        ownerId: currentUserId,
        sharedWith: ['user_6'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 30)),
      ),

      // HBO Max - Due in 8 days
      Subscription(
        id: 'sub_7',
        name: 'HBO Max',
        iconUrl: null,
        color: '#5D28FA',
        totalCost: 15.99,
        billingCycle: BillingCycle.monthly,
        dueDate: now.add(const Duration(days: 8)),
        ownerId: currentUserId,
        sharedWith: ['user_2', 'user_6'],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 75)),
      ),

      // Adobe Creative Cloud - Yearly subscription
      Subscription(
        id: 'sub_8',
        name: 'Adobe Creative Cloud',
        iconUrl: null,
        color: '#FF0000',
        totalCost: 599.88, // Yearly cost
        billingCycle: BillingCycle.yearly,
        dueDate: now.add(const Duration(days: 120)),
        ownerId: currentUserId,
        sharedWith: [],
        status: SubscriptionStatus.active,
        createdAt: now.subtract(const Duration(days: 245)),
      ),
    ];
  }

  /// Get mock pending payments for testing
  ///
  /// Returns a list of subscription members who haven't paid yet.
  /// Some payments are overdue to test the "Action Required" section.
  static List<SubscriptionMember> getMockPendingPayments() {
    final now = DateTime.now();

    return [
      // Sarah Jenkins - Overdue 4 days (Netflix)
      SubscriptionMember(
        id: 'member_1',
        subscriptionId: 'sub_1',
        userId: 'user_2',
        userName: 'Sarah Jenkins',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 5.33, // 15.99 / 3 members
        hasPaid: false,
        lastPaymentDate: now.subtract(const Duration(days: 34)),
        dueDate: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 90)),
      ),

      // Mike Thompson - Overdue 5 days (Spotify)
      SubscriptionMember(
        id: 'member_2',
        subscriptionId: 'sub_2',
        userId: 'user_3',
        userName: 'Mike T.',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 5.00, // 9.99 / 2 members
        hasPaid: false,
        lastPaymentDate: now.subtract(const Duration(days: 35)),
        dueDate: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 60)),
      ),

      // Emma Wilson - Pending (Disney+)
      SubscriptionMember(
        id: 'member_3',
        subscriptionId: 'sub_3',
        userId: 'user_3',
        userName: 'Emma Wilson',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 4.66, // 13.99 / 3 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 45)),
      ),

      // David Lee - Pending (Disney+)
      SubscriptionMember(
        id: 'member_4',
        subscriptionId: 'sub_3',
        userId: 'user_4',
        userName: 'David Lee',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 4.66, // 13.99 / 3 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 45)),
      ),

      // Alex Rodriguez - Due soon (YouTube Premium)
      SubscriptionMember(
        id: 'member_5',
        subscriptionId: 'sub_4',
        userId: 'user_2',
        userName: 'Alex Rodriguez',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 3.00, // 11.99 / 4 members
        hasPaid: false,
        lastPaymentDate: now.subtract(const Duration(days: 25)),
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 120)),
      ),

      // Jessica Chen - Pending (YouTube Premium)
      SubscriptionMember(
        id: 'member_6',
        subscriptionId: 'sub_4',
        userId: 'user_3',
        userName: 'Jessica Chen',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 3.00, // 11.99 / 4 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 120)),
      ),

      // Chris Parker - Overdue 2 days (YouTube Premium)
      SubscriptionMember(
        id: 'member_7',
        subscriptionId: 'sub_4',
        userId: 'user_4',
        userName: 'Chris Parker',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 3.00, // 11.99 / 4 members
        hasPaid: false,
        lastPaymentDate: now.subtract(const Duration(days: 32)),
        dueDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 120)),
      ),

      // Rachel Green - Pending (Amazon Prime)
      SubscriptionMember(
        id: 'member_8',
        subscriptionId: 'sub_5',
        userId: 'user_5',
        userName: 'Rachel Green',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 7.50, // 14.99 / 2 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 20)),
        createdAt: now.subtract(const Duration(days: 180)),
      ),

      // Tom Brady - Pending (Apple Music)
      SubscriptionMember(
        id: 'member_9',
        subscriptionId: 'sub_6',
        userId: 'user_6',
        userName: 'Tom Brady',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 5.50, // 10.99 / 2 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 30)),
      ),

      // Lisa Anderson - Pending (HBO Max)
      SubscriptionMember(
        id: 'member_10',
        subscriptionId: 'sub_7',
        userId: 'user_2',
        userName: 'Lisa Anderson',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 5.33, // 15.99 / 3 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 75)),
      ),

      // Kevin Martinez - Pending (HBO Max)
      SubscriptionMember(
        id: 'member_11',
        subscriptionId: 'sub_7',
        userId: 'user_6',
        userName: 'Kevin Martinez',
        userEmail: 'sarah@email.com',
        userAvatar: null,
        amountToPay: 5.33, // 15.99 / 3 members
        hasPaid: false,
        lastPaymentDate: null,
        dueDate: now.add(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 75)),
      ),
    ];
  }

  /// Get mock monthly statistics for testing
  ///
  /// Returns realistic statistics based on the mock subscriptions and payments.
  static MonthlyStats getMockStats() {
    return const MonthlyStats(
      totalMonthlyCost: 142.90, // Sum of all monthly costs (including yearly/12)
      pendingToCollect: 45.00, // Total from unpaid members
      activeSubscriptionsCount: 8, // All 8 subscriptions
      overduePaymentsCount: 3, // Sarah, Mike, and Chris
      collectedAmount: 35.00, // Amount already collected this month
      paidMembersCount: 4, // Members who have paid
      unpaidMembersCount: 11, // Members who haven't paid
    );
  }

  /// Get mock active subscriptions (subset of all subscriptions)
  ///
  /// Returns only the subscriptions that should be displayed on the home screen.
  /// Typically the most recent or most important ones.
  static List<Subscription> getMockActiveSubscriptions(String currentUserId) {
    final all = getMockSubscriptions(currentUserId);
    // Return first 6 for the home screen grid (3 rows x 2 columns)
    return all.take(6).toList();
  }

  /// Get mock overdue payments (subset of pending payments)
  ///
  /// Returns only the payments that are overdue for the "Action Required" section.
  static List<SubscriptionMember> getMockOverduePayments() {
    final all = getMockPendingPayments();
    // Return only overdue payments (first 3: Sarah, Mike, Chris)
    return all.where((member) => member.isOverdue).toList();
  }

  /// Clear all mock data (for testing reset functionality)
  static void clearMockData() {
    // This is a placeholder for when we implement data clearing functionality
    // In a real implementation, this would clear any cached data
  }

  /// Check if using mock data (for development mode indicators)
  static bool get isMockDataEnabled => true;
}
