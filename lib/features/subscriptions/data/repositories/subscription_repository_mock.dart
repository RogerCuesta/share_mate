// lib/features/subscriptions/data/repositories/subscription_repository_mock.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_seed_data.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_data.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_overview.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_analytics.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_spending.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/time_range.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:uuid/uuid.dart';

/// Mock implementation of SubscriptionRepository for UI testing
///
/// This repository uses [SubscriptionSeedData] to provide realistic mock data
/// without connecting to Supabase. Perfect for:
/// - UI development and testing
/// - Offline development
/// - Demo purposes
/// - Integration testing
///
/// Usage:
/// ```dart
/// // In injection.dart, replace the real repository with this mock:
/// @Riverpod(keepAlive: true)
/// SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
///   return SubscriptionRepositoryMock();
/// }
/// ```
///
/// **IMPORTANT**: This is for development only. Replace with the real
/// implementation before production deployment.
class SubscriptionRepositoryMock implements SubscriptionRepository {
  // In-memory storage for simulated state changes
  List<Subscription>? _cachedSubscriptions;
  List<SubscriptionMember>? _cachedMembers;
  List<PaymentHistory>? _cachedPaymentHistory;
  MonthlyStats? _cachedStats;

  /// Simulate network delay for realistic testing
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<Either<SubscriptionFailure, MonthlyStats>> getMonthlyStats(
    String userId,
  ) async {
    await _simulateDelay();

    try {
      // Return cached or fresh mock stats
      _cachedStats ??= SubscriptionSeedData.getMockStats();
      return Right(_cachedStats!);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<Subscription>>>
      getActiveSubscriptions(String userId) async {
    await _simulateDelay();

    try {
      // Get all subscriptions and filter active ones
      _cachedSubscriptions ??=
          SubscriptionSeedData.getMockSubscriptions(userId);

      final activeSubscriptions = _cachedSubscriptions!
          .where((sub) => sub.status == SubscriptionStatus.active)
          .toList();

      return Right(activeSubscriptions);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<Subscription>>> getAllSubscriptions(
    String userId,
  ) async {
    await _simulateDelay();

    try {
      _cachedSubscriptions ??=
          SubscriptionSeedData.getMockSubscriptions(userId);
      return Right(_cachedSubscriptions!);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> getSubscriptionById(
    String subscriptionId,
  ) async {
    await _simulateDelay();

    try {
      _cachedSubscriptions ??=
          SubscriptionSeedData.getMockSubscriptions('current-user');

      final subscription = _cachedSubscriptions!.firstWhere(
        (sub) => sub.id == subscriptionId,
        orElse: () => throw Exception('Subscription not found'),
      );

      return Right(subscription);
    } catch (e) {
      return const Left(SubscriptionFailure.notFound());
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>>
      getPendingPayments(String userId) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

      // Filter only pending (not paid)
      final pending =
          _cachedMembers!.where((member) => !member.hasPaid).toList();

      return Right(pending);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>>
      getSubscriptionMembers(String subscriptionId) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

      final members = _cachedMembers!
          .where((member) => member.subscriptionId == subscriptionId)
          .toList();

      return Right(members);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> createSubscription(
    Subscription subscription,
  ) async {
    await _simulateDelay();

    try {
      _cachedSubscriptions ??= SubscriptionSeedData.getMockSubscriptions(
        subscription.ownerId,
      );

      // Add to cache
      _cachedSubscriptions!.add(subscription);

      // Recalculate stats
      _recalculateStats();

      return Right(subscription);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> updateSubscription(
    Subscription subscription,
  ) async {
    await _simulateDelay();

    try {
      _cachedSubscriptions ??=
          SubscriptionSeedData.getMockSubscriptions('current-user');

      // Find and update
      final index = _cachedSubscriptions!
          .indexWhere((sub) => sub.id == subscription.id);

      if (index == -1) {
        return const Left(SubscriptionFailure.notFound());
      }

      _cachedSubscriptions![index] = subscription;

      // Recalculate stats
      _recalculateStats();

      return Right(subscription);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> deleteSubscription(
    String subscriptionId,
  ) async {
    await _simulateDelay();

    try {
      _cachedSubscriptions ??=
          SubscriptionSeedData.getMockSubscriptions('current-user');

      _cachedSubscriptions!.removeWhere((sub) => sub.id == subscriptionId);

      // Recalculate stats
      _recalculateStats();

      return const Right(unit);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, PaymentHistory>> markPaymentAsPaid({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();
      _cachedPaymentHistory ??= [];

      final index =
          _cachedMembers!.indexWhere((member) => member.id == memberId);

      if (index == -1) {
        return const Left(SubscriptionFailure.notFound());
      }

      // Update member to paid
      final updatedMember = _cachedMembers![index].copyWith(
        hasPaid: true,
        lastPaymentDate: paymentDate,
      );

      _cachedMembers![index] = updatedMember;

      // Get subscription for denormalization
      _cachedSubscriptions ??= SubscriptionSeedData.getMockSubscriptions('current-user');
      final subscription = _cachedSubscriptions!.firstWhere(
        (s) => s.id == subscriptionId,
        orElse: () => _cachedSubscriptions!.first,
      );

      // Create payment history record
      const uuid = Uuid();
      final history = PaymentHistory(
        id: uuid.v4(),
        subscriptionId: subscriptionId,
        memberId: memberId,
        memberName: updatedMember.userName,
        subscriptionName: subscription.name,
        amount: amount,
        paymentDate: paymentDate,
        markedBy: markedBy,
        action: PaymentAction.paid,
        notes: notes,
        createdAt: DateTime.now(),
      );

      _cachedPaymentHistory!.add(history);

      // Recalculate stats
      _recalculateStats();

      return Right(history);
    } catch (e) {
      return Left(SubscriptionFailure.paymentError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, int>> markAllPaymentsAsPaid({
    required String subscriptionId,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();
      _cachedPaymentHistory ??= [];

      // Find all unpaid members for this subscription
      final unpaidMembers = _cachedMembers!
          .where((m) => m.subscriptionId == subscriptionId && !m.hasPaid)
          .toList();

      if (unpaidMembers.isEmpty) {
        return const Right(0);
      }

      const uuid = Uuid();

      // Get subscription for denormalization
      _cachedSubscriptions ??= SubscriptionSeedData.getMockSubscriptions('current-user');
      final subscription = _cachedSubscriptions!.firstWhere(
        (s) => s.id == subscriptionId,
        orElse: () => _cachedSubscriptions!.first,
      );

      // Update all members and create history records
      for (final member in unpaidMembers) {
        final index = _cachedMembers!.indexWhere((m) => m.id == member.id);

        if (index != -1) {
          // Update member
          final updatedMember = _cachedMembers![index].copyWith(
            hasPaid: true,
            lastPaymentDate: paymentDate,
          );
          _cachedMembers![index] = updatedMember;

          // Create history record
          final history = PaymentHistory(
            id: uuid.v4(),
            subscriptionId: subscriptionId,
            memberId: member.id,
            memberName: updatedMember.userName,
            subscriptionName: subscription.name,
            amount: member.amountToPay,
            paymentDate: paymentDate,
            markedBy: markedBy,
            action: PaymentAction.paid,
            notes: notes,
            createdAt: DateTime.now(),
          );
          _cachedPaymentHistory!.add(history);
        }
      }

      // Recalculate stats
      _recalculateStats();

      return Right(unpaidMembers.length);
    } catch (e) {
      return Left(SubscriptionFailure.paymentError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, PaymentHistory>> unmarkPayment({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();
      _cachedPaymentHistory ??= [];

      final index =
          _cachedMembers!.indexWhere((member) => member.id == memberId);

      if (index == -1) {
        return const Left(SubscriptionFailure.notFound());
      }

      // Update member to unpaid
      final updatedMember = _cachedMembers![index].copyWith(
        hasPaid: false,
      );

      _cachedMembers![index] = updatedMember;

      // Get subscription for denormalization
      _cachedSubscriptions ??= SubscriptionSeedData.getMockSubscriptions('current-user');
      final subscription = _cachedSubscriptions!.firstWhere(
        (s) => s.id == subscriptionId,
        orElse: () => _cachedSubscriptions!.first,
      );

      // Create payment history record with unpaid action
      const uuid = Uuid();
      final history = PaymentHistory(
        id: uuid.v4(),
        subscriptionId: subscriptionId,
        memberId: memberId,
        memberName: updatedMember.userName,
        subscriptionName: subscription.name,
        amount: amount,
        paymentDate: paymentDate,
        markedBy: markedBy,
        action: PaymentAction.unpaid,
        notes: notes,
        createdAt: DateTime.now(),
      );

      _cachedPaymentHistory!.add(history);

      // Recalculate stats
      _recalculateStats();

      return Right(history);
    } catch (e) {
      return Left(SubscriptionFailure.paymentError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<PaymentHistory>>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
  }) async {
    await _simulateDelay();

    try {
      _cachedPaymentHistory ??= [];

      // Filter by subscription and optionally by member
      var history = _cachedPaymentHistory!
          .where((h) => h.subscriptionId == subscriptionId)
          .toList();

      if (memberId != null) {
        history = history.where((h) => h.memberId == memberId).toList();
      }

      // Sort by most recent first
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(history);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionMember>>
      addMemberToSubscription({
    required String subscriptionId,
    required String userId,
    required String userName,
    required String userEmail,
    String? userAvatar,
  }) async {
    await _simulateDelay();

    try {
      // Get subscription
      final subscriptionResult = await getSubscriptionById(subscriptionId);

      return subscriptionResult.fold(
        (failure) => Left(failure),
        (subscription) {
          _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

          // Create new member
          final newMember = SubscriptionMember(
            id: 'member_${DateTime.now().millisecondsSinceEpoch}',
            subscriptionId: subscriptionId,
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            userAvatar: userAvatar,
            amountToPay: subscription.costPerPerson,
            hasPaid: false,
            lastPaymentDate: null,
            dueDate: subscription.dueDate,
            createdAt: DateTime.now(),
          );

          _cachedMembers!.add(newMember);

          // Recalculate stats
          _recalculateStats();

          return Right(newMember);
        },
      );
    } catch (e) {
      return Left(SubscriptionFailure.memberError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> removeMemberFromSubscription(
    String memberId,
  ) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

      _cachedMembers!.removeWhere((member) => member.id == memberId);

      // Recalculate stats
      _recalculateStats();

      return const Right(unit);
    } catch (e) {
      return Left(SubscriptionFailure.memberError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionMember>> updateMemberAmount({
    required String memberId,
    required double newAmountToPay,
    bool resetPayment = false,
  }) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

      final index =
          _cachedMembers!.indexWhere((member) => member.id == memberId);

      if (index == -1) {
        return const Left(SubscriptionFailure.notFound());
      }

      // Update member amount and optionally reset payment
      final updatedMember = _cachedMembers![index].copyWith(
        amountToPay: newAmountToPay,
        hasPaid: !resetPayment && _cachedMembers![index].hasPaid,
      );

      _cachedMembers![index] = updatedMember;

      // Recalculate stats
      _recalculateStats();

      return Right(updatedMember);
    } catch (e) {
      return Left(SubscriptionFailure.memberError(e.toString()));
    }
  }

  /// Recalculate monthly stats based on current cached data
  void _recalculateStats() {
    if (_cachedSubscriptions == null || _cachedMembers == null) return;

    final activeSubscriptions = _cachedSubscriptions!
        .where((sub) => sub.status == SubscriptionStatus.active)
        .toList();

    final totalMonthlyCost = activeSubscriptions.fold<double>(
      0.0,
      (sum, sub) => sum + sub.monthlyCost,
    );

    final now = DateTime.now();
    final unpaidMembers = _cachedMembers!.where((m) => !m.hasPaid).toList();
    final paidMembers = _cachedMembers!.where((m) => m.hasPaid).toList();

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

    _cachedStats = MonthlyStats(
      totalMonthlyCost: totalMonthlyCost,
      pendingToCollect: pendingToCollect,
      activeSubscriptionsCount: activeSubscriptions.length,
      overduePaymentsCount: overduePaymentsCount,
      collectedAmount: collectedAmount,
      paidMembersCount: paidMembers.length,
      unpaidMembersCount: unpaidMembers.length,
    );
  }

  @override
  Future<Either<SubscriptionFailure, PaymentStats>> getPaymentStats({
    required String subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _simulateDelay();

    try {
      _cachedPaymentHistory ??= [];

      // Filter by subscription and date range
      var history = _cachedPaymentHistory!
          .where((h) => h.subscriptionId == subscriptionId)
          .toList();

      if (startDate != null) {
        history = history
            .where((h) => h.paymentDate.isAfter(startDate) || h.paymentDate.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        history = history
            .where((h) => h.paymentDate.isBefore(endDate) || h.paymentDate.isAtSameMomentAs(endDate))
            .toList();
      }

      // Calculate stats
      final paidHistory = history.where((h) => h.action == PaymentAction.paid).toList();
      final unpaidHistory = history.where((h) => h.action == PaymentAction.unpaid).toList();

      final totalPayments = paidHistory.length;
      final totalAmountPaid = paidHistory.fold<double>(0.0, (sum, h) => sum + h.amount);
      final totalAmountUnpaid = unpaidHistory.fold<double>(0.0, (sum, h) => sum + h.amount);
      final uniquePayers = paidHistory.map((h) => h.memberId).toSet().length;

      // Calculate payment methods breakdown
      final paymentMethods = <String, int>{};
      for (final payment in paidHistory) {
        final method = payment.paymentMethod ?? 'cash';
        paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
      }

      final stats = PaymentStats(
        totalPayments: totalPayments,
        totalAmountPaid: totalAmountPaid,
        totalAmountUnpaid: totalAmountUnpaid,
        uniquePayers: uniquePayers,
        paymentMethods: paymentMethods,
      );

      return Right(stats);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, String>> exportPaymentHistoryPdf({
    required String subscriptionId,
    required String subscriptionName,
    required List<PaymentHistory> history,
  }) async {
    await _simulateDelay();

    // Mock: Return fake file path
    return const Right('/mock/path/payment_history.pdf');
  }

  @override
  Future<Either<SubscriptionFailure, String>> exportPaymentHistoryCsv({
    required String subscriptionId,
    required String subscriptionName,
    required List<PaymentHistory> history,
  }) async {
    await _simulateDelay();

    // Mock: Return fake file path
    return const Right('/mock/path/payment_history.csv');
  }

  @override
  Future<Either<SubscriptionFailure, AnalyticsData>> getAnalyticsData({
    required String userId,
    required TimeRange timeRange,
  }) async {
    await _simulateDelay();

    try {
      // Get mock data
      _cachedSubscriptions ??=
          SubscriptionSeedData.getMockSubscriptions(userId);
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

      // Calculate overview
      final activeSubscriptions = _cachedSubscriptions!
          .where((sub) => sub.status == SubscriptionStatus.active)
          .toList();

      final totalMonthlyCost = activeSubscriptions.fold<double>(
        0,
        (sum, sub) {
          final monthlyCost = sub.billingCycle == BillingCycle.yearly
              ? sub.totalCost / 12
              : sub.totalCost;
          return sum + monthlyCost;
        },
      );

      final totalMembers = _cachedMembers!.length;
      final averageCostPerSubscription = activeSubscriptions.isEmpty
          ? 0.0
          : totalMonthlyCost / activeSubscriptions.length;

      final overview = AnalyticsOverview(
        totalMonthlyCost: totalMonthlyCost,
        totalActiveSubscriptions: activeSubscriptions.length,
        totalMembers: totalMembers,
        averageCostPerSubscription: averageCostPerSubscription,
      );

      // Generate mock subscription spending data from active subscriptions
      final subscriptionSpending = activeSubscriptions.map((sub) {
        // Calculate monthly cost (normalize yearly to monthly)
        final monthlyCost = sub.billingCycle == BillingCycle.yearly
            ? sub.totalCost / 12
            : sub.totalCost;

        // Mock payment count (simulate 1-6 payments per subscription)
        final paymentCount = (monthlyCost * 0.5).round() + 1;

        return SubscriptionSpending(
          subscriptionId: sub.id,
          subscriptionName: sub.name,
          totalAmountPaid: monthlyCost,
          paymentCount: paymentCount,
          color: sub.color,
        );
      }).toList();

      // Mock analytics data with generated subscription spending
      final analyticsData = AnalyticsData(
        overview: overview,
        spendingTrends: [], // Empty for mock (no payment history)
        subscriptionSpending: subscriptionSpending,
        paymentAnalytics: PaymentAnalytics.empty(),
      );

      return Right(analyticsData);
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  /// Reset all cached data (useful for testing)
  void resetMockData() {
    _cachedSubscriptions = null;
    _cachedMembers = null;
    _cachedStats = null;
    _cachedPaymentHistory = null;
  }
}
