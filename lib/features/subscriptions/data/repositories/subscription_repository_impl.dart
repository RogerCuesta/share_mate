import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_orchestrator.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/core/sync/sync_logger.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
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
import 'package:flutter_project_agents/features/subscriptions/domain/services/split_calculator.dart';
import 'package:uuid/uuid.dart';

/// Implementation of SubscriptionRepository with offline-first strategy
///
/// This repository tries Supabase first, then falls back to Hive cache on errors.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required SubscriptionLocalDataSource localDataSource,
    PaymentSyncOrchestrator? syncOrchestrator,
    BillingAutomationOrchestrator? billingAutomationOrchestrator,
    SyncLogger syncLogger = const SyncLogger(scope: 'SubscriptionRepository'),
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _syncOrchestrator = syncOrchestrator,
        _billingAutomationOrchestrator = billingAutomationOrchestrator,
        _syncLogger = syncLogger;
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SubscriptionLocalDataSource _localDataSource;
  final PaymentSyncOrchestrator? _syncOrchestrator;
  final BillingAutomationOrchestrator? _billingAutomationOrchestrator;
  final SyncLogger _syncLogger;

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
      _triggerBillingAutomationRefresh(reason: 'subscription_created');

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
      _triggerBillingAutomationRefresh(reason: 'subscription_updated');

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
      _triggerBillingAutomationRefresh(reason: 'subscription_deleted');

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
      _syncLogger.logSync(
        event: 'repository_mark_paid_started',
        actionType: 'paid',
        metadata: {'layer': 'repository'},
      );

      // Phase 1: Optimistic update in local cache
      final cachedMember = await _localDataSource.getMemberById(memberId);
      final cachedSubscription =
          await _localDataSource.getSubscriptionById(subscriptionId);

      // Get member and subscription names for denormalization
      final memberName = cachedMember?.userName ?? 'Unknown Member';
      final subscriptionName =
          cachedSubscription?.name ?? 'Unknown Subscription';

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
        _syncLogger.logSync(
          event: 'repository_mark_paid_local_updated',
          actionType: 'paid',
          metadata: {'layer': 'repository'},
        );
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
        _syncLogger.logSync(
          event: 'repository_mark_paid_remote_success',
          actionType: 'paid',
          metadata: {'layer': 'repository'},
        );
        _triggerSyncAfterRemoteWrite();

        return Right(remoteHistory.toEntity());
      } on SubscriptionRemoteException catch (e) {
        // Phase 3b: Remote failed → queue for sync
        final queuedOperationId = await _queuePaymentOperation(
          subscriptionId: subscriptionId,
          memberId: memberId,
          amount: amount,
          markedBy: markedBy,
          action: 'paid',
          cycleDueDate: _resolveCycleDueDate(
            memberDueDate: cachedMember?.dueDate,
            subscriptionDueDate: cachedSubscription?.dueDate,
            paymentDate: paymentDate,
          ),
          notes: notes,
          initialErrorClass: 'remote_write_failed',
          initialErrorCode: _extractRemoteErrorCode(e.message),
          lastAttemptAt: DateTime.now(),
        );
        if (queuedOperationId != null) {
          _syncLogger.logRetry(
            event: 'repository_mark_paid_remote_failed_queued',
            operationId: queuedOperationId,
            retryCount: 0,
            metadata: {'layer': 'repository'},
          );
        }

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

        _syncLogger.logSync(
          event: 'repository_mark_paid_optimistic_return',
          actionType: 'paid',
          metadata: {'layer': 'repository'},
        );
        return Right(optimisticHistory);
      }
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'repository_mark_paid_exception',
        operationId: 'repository_mark_paid_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
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
      _syncLogger.logSync(
        event: 'repository_mark_all_paid_started',
        actionType: 'paid_bulk',
        metadata: {'layer': 'repository'},
      );

      // Phase 1: Optimistic update in local cache
      final cachedMembers =
          await _localDataSource.getMembersBySubscriptionId(subscriptionId);
      final unpaidMembers = cachedMembers.where((m) => !m.hasPaid).toList();

      _syncLogger.logSync(
        event: 'repository_mark_all_paid_unpaid_loaded',
        actionType: 'paid_bulk',
        metadata: {'layer': 'repository', 'unpaid_count': unpaidMembers.length},
      );

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
      _syncLogger.logSync(
        event: 'repository_mark_all_paid_local_updated',
        actionType: 'paid_bulk',
        metadata: {'layer': 'repository'},
      );

      // Phase 2: Try remote update
      try {
        final count = await _remoteDataSource.markAllPaymentsAsPaid(
          subscriptionId: subscriptionId,
          paymentDate: paymentDate,
          markedBy: markedBy,
          notes: notes,
        );

        _syncLogger.logSync(
          event: 'repository_mark_all_paid_remote_success',
          actionType: 'paid_bulk',
          metadata: {'layer': 'repository', 'updated_count': count},
        );
        _triggerSyncAfterRemoteWrite();
        return Right(count);
      } on SubscriptionRemoteException catch (e) {
        // Phase 3b: Remote failed → queue operations for sync
        var queuedCount = 0;

        for (final member in unpaidMembers) {
          final operationId = await _queuePaymentOperation(
            subscriptionId: subscriptionId,
            memberId: member.id,
            amount: member.amountToPay,
            markedBy: markedBy,
            action: 'paid',
            cycleDueDate: member.dueDate,
            notes: notes,
            initialErrorClass: 'remote_write_failed',
            initialErrorCode: _extractRemoteErrorCode(e.message),
            lastAttemptAt: DateTime.now(),
          );
          if (operationId != null) {
            queuedCount += 1;
          }
        }

        _syncLogger.logRetry(
          event: 'repository_mark_all_paid_remote_failed_queued',
          operationId: 'bulk_paid_queue',
          retryCount: 0,
          metadata: {'layer': 'repository', 'queued_count': queuedCount},
        );
        return Right(unpaidMembers.length);
      }
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'repository_mark_all_paid_exception',
        operationId: 'repository_mark_all_paid_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
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
      _syncLogger.logSync(
        event: 'repository_unmark_started',
        actionType: 'unpaid',
        metadata: {'layer': 'repository'},
      );

      // Phase 1: Optimistic update in local cache
      final cachedMember = await _localDataSource.getMemberById(memberId);
      final cachedSubscription =
          await _localDataSource.getSubscriptionById(subscriptionId);

      // Get member and subscription names for denormalization
      final memberName = cachedMember?.userName ?? 'Unknown Member';
      final subscriptionName =
          cachedSubscription?.name ?? 'Unknown Subscription';

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
        _syncLogger.logSync(
          event: 'repository_unmark_local_updated',
          actionType: 'unpaid',
          metadata: {'layer': 'repository'},
        );
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
        _syncLogger.logSync(
          event: 'repository_unmark_remote_success',
          actionType: 'unpaid',
          metadata: {'layer': 'repository'},
        );
        _triggerSyncAfterRemoteWrite();

        return Right(remoteHistory.toEntity());
      } on SubscriptionRemoteException catch (e) {
        // Phase 3b: Remote failed → queue for sync
        final queuedOperationId = await _queuePaymentOperation(
          subscriptionId: subscriptionId,
          memberId: memberId,
          amount: amount,
          markedBy: markedBy,
          action: 'unpaid',
          cycleDueDate: _resolveCycleDueDate(
            memberDueDate: cachedMember?.dueDate,
            subscriptionDueDate: cachedSubscription?.dueDate,
            paymentDate: paymentDate,
          ),
          notes: notes,
          initialErrorClass: 'remote_write_failed',
          initialErrorCode: _extractRemoteErrorCode(e.message),
          lastAttemptAt: DateTime.now(),
        );
        if (queuedOperationId != null) {
          _syncLogger.logRetry(
            event: 'repository_unmark_remote_failed_queued',
            operationId: queuedOperationId,
            retryCount: 0,
            metadata: {'layer': 'repository'},
          );
        }

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

        _syncLogger.logSync(
          event: 'repository_unmark_optimistic_return',
          actionType: 'unpaid',
          metadata: {'layer': 'repository'},
        );
        return Right(optimisticHistory);
      }
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'repository_unmark_exception',
        operationId: 'repository_unmark_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
      return Left(SubscriptionFailure.paymentError(e.toString()));
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<PaymentHistory>>> getPaymentHistory({
    required String subscriptionId,
    String? memberId,
  }) async {
    try {
      _syncLogger.logSync(
        event: 'repository_payment_history_fetch_started',
        metadata: {'layer': 'repository'},
      );

      // Try remote first
      final remoteHistory = await _remoteDataSource.getPaymentHistory(
        subscriptionId: subscriptionId,
        memberId: memberId,
      );

      // Cache in Hive
      await _localDataSource.cachePaymentHistories(remoteHistory);

      _syncLogger.logSync(
        event: 'repository_payment_history_fetch_remote_success',
        metadata: {
          'layer': 'repository',
          'record_count': remoteHistory.length,
        },
      );

      return Right(remoteHistory.map((h) => h.toEntity()).toList());
    } on SubscriptionRemoteException {
      // Fallback to local cache
      try {
        _syncLogger.logRetry(
          event: 'repository_payment_history_fetch_remote_failed',
          operationId: 'payment_history_fetch',
          retryCount: 0,
          metadata: {'layer': 'repository', 'fallback': 'local_cache'},
        );
        final cachedHistory = memberId != null
            ? await _localDataSource.getPaymentHistoryByMemberId(memberId)
            : await _localDataSource.getPaymentHistoryBySubscriptionId(
                subscriptionId,
              );

        _syncLogger.logSync(
          event: 'repository_payment_history_fetch_cache_success',
          metadata: {
            'layer': 'repository',
            'record_count': cachedHistory.length,
          },
        );

        return Right(cachedHistory.map((h) => h.toEntity()).toList());
      } catch (localError) {
        return Left(SubscriptionFailure.cacheError(localError.toString()));
      }
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'repository_payment_history_fetch_exception',
        operationId: 'payment_history_fetch_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
      return Left(SubscriptionFailure.serverError(e.toString()));
    }
  }

  // ========== Helper Methods ==========

  /// Queue a payment operation for offline sync
  Future<String?> _queuePaymentOperation({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy,
    required String action,
    required DateTime cycleDueDate,
    String? notes,
    String? initialErrorClass,
    String? initialErrorCode,
    DateTime? lastAttemptAt,
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
        nextAttemptAt: DateTime.now(),
        lastAttemptAt: lastAttemptAt,
        lastErrorClass: initialErrorClass,
        lastErrorCode: initialErrorCode,
        cycleDueDate: cycleDueDate,
        idempotencyKey: _buildIdempotencyKey(
          subscriptionId: subscriptionId,
          memberId: memberId,
          action: action,
          cycleDueDate: cycleDueDate,
        ),
      );

      await syncQueue.enqueue(operation);
      _syncLogger.logSync(
        event: 'repository_queue_operation_enqueued',
        operationId: operation.id,
        actionType: action,
        metadata: {'layer': 'repository'},
      );
      return operation.id;
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'repository_queue_operation_failed',
        operationId: 'repository_queue_operation_failed',
        terminalReason: 'queue_enqueue_failed',
        errorClass: e.runtimeType.toString(),
      );
      return null;
    }
  }

  void _triggerSyncAfterRemoteWrite() {
    final orchestrator = _syncOrchestrator;
    if (orchestrator == null) {
      return;
    }
    unawaited(
      orchestrator.triggerSync(reason: 'post_remote_write'),
    );
  }

  void _triggerBillingAutomationRefresh({
    required String reason,
  }) {
    final billingAutomationOrchestrator = _billingAutomationOrchestrator;
    if (billingAutomationOrchestrator == null) {
      return;
    }
    unawaited(billingAutomationOrchestrator.run(reason: reason));
  }

  String? _extractRemoteErrorCode(String message) {
    final codeMatch = RegExp(r'code[:=\s]+([a-z0-9_]+)', caseSensitive: false)
        .firstMatch(message);
    if (codeMatch != null) {
      return codeMatch.group(1);
    }

    final statusMatch = RegExp(r'\b([45]\d{2})\b').firstMatch(message);
    if (statusMatch != null) {
      return statusMatch.group(1);
    }

    return null;
  }

  DateTime _resolveCycleDueDate({
    required DateTime paymentDate,
    DateTime? memberDueDate,
    DateTime? subscriptionDueDate,
  }) {
    return memberDueDate ?? subscriptionDueDate ?? paymentDate;
  }

  String _buildIdempotencyKey({
    required String subscriptionId,
    required String memberId,
    required String action,
    required DateTime cycleDueDate,
  }) {
    final cycleAnchor = cycleDueDate.toUtc().toIso8601String();
    return 'sync:$action:$subscriptionId:$memberId:$cycleAnchor';
  }

  String? _normalizeOptionalEmail(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<double> _resolveDefaultMemberAmount({
    required String subscriptionId,
    required Subscription subscription,
  }) async {
    final membersResult = await getSubscriptionMembers(subscriptionId);
    final existingMembers = membersResult.getOrElse(
      () => const <SubscriptionMember>[],
    );

    final splitResult = const SplitCalculator().calculate(
      totalAmount: subscription.totalCost,
      members: [
        for (final member in existingMembers)
          SplitParticipantInput(id: member.userId, name: member.userName),
        const SplitParticipantInput(id: '__pending_member__', name: 'pending'),
      ],
    );
    return splitResult.memberAmount;
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionMember>>
      addMemberToSubscription({
    required String subscriptionId,
    required String userId,
    required String userName,
    String? userEmail,
    String? userAvatar,
    double? amountToPay,
  }) async {
    try {
      // Get subscription to derive default amount when not explicitly provided.
      final subscriptionResult = await getSubscriptionById(subscriptionId);

      return subscriptionResult.fold(
        (failure) => Left(failure),
        (subscription) async {
          final resolvedAmount = amountToPay ??
              await _resolveDefaultMemberAmount(
                subscriptionId: subscriptionId,
                subscription: subscription,
              );
          final normalizedEmail = _normalizeOptionalEmail(userEmail);
          final member = SubscriptionMember(
            id: '', // Will be generated by Supabase
            subscriptionId: subscriptionId,
            userId: userId,
            userName: userName,
            userEmail: normalizedEmail,
            userAvatar: userAvatar,
            amountToPay: resolvedAmount,
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
    return const Left(
        SubscriptionFailure.serverError('PDF export not yet implemented'));
  }

  @override
  Future<Either<SubscriptionFailure, String>> exportPaymentHistoryCsv({
    required String subscriptionId,
    required String subscriptionName,
    required List<PaymentHistory> history,
  }) async {
    // TODO: Implement after creating CsvGenerator service
    return const Left(
        SubscriptionFailure.serverError('CSV export not yet implemented'));
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

      debugPrint(
          '✅ [SubscriptionRepository] Analytics data fetched successfully');
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
        final monthlyCost =
            sub.billingCycle == 'yearly' ? sub.totalCost / 12 : sub.totalCost;
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
