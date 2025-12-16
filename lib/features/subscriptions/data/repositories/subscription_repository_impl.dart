import 'package:dartz/dartz.dart';

import '../../domain/entities/monthly_stats.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_member.dart';
import '../../domain/failures/subscription_failure.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_local_datasource.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../models/subscription_member_model.dart';
import '../models/subscription_model.dart';

/// Implementation of SubscriptionRepository with offline-first strategy
///
/// This repository tries Supabase first, then falls back to Hive cache on errors.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionLocalDataSource _localDataSource;

  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required SubscriptionLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<SubscriptionFailure, MonthlyStats>> getMonthlyStats(
    String userId,
  ) async {
    try {
      // Try remote first
      final statsModel = await _remoteDataSource.calculateMonthlyStats(userId);
      return Right(statsModel.toEntity());
    } on SubscriptionRemoteException catch (e) {
      // If remote fails, calculate from local cache
      try {
        final subscriptions =
            await _localDataSource.getSubscriptionsByOwnerId(userId);
        final members = await _localDataSource.getMembersByOwnerId(userId);

        // Calculate stats from cached data
        final activeSubscriptions =
            subscriptions.where((s) => s.status == 'active').toList();

        final totalMonthlyCost = activeSubscriptions.fold<double>(
          0.0,
          (sum, sub) {
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

        final overduePaymentsCount =
            unpaidMembers.where((m) => m.dueDate.isBefore(now)).length;

        return Right(
          MonthlyStats(
            totalMonthlyCost: totalMonthlyCost,
            pendingToCollect: pendingToCollect,
            activeSubscriptionsCount: activeSubscriptions.length,
            overduePaymentsCount: overduePaymentsCount,
            collectedAmount: collectedAmount,
            paidMembersCount: paidMembers.length,
            unpaidMembersCount: unpaidMembers.length,
          ),
        );
      } catch (localError) {
        return Left(
          SubscriptionFailure.cacheError(localError.toString()),
        );
      }
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<Subscription>>>
      getActiveSubscriptions(String userId) async {
    try {
      // Try remote first
      final remoteModels = await _remoteDataSource.getSubscriptions(userId);

      // Cache in Hive
      await _localDataSource.cacheSubscriptions(remoteModels);

      // Filter active and convert to entities
      final activeSubscriptions = remoteModels
          .where((model) => model.status == 'active')
          .map((model) => model.toEntity())
          .toList();

      return Right(activeSubscriptions);
    } on SubscriptionRemoteException {
      // Fallback to local cache
      try {
        final cachedModels =
            await _localDataSource.getSubscriptionsByOwnerId(userId);
        final activeSubscriptions = cachedModels
            .where((model) => model.status == 'active')
            .map((model) => model.toEntity())
            .toList();

        return Right(activeSubscriptions);
      } catch (localError) {
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<Subscription>>> getAllSubscriptions(
    String userId,
  ) async {
    try {
      // Try remote first
      final remoteModels = await _remoteDataSource.getSubscriptions(userId);

      // Cache in Hive
      await _localDataSource.cacheSubscriptions(remoteModels);

      return Right(remoteModels.map((model) => model.toEntity()).toList());
    } on SubscriptionRemoteException {
      // Fallback to local cache
      try {
        final cachedModels =
            await _localDataSource.getSubscriptionsByOwnerId(userId);
        return Right(cachedModels.map((model) => model.toEntity()).toList());
      } catch (localError) {
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> getSubscriptionById(
    String subscriptionId,
  ) async {
    try {
      // Check cache first
      final cached = await _localDataSource.getSubscriptionById(subscriptionId);
      if (cached != null) {
        return Right(cached.toEntity());
      }

      // Fetch from remote if not in cache
      final remoteModel =
          await _remoteDataSource.getSubscriptionById(subscriptionId);

      // Cache it
      await _localDataSource.cacheSubscription(remoteModel);

      return Right(remoteModel.toEntity());
    } on SubscriptionRemoteException {
      return const Left(SubscriptionFailure.notFound());
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>>
      getPendingPayments(String userId) async {
    try {
      // Try remote first
      final members = await _remoteDataSource.getMembers(userId);

      // Cache in Hive
      await _localDataSource.cacheMembers(members);

      // Filter pending (not paid)
      final pending = members
          .where((member) => !member.hasPaid)
          .map((member) => member.toEntity())
          .toList();

      return Right(pending);
    } on SubscriptionRemoteException {
      // Fallback to local cache
      try {
        final cachedMembers =
            await _localDataSource.getMembersByOwnerId(userId);
        final pending = cachedMembers
            .where((member) => !member.hasPaid)
            .map((member) => member.toEntity())
            .toList();

        return Right(pending);
      } catch (localError) {
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>>
      getSubscriptionMembers(String subscriptionId) async {
    try {
      // Try remote first
      final members =
          await _remoteDataSource.getSubscriptionMembers(subscriptionId);

      // Cache in Hive
      await _localDataSource.cacheMembers(members);

      return Right(members.map((member) => member.toEntity()).toList());
    } on SubscriptionRemoteException {
      // Fallback to local cache
      try {
        final cachedMembers =
            await _localDataSource.getMembersBySubscriptionId(subscriptionId);
        return Right(
          cachedMembers.map((member) => member.toEntity()).toList(),
        );
      } catch (localError) {
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> createSubscription(
    Subscription subscription,
  ) async {
    try {
      final model = SubscriptionModel.fromEntity(subscription);

      // Save locally first (optimistic update)
      await _localDataSource.cacheSubscription(model);

      // Sync to remote
      final remoteModel = await _remoteDataSource.createSubscription(model);

      // Update local with server version
      await _localDataSource.updateSubscription(remoteModel);

      return Right(remoteModel.toEntity());
    } on SubscriptionRemoteException catch (e) {
      // Remote failed, but local is already saved
      // Return network error
      return Left(SubscriptionFailure.networkError());
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> updateSubscription(
    Subscription subscription,
  ) async {
    try {
      final model = SubscriptionModel.fromEntity(subscription);

      // Update locally first
      await _localDataSource.updateSubscription(model);

      // Sync to remote
      final remoteModel = await _remoteDataSource.updateSubscription(model);

      // Update local with server version
      await _localDataSource.updateSubscription(remoteModel);

      return Right(remoteModel.toEntity());
    } on SubscriptionRemoteException {
      return Left(SubscriptionFailure.networkError());
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> deleteSubscription(
    String subscriptionId,
  ) async {
    try {
      // Delete locally first
      await _localDataSource.deleteSubscription(subscriptionId);

      // Delete from remote
      await _remoteDataSource.deleteSubscription(subscriptionId);

      return const Right(unit);
    } on SubscriptionRemoteException {
      return Left(SubscriptionFailure.networkError());
    } catch (e) {
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionMember>> markPaymentAsPaid({
    required String memberId,
    required DateTime paymentDate,
  }) async {
    try {
      // Update remote first
      final updated = await _remoteDataSource.updatePaymentStatus(
        memberId: memberId,
        hasPaid: true,
        paymentDate: paymentDate,
      );

      // Update local cache
      await _localDataSource.updateMember(updated);

      return Right(updated.toEntity());
    } on SubscriptionRemoteException {
      return Left(SubscriptionFailure.networkError());
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
    try {
      // Get subscription to calculate amount
      final subscriptionResult =
          await getSubscriptionById(subscriptionId);

      return subscriptionResult.fold(
        (failure) => Left(failure),
        (subscription) async {
          final member = SubscriptionMember(
            id: '', // Will be generated by Supabase
            subscriptionId: subscriptionId,
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            amountToPay: subscription.costPerPerson,
            hasPaid: false,
            lastPaymentDate: null,
            dueDate: subscription.dueDate,
            createdAt: DateTime.now(),
          );

          final memberModel = SubscriptionMemberModel.fromEntity(member);

          // Add to remote
          final remoteModel = await _remoteDataSource.addMember(memberModel);

          // Cache locally
          await _localDataSource.cacheMember(remoteModel);

          return Right(remoteModel.toEntity());
        },
      );
    } on SubscriptionRemoteException {
      return Left(SubscriptionFailure.networkError());
    } catch (e) {
      return Left(SubscriptionFailure.memberError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, Unit>> removeMemberFromSubscription(
    String memberId,
  ) async {
    try {
      // Delete from local
      await _localDataSource.deleteMember(memberId);

      // Delete from remote
      await _remoteDataSource.removeMember(memberId);

      return const Right(unit);
    } on SubscriptionRemoteException {
      return Left(SubscriptionFailure.networkError());
    } catch (e) {
      return Left(SubscriptionFailure.memberError(e.toString()));
    }
  }
}
