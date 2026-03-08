import 'dart:io';

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/hive_type_ids.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('PaymentSyncQueueService', () {
    late Directory hiveDir;
    late PaymentSyncQueueService queueService;
    late List<int> encryptionKey;

    PaymentSyncOperation buildOperation({
      required String id,
      required DateTime createdAt,
      DateTime? nextAttemptAt,
      int retryCount = 0,
      String status = paymentSyncStatusPending,
    }) {
      return PaymentSyncOperation(
        id: id,
        memberId: 'member-$id',
        subscriptionId: 'subscription-$id',
        amount: 9.99,
        markedBy: 'owner-id',
        action: 'paid',
        createdAt: createdAt,
        nextAttemptAt: nextAttemptAt,
        retryCount: retryCount,
        status: status,
      );
    }

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'payment_sync_queue_service_test',
      );
      Hive.init(hiveDir.path);
      if (!Hive.isAdapterRegistered(HiveTypeIds.paymentSyncQueue)) {
        Hive.registerAdapter(PaymentSyncOperationAdapter());
      }

      encryptionKey = Hive.generateSecureKey();
      HiveService.clearKeyFailureSafeModeForTesting();
      HiveService.overrideEncryptionKeyProviderForTesting(
        () async => encryptionKey,
      );

      queueService = PaymentSyncQueueService();
      await queueService.init();
    });

    tearDown(() async {
      HiveService.overrideEncryptionKeyProviderForTesting(null);
      HiveService.clearKeyFailureSafeModeForTesting();
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('reads pending operations by createdAt order and retry schedule',
        () async {
      final now = DateTime(2026, 1, 10, 12);
      final older = buildOperation(
        id: 'older',
        createdAt: now.subtract(const Duration(minutes: 2)),
      );
      final newer = buildOperation(
        id: 'newer',
        createdAt: now.subtract(const Duration(minutes: 1)),
        nextAttemptAt: now.add(const Duration(minutes: 1)),
      );

      await queueService.enqueue(newer);
      await queueService.enqueue(older);

      final dueNow = await queueService.getPendingOrdered(asOf: now);
      expect(dueNow.map((operation) => operation.id), equals(['older']));

      final dueLater = await queueService.getPendingOrdered(
        asOf: now.add(const Duration(minutes: 5)),
      );
      expect(
        dueLater.map((operation) => operation.id),
        equals(['older', 'newer']),
      );
    });

    test('marks processing and schedules retry metadata', () async {
      final createdAt = DateTime(2026, 1, 10, 12);
      final operation = buildOperation(id: 'retry-op', createdAt: createdAt);
      await queueService.enqueue(operation);

      final attemptedAt = createdAt.add(const Duration(minutes: 1));
      await queueService.markProcessing(
        operation.id,
        attemptedAt: attemptedAt,
      );

      final processingOperation = Hive.box<PaymentSyncOperation>(
        'payment_sync_queue',
      ).get(operation.id);
      expect(processingOperation, isNotNull);
      expect(processingOperation!.status, paymentSyncStatusProcessing);
      expect(processingOperation.lastAttemptAt, attemptedAt);

      final nextAttemptAt = createdAt.add(const Duration(minutes: 3));
      await queueService.scheduleRetry(
        operation.id,
        retryCount: 2,
        nextAttemptAt: nextAttemptAt,
        lastAttemptAt: attemptedAt,
        lastErrorClass: 'retryable',
        lastErrorCode: 'network',
      );

      final retriedOperation = Hive.box<PaymentSyncOperation>(
        'payment_sync_queue',
      ).get(operation.id);
      expect(retriedOperation, isNotNull);
      expect(retriedOperation!.status, paymentSyncStatusPending);
      expect(retriedOperation.retryCount, 2);
      expect(retriedOperation.nextAttemptAt, nextAttemptAt);
      expect(retriedOperation.lastAttemptAt, attemptedAt);
      expect(retriedOperation.lastErrorClass, 'retryable');
      expect(retriedOperation.lastErrorCode, 'network');
      expect(retriedOperation.terminalReason, isNull);
      expect(retriedOperation.terminalAt, isNull);
    });

    test('moves exhausted operation to terminal partition', () async {
      final operation = buildOperation(
        id: 'terminal-op',
        createdAt: DateTime(2026, 1, 10, 12),
      );
      await queueService.enqueue(operation);

      final terminalAt = DateTime(2026, 1, 10, 12, 10);
      await queueService.markTerminal(
        operation.id,
        retryCount: 5,
        terminalReason: 'max_attempts_exhausted',
        terminalAt: terminalAt,
        lastErrorClass: 'retryable',
        lastErrorCode: 'timeout',
      );

      final pending = await queueService.getPendingOrdered(
        asOf: terminalAt.add(const Duration(minutes: 1)),
      );
      final terminal = await queueService.getTerminal();

      expect(pending, isEmpty);
      expect(terminal.length, 1);
      expect(terminal.first.id, operation.id);
      expect(terminal.first.status, paymentSyncStatusTerminal);
      expect(terminal.first.terminalReason, 'max_attempts_exhausted');
      expect(queueService.pendingCount, 0);
      expect(queueService.terminalCount, 1);
    });

    test('retryTerminal requeues terminal operations with cleared metadata',
        () async {
      final createdAt = DateTime(2026, 1, 10, 12);
      final operation =
          buildOperation(id: 'manual-retry', createdAt: createdAt);
      await queueService.enqueue(operation);
      await queueService.markTerminal(
        operation.id,
        retryCount: 5,
        terminalReason: 'manual_action_required',
        terminalAt: createdAt.add(const Duration(minutes: 5)),
        lastErrorClass: 'terminal',
        lastErrorCode: '400',
      );

      final retryAt = createdAt.add(const Duration(minutes: 6));
      final retriedCount = await queueService.retryTerminal(retryAt: retryAt);
      expect(retriedCount, 1);

      final retried = Hive.box<PaymentSyncOperation>('payment_sync_queue')
          .get(operation.id);
      expect(retried, isNotNull);
      expect(retried!.status, paymentSyncStatusPending);
      expect(retried.retryCount, 0);
      expect(retried.nextAttemptAt, retryAt);
      expect(retried.lastErrorClass, isNull);
      expect(retried.lastErrorCode, isNull);
      expect(retried.terminalReason, isNull);
      expect(retried.terminalAt, isNull);
      expect(queueService.pendingCount, 1);
      expect(queueService.terminalCount, 0);
    });

    test('clearTerminalOnly deletes dead-letter rows and preserves pending',
        () async {
      final baseTime = DateTime(2026, 1, 10, 12);
      final pendingOperation = buildOperation(
        id: 'pending-op',
        createdAt: baseTime,
      );
      final terminalOperation = buildOperation(
        id: 'terminal-op',
        createdAt: baseTime.add(const Duration(minutes: 1)),
      );

      await queueService.enqueue(pendingOperation);
      await queueService.enqueue(terminalOperation);
      await queueService.markTerminal(
        terminalOperation.id,
        retryCount: 5,
        terminalReason: 'max_attempts_exhausted',
      );

      final deletedCount = await queueService.clearTerminalOnly();
      expect(deletedCount, 1);

      final box = Hive.box<PaymentSyncOperation>('payment_sync_queue');
      expect(box.get(pendingOperation.id), isNotNull);
      expect(box.get(terminalOperation.id), isNull);
      expect(queueService.pendingCount, 1);
      expect(queueService.terminalCount, 0);
    });
  });
}
