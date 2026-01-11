import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_data.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_overview.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_analytics.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/time_range.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of SubscriptionRepository with offline-first strategy
///
/// This repository tries Supabase first, then falls back to Hive cache on errors.
class SubscriptionRepositoryImpl implements SubscriptionRepository {

  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required SubscriptionLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionLocalDataSource _localDataSource;

  @override
  Future<Either<SubscriptionFailure, MonthlyStats>> getMonthlyStats(
    String userId,
  ) async {
    try {
      // Try remote first
      final statsModel = await _remoteDataSource.calculateMonthlyStats(userId);
      return Right(statsModel.toEntity());
    } on SubscriptionRemoteException {
      // If remote fails, calculate from local cache
      try {
        final subscriptions =
            await _localDataSource.getSubscriptionsByOwnerId(userId);
        final members = await _localDataSource.getMembersByOwnerId(userId);

        // Calculate stats from cached data
        final activeSubscriptions =
            subscriptions.where((s) => s.status == 'active').toList();

        final totalMonthlyCost = activeSubscriptions.fold<double>(
          0,
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
          0,
          (sum, member) => sum + member.amountToPay,
        );

        final collectedAmount = paidMembers.fold<double>(
          0,
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
    } on SubscriptionRemoteException {
      // Remote failed, but local is already saved
      // Return network error
      return const Left(SubscriptionFailure.networkError());
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
      return const Left(SubscriptionFailure.networkError());
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
      return const Left(SubscriptionFailure.networkError());
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
    try {
      debugPrint('🔍 [SubscriptionRepository] Marking payment as paid');
      debugPrint('   Member: $memberId, Amount: \$${amount.toStringAsFixed(2)}');

      // Phase 1: Optimistic update in local cache
      final cachedMember = await _localDataSource.getMemberById(memberId);
      final cachedSubscription = await _localDataSource.getSubscriptionById(subscriptionId);

      // Get member and subscription names for denormalization
      final memberName = cachedMember?.userName ?? 'Unknown Member';
      final subscriptionName = cachedSubscription?.name ?? 'Unknown Subscription';

      if (cachedMember != null) {
        final updatedMember = SubscriptionMemberModel(
          id: cachedMember.id,
          subscriptionId: cachedMember.subscriptionId,
          userId: cachedMember.userId,
          userName: cachedMember.userName,
          userEmail: cachedMember.userEmail,
          userAvatar: cachedMember.userAvatar,
          amountToPay: cachedMember.amountToPay,
          hasPaid: true,
          lastPaymentDate: paymentDate,
          dueDate: cachedMember.dueDate,
          createdAt: cachedMember.createdAt,
          updatedAt: DateTime.now(),
        );
        await _localDataSource.updateMember(updatedMember);
        debugPrint('   ✅ Local cache updated optimistically');
      }

      // Phase 2: Try remote update
      try {
        final remoteHistory = await _remoteDataSource.markPaymentAsPaid(
          subscriptionId: subscriptionId,
          memberId: memberId,
          amount: amount,
          paymentDate: paymentDate,
          markedBy: markedBy,
          notes: notes,
        );

        // Phase 3a: Success → cache confirmed data
        await _localDataSource.cachePaymentHistory(remoteHistory);
        debugPrint('   ✅ Remote update successful, history cached');

        return Right(remoteHistory.toEntity());
      } on SubscriptionRemoteException catch (e) {
        // Phase 3b: Remote failed → queue for sync
        debugPrint('   ⚠️ Remote update failed: $e');
        await _queuePaymentOperation(
          subscriptionId: subscriptionId,
          memberId: memberId,
          amount: amount,
          markedBy: markedBy,
          action: 'paid',
          notes: notes,
        );

        // Return optimistic result with generated ID
        const uuid = Uuid();
        final optimisticHistory = PaymentHistory(
          id: uuid.v4(),
          subscriptionId: subscriptionId,
          memberId: memberId,
          memberName: memberName,
          subscriptionName: subscriptionName,
          amount: amount,
          paymentDate: paymentDate,
          markedBy: markedBy,
          action: PaymentAction.paid,
          notes: notes,
          createdAt: DateTime.now(),
        );

        debugPrint('   📤 Operation queued for sync, returning optimistic result');
        return Right(optimisticHistory);
      }
    } catch (e) {
      debugPrint('   ❌ Unexpected error: $e');
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
    try {
      debugPrint('🔍 [SubscriptionRepository] Marking all payments as paid');
      debugPrint('   Subscription: $subscriptionId');

      // Phase 1: Optimistic update in local cache
      final cachedMembers = await _localDataSource
          .getMembersBySubscriptionId(subscriptionId);
      final unpaidMembers = cachedMembers.where((m) => !m.hasPaid).toList();

      debugPrint('   📊 Found ${unpaidMembers.length} unpaid members in cache');

      // Update all unpaid members locally
      for (final member in unpaidMembers) {
        final updatedMember = SubscriptionMemberModel(
          id: member.id,
          subscriptionId: member.subscriptionId,
          userId: member.userId,
          userName: member.userName,
          userEmail: member.userEmail,
          userAvatar: member.userAvatar,
          amountToPay: member.amountToPay,
          hasPaid: true,
          lastPaymentDate: paymentDate,
          dueDate: member.dueDate,
          createdAt: member.createdAt,
          updatedAt: DateTime.now(),
        );
        await _localDataSource.updateMember(updatedMember);
      }
      debugPrint('   ✅ Local cache updated optimistically');

      // Phase 2: Try remote update
      try {
        final count = await _remoteDataSource.markAllPaymentsAsPaid(
          subscriptionId: subscriptionId,
          paymentDate: paymentDate,
          markedBy: markedBy,
          notes: notes,
        );

        debugPrint('   ✅ Remote update successful: $count payments marked');
        return Right(count);
      } on SubscriptionRemoteException catch (e) {
        // Phase 3b: Remote failed → queue operations for sync
        debugPrint('   ⚠️ Remote update failed: $e');

        for (final member in unpaidMembers) {
          await _queuePaymentOperation(
            subscriptionId: subscriptionId,
            memberId: member.id,
            amount: member.amountToPay,
            markedBy: markedBy,
            action: 'paid',
            notes: notes,
          );
        }

        debugPrint('   📤 ${unpaidMembers.length} operations queued for sync');
        return Right(unpaidMembers.length);
      }
    } catch (e) {
      debugPrint('   ❌ Unexpected error: $e');
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
    try {
      debugPrint('🔍 [SubscriptionRepository] Unmarking payment');
      debugPrint('   Member: $memberId');

      // Phase 1: Optimistic update in local cache
      final cachedMember = await _localDataSource.getMemberById(memberId);
      final cachedSubscription = await _localDataSource.getSubscriptionById(subscriptionId);

      // Get member and subscription names for denormalization
      final memberName = cachedMember?.userName ?? 'Unknown Member';
      final subscriptionName = cachedSubscription?.name ?? 'Unknown Subscription';

      if (cachedMember != null) {
        final updatedMember = SubscriptionMemberModel(
          id: cachedMember.id,
          subscriptionId: cachedMember.subscriptionId,
          userId: cachedMember.userId,
          userName: cachedMember.userName,
          userEmail: cachedMember.userEmail,
          userAvatar: cachedMember.userAvatar,
          amountToPay: cachedMember.amountToPay,
          hasPaid: false,
          lastPaymentDate: cachedMember.lastPaymentDate,
          dueDate: cachedMember.dueDate,
          createdAt: cachedMember.createdAt,
          updatedAt: DateTime.now(),
        );
        await _localDataSource.updateMember(updatedMember);
        debugPrint('   ✅ Local cache updated optimistically');
      }

      // Phase 2: Try remote update
      try {
        final remoteHistory = await _remoteDataSource.unmarkPayment(
          subscriptionId: subscriptionId,
          memberId: memberId,
          amount: amount,
          paymentDate: paymentDate,
          markedBy: markedBy,
          notes: notes,
        );

        // Phase 3a: Success → cache confirmed data
        await _localDataSource.cachePaymentHistory(remoteHistory);
        debugPrint('   ✅ Remote update successful, history cached');

        return Right(remoteHistory.toEntity());
      } on SubscriptionRemoteException catch (e) {
        // Phase 3b: Remote failed → queue for sync
        debugPrint('   ⚠️ Remote update failed: $e');
        await _queuePaymentOperation(
          subscriptionId: subscriptionId,
          memberId: memberId,
          amount: amount,
          markedBy: markedBy,
          action: 'unpaid',
          notes: notes,
        );

        // Return optimistic result
        const uuid = Uuid();
        final optimisticHistory = PaymentHistory(
          id: uuid.v4(),
          subscriptionId: subscriptionId,
          memberId: memberId,
          memberName: memberName,
          subscriptionName: subscriptionName,
          amount: amount,
          paymentDate: paymentDate,
          markedBy: markedBy,
          action: PaymentAction.unpaid,
          notes: notes,
          createdAt: DateTime.now(),
        );

        debugPrint('   📤 Operation queued for sync, returning optimistic result');
        return Right(optimisticHistory);
      }
    } catch (e) {
      debugPrint('   ❌ Unexpected error: $e');
      return Left(SubscriptionFailure.paymentError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<PaymentHistory>>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
  }) async {
    try {
      debugPrint('🔍 [SubscriptionRepository] Fetching payment history');
      debugPrint('   Subscription: $subscriptionId');

      // Try remote first
      final remoteHistory = await _remoteDataSource.getPaymentHistory(
        subscriptionId: subscriptionId,
        memberId: memberId,
      );

      // Cache in Hive
      await _localDataSource.cachePaymentHistories(remoteHistory);

      debugPrint('   ✅ Fetched ${remoteHistory.length} records from remote');

      return Right(remoteHistory.map((h) => h.toEntity()).toList());
    } on SubscriptionRemoteException {
      // Fallback to local cache
      try {
        debugPrint('   ⚠️ Remote fetch failed, falling back to cache');
        final cachedHistory = memberId != null
            ? await _localDataSource.getPaymentHistoryByMemberId(memberId)
            : await _localDataSource.getPaymentHistoryBySubscriptionId(
                subscriptionId,
              );

        debugPrint('   📦 Fetched ${cachedHistory.length} records from cache');

        return Right(cachedHistory.map((h) => h.toEntity()).toList());
      } catch (localError) {
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      debugPrint('   ❌ Unexpected error: $e');
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  // ========== Helper Methods ==========

  /// Queue a payment operation for offline sync
  Future<void> _queuePaymentOperation({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy,
    required String action,
    String? notes,
  }) async {
    try {
      const uuid = Uuid();
      final syncQueue = PaymentSyncQueueService();
      await syncQueue.init();

      final operation = PaymentSyncOperation(
        id: uuid.v4(),
        memberId: memberId,
        subscriptionId: subscriptionId,
        amount: amount,
        markedBy: markedBy,
        action: action,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await syncQueue.enqueue(operation);
      debugPrint('   📤 Queued sync operation: ${operation.id}');
    } catch (e) {
      debugPrint('   ⚠️ Failed to queue sync operation: $e');
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
            userEmail: userEmail,
            userAvatar: userAvatar,
            amountToPay: subscription.costPerPerson,
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
      return const Left(SubscriptionFailure.networkError());
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
      return const Left(SubscriptionFailure.networkError());
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
    try {
      // Update in remote first
      final updatedModel = await _remoteDataSource.updateMemberAmount(
        memberId: memberId,
        amountToPay: newAmountToPay,
        hasPaid: resetPayment ? false : null, // null = don't update has_paid
      );

      // Update local cache
      await _localDataSource.updateMember(updatedModel);

      return Right(updatedModel.toEntity());
    } on SubscriptionRemoteException {
      return const Left(SubscriptionFailure.networkError());
    } catch (e) {
      return Left(SubscriptionFailure.memberError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, PaymentStats>> getPaymentStats({
    required String subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get stats from remote (calls RPC function)
      final stats = await _remoteDataSource.getPaymentStats(
        subscriptionId: subscriptionId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(stats);
    } on SubscriptionRemoteException {
      return const Left(SubscriptionFailure.networkError());
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
    // TODO: Implement after creating PdfGenerator service
    return const Left(SubscriptionFailure.serverError('PDF export not yet implemented'));
  }

  @override
  Future<Either<SubscriptionFailure, String>> exportPaymentHistoryCsv({
    required String subscriptionId,
    required String subscriptionName,
    required List<PaymentHistory> history,
  }) async {
    // TODO: Implement after creating CsvGenerator service
    return const Left(SubscriptionFailure.serverError('CSV export not yet implemented'));
  }

  @override
  Future<Either<SubscriptionFailure, AnalyticsData>> getAnalyticsData({
    required String userId,
    required TimeRange timeRange,
  }) async {
    try {
      debugPrint('🔍 [SubscriptionRepository] Fetching analytics data');
      debugPrint('   User: $userId');
      debugPrint('   Time Range: ${timeRange.displayName}');

      // Try remote first
      final analyticsModel = await _remoteDataSource.getAnalyticsData(
        userId: userId,
        timeRange: timeRange,
      );

      // Optional: Cache analytics data locally
      // await _localDataSource.cacheAnalyticsData(analyticsModel);

      debugPrint('✅ [SubscriptionRepository] Analytics data fetched successfully');
      return Right(analyticsModel.toEntity());
    } on SubscriptionRemoteException catch (e) {
      // Fallback: Calculate from cache
      debugPrint('   ⚠️ Remote fetch failed: $e');
      debugPrint('   📦 Calculating analytics from local cache...');

      try {
        final cachedAnalytics = await _calculateAnalyticsFromCache(
          userId,
          timeRange,
        );
        debugPrint('   ✅ Analytics calculated from cache');
        return Right(cachedAnalytics);
      } catch (localError) {
        debugPrint('   ❌ Cache calculation failed: $localError');
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      debugPrint('   ❌ Unexpected error: $e');
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  /// Calculate analytics from local cache (offline fallback)
  Future<AnalyticsData> _calculateAnalyticsFromCache(
    String userId,
    TimeRange timeRange,
  ) async {
    // Get cached subscriptions and members
    final subscriptions =
        await _localDataSource.getSubscriptionsByOwnerId(userId);
    final members = await _localDataSource.getMembersByOwnerId(userId);

    // Calculate overview from cached data
    final activeSubscriptions =
        subscriptions.where((s) => s.status == 'active').toList();

    final totalMonthlyCost = activeSubscriptions.fold<double>(
      0,
      (sum, sub) {
        final monthlyCost = sub.billingCycle == 'yearly'
            ? sub.totalCost / 12
            : sub.totalCost;
        return sum + monthlyCost;
      },
    );

    final totalMembers = members.length;

    final averageCostPerSubscription = activeSubscriptions.isEmpty
        ? 0.0
        : totalMonthlyCost / activeSubscriptions.length;

    // For offline mode, we can't calculate payment history analytics
    // So we return empty/default values
    return AnalyticsData(
      overview: AnalyticsOverview(
        totalMonthlyCost: totalMonthlyCost,
        totalActiveSubscriptions: activeSubscriptions.length,
        totalMembers: totalMembers,
        averageCostPerSubscription: averageCostPerSubscription,
      ),
      spendingTrends: [], // Can't calculate without payment history
      subscriptionSpending: [], // Can't calculate without payment history
      paymentAnalytics: PaymentAnalytics.empty(),
    );
  }
}
