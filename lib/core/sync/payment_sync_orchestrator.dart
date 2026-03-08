import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/core/sync/sync_error_classifier.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';

class PaymentSyncOrchestrator {
  PaymentSyncOrchestrator({
    required PaymentSyncQueueService queueService,
    required SubscriptionRemoteDataSource remoteDataSource,
    SyncErrorClassifier errorClassifier = const SyncErrorClassifier(),
    DateTime Function()? now,
    Random? random,
    this.maxAttempts = 5,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 1),
    this.maxJitter = const Duration(milliseconds: 400),
    this.minForegroundTriggerInterval = const Duration(seconds: 30),
  })  : _queueService = queueService,
        _remoteDataSource = remoteDataSource,
        _errorClassifier = errorClassifier,
        _clock = now ?? DateTime.now,
        _random = random ?? Random();

  static const String foregroundIntervalReason = 'foreground_interval';

  final PaymentSyncQueueService _queueService;
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SyncErrorClassifier _errorClassifier;
  final DateTime Function() _clock;
  final Random _random;

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Duration maxJitter;
  final Duration minForegroundTriggerInterval;

  bool _started = false;
  bool _singleFlight = false;
  bool _rerunRequested = false;
  DateTime? _lastForegroundTriggerAt;

  DateTime? lastSuccessfulSyncAt;

  bool get isStarted => _started;
  bool get singleFlightInProgress => _singleFlight;

  Future<void> start() async {
    if (_started) {
      return;
    }
    await _queueService.init();
    _started = true;
  }

  Future<void> stop() async {
    _started = false;
  }

  Future<void> triggerSync({
    String reason = 'manual',
    bool force = false,
  }) async {
    if (!_started) {
      return;
    }

    final now = _clock();
    if (!force && _shouldThrottleForegroundTrigger(now, reason)) {
      return;
    }

    if (reason == foregroundIntervalReason) {
      _lastForegroundTriggerAt = now;
    }

    if (_singleFlight) {
      _rerunRequested = true;
      return;
    }

    _singleFlight = true;
    try {
      do {
        _rerunRequested = false;
        await _drainReadyQueue();
      } while (_rerunRequested);
    } finally {
      _singleFlight = false;
    }
  }

  bool _shouldThrottleForegroundTrigger(DateTime now, String reason) {
    if (reason != foregroundIntervalReason) {
      return false;
    }
    final lastTrigger = _lastForegroundTriggerAt;
    if (lastTrigger == null) {
      return false;
    }
    final elapsed = now.difference(lastTrigger);
    return elapsed < minForegroundTriggerInterval;
  }

  Future<void> _drainReadyQueue() async {
    while (_started) {
      final pendingOperations = await _queueService.getPendingOrdered(
        asOf: _clock(),
      );
      if (pendingOperations.isEmpty) {
        return;
      }

      pendingOperations.sort((a, b) {
        final createdAtComparison = a.createdAt.compareTo(b.createdAt);
        if (createdAtComparison != 0) {
          return createdAtComparison;
        }
        return a.id.compareTo(b.id);
      });

      for (final operation in pendingOperations) {
        await _processOperation(operation);
      }
    }
  }

  Future<void> _processOperation(PaymentSyncOperation operation) async {
    final attemptedAt = _clock();
    await _queueService.markProcessing(
      operation.id,
      attemptedAt: attemptedAt,
    );

    try {
      await _applyRemoteMutation(operation);
      await _queueService.markSynced(operation.id);
      lastSuccessfulSyncAt = attemptedAt;
    } catch (error, stackTrace) {
      final classification = _errorClassifier.classify(
        error,
        stackTrace: stackTrace,
      );
      final currentAttempt = operation.retryCount + 1;

      final shouldRetry =
          classification.isRetryable && currentAttempt < maxAttempts;
      if (shouldRetry) {
        final delay = _calculateExponentialBackoffWithJitter(currentAttempt);
        final nextAttemptAt = attemptedAt.add(delay);
        await _queueService.scheduleRetry(
          operation.id,
          retryCount: currentAttempt,
          nextAttemptAt: nextAttemptAt,
          lastAttemptAt: attemptedAt,
          lastErrorClass: classification.errorClass,
          lastErrorCode: classification.errorCode,
        );
        debugPrint(
          '🔁 [PaymentSyncOrchestrator] Scheduled retry for ${operation.id} '
          '(attempt $currentAttempt/$maxAttempts, next: $nextAttemptAt)',
        );
        return;
      }

      await _queueService.markTerminal(
        operation.id,
        retryCount: currentAttempt,
        terminalReason: classification.terminalReason,
        terminalAt: attemptedAt,
        lastAttemptAt: attemptedAt,
        lastErrorClass: classification.errorClass,
        lastErrorCode: classification.errorCode,
      );
      debugPrint(
        '🛑 [PaymentSyncOrchestrator] Operation moved to terminal partition: '
        '${operation.id} (${classification.terminalReason})',
      );
    }
  }

  Future<void> _applyRemoteMutation(PaymentSyncOperation operation) async {
    if (operation.action == 'paid') {
      await _remoteDataSource.markPaymentAsPaid(
        subscriptionId: operation.subscriptionId,
        memberId: operation.memberId,
        amount: operation.amount,
        paymentDate: operation.createdAt,
        markedBy: operation.markedBy,
        notes: operation.notes,
      );
      return;
    }

    if (operation.action == 'unpaid') {
      await _remoteDataSource.unmarkPayment(
        subscriptionId: operation.subscriptionId,
        memberId: operation.memberId,
        amount: operation.amount,
        paymentDate: operation.createdAt,
        markedBy: operation.markedBy,
        notes: operation.notes,
      );
      return;
    }

    throw StateError('Unsupported sync action: ${operation.action}');
  }

  Duration _calculateExponentialBackoffWithJitter(int attempt) {
    final exponent = attempt <= 1 ? 0 : attempt - 1;
    final exponentialMilliseconds =
        baseDelay.inMilliseconds * pow(2, exponent).toInt();
    final cappedMilliseconds = min(
      exponentialMilliseconds,
      maxDelay.inMilliseconds,
    );
    final jitterMilliseconds = maxJitter.inMilliseconds <= 0
        ? 0
        : _random.nextInt(maxJitter.inMilliseconds + 1);
    return Duration(milliseconds: cappedMilliseconds + jitterMilliseconds);
  }
}
