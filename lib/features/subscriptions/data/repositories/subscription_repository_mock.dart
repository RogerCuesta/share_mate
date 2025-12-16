// lib/features/subscriptions/data/repositories/subscription_repository_mock.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_seed_data.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';

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
  Future<Either<SubscriptionFailure, SubscriptionMember>> markPaymentAsPaid({
    required String memberId,
    required DateTime paymentDate,
  }) async {
    await _simulateDelay();

    try {
      _cachedMembers ??= SubscriptionSeedData.getMockPendingPayments();

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

      // Recalculate stats
      _recalculateStats();

      return Right(updatedMember);
    } catch (e) {
      return Left(SubscriptionFailure.paymentError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionMember>>
      addMemberToSubscription({
    required String subscriptionId,
    required String userId,
    required String userName,
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
            userEmail: "newmember@example.com",
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

  /// Reset all cached data (useful for testing)
  void resetMockData() {
    _cachedSubscriptions = null;
    _cachedMembers = null;
    _cachedStats = null;
  }
}
