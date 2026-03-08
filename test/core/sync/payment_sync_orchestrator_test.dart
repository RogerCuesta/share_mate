import 'dart:async';
import 'dart:math';

import 'package:flutter_project_agents/core/sync/payment_sync_orchestrator.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_history_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentSyncQueueService extends Mock
    implements PaymentSyncQueueService {}

class MockSubscriptionRemoteDataSource extends Mock
    implements SubscriptionRemoteDataSource {}

class FakePaymentSyncOperation extends Fake implements PaymentSyncOperation {}

void main() {
  group('PaymentSyncOrchestrator', () {
    late MockPaymentSyncQueueService mockQueueService;
    late MockSubscriptionRemoteDataSource mockRemoteDataSource;

    PaymentHistoryModel buildHistory(String id) {
      final now = DateTime(2026, 1, 10, 12);
      return PaymentHistoryModel(
        id: id,
        subscriptionId: 'subscription-id',
        memberId: 'member-id',
        memberName: 'Member',
        subscriptionName: 'Subscription',
        amount: 9.99,
        paymentDate: now,
        markedBy: 'owner-id',
        action: 'paid',
        createdAt: now,
      );
    }

    PaymentSyncOperation buildOperation({
      required String id,
      required DateTime createdAt,
      int retryCount = 0,
      String action = 'paid',
      DateTime? cycleDueDate,
    }) {
      return PaymentSyncOperation(
        id: id,
        memberId: 'member-$id',
        subscriptionId: 'subscription-$id',
        amount: 12.50,
        markedBy: 'owner-id',
        action: action,
        createdAt: createdAt,
        retryCount: retryCount,
        cycleDueDate: cycleDueDate ?? DateTime(2026, 1, 1),
      );
    }

    setUpAll(() {
      registerFallbackValue(FakePaymentSyncOperation());
      registerFallbackValue(DateTime(2026, 1, 1));
    });

    setUp(() {
      mockQueueService = MockPaymentSyncQueueService();
      mockRemoteDataSource = MockSubscriptionRemoteDataSource();

      when(() => mockQueueService.init()).thenAnswer((_) async {});
      when(
        () => mockQueueService.getPendingOrdered(
          asOf: any(named: 'asOf'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockQueueService.markProcessing(
          any(),
          attemptedAt: any(named: 'attemptedAt'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockQueueService.markSynced(any())).thenAnswer((_) async {});
      when(
        () => mockQueueService.scheduleRetry(
          any(),
          retryCount: any(named: 'retryCount'),
          nextAttemptAt: any(named: 'nextAttemptAt'),
          lastAttemptAt: any(named: 'lastAttemptAt'),
          lastErrorClass: any(named: 'lastErrorClass'),
          lastErrorCode: any(named: 'lastErrorCode'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockQueueService.markTerminal(
          any(),
          retryCount: any(named: 'retryCount'),
          terminalReason: any(named: 'terminalReason'),
          terminalAt: any(named: 'terminalAt'),
          lastAttemptAt: any(named: 'lastAttemptAt'),
          lastErrorClass: any(named: 'lastErrorClass'),
          lastErrorCode: any(named: 'lastErrorCode'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => buildHistory('history-paid'));
      when(
        () => mockRemoteDataSource.unmarkPayment(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => buildHistory('history-unpaid'));
      when(
        () => mockRemoteDataSource.getPaymentSyncMemberCycleContext(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
        ),
      ).thenAnswer(
        (_) async => PaymentSyncMemberCycleContext(
          cycleDueDate: DateTime(2026, 1, 1),
          hasPaid: false,
        ),
      );
      when(
        () => mockRemoteDataSource.recordPaymentSyncConflictAudit(
          operationId: any(named: 'operationId'),
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          action: any(named: 'action'),
          terminalReason: any(named: 'terminalReason'),
          queuedCycleDueDate: any(named: 'queuedCycleDueDate'),
          backendCycleDueDate: any(named: 'backendCycleDueDate'),
          retryCount: any(named: 'retryCount'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {});
    });

    test('drains queue deterministically and continues when one op is terminal',
        () async {
      final baseTime = DateTime(2026, 1, 10, 12);
      final older = buildOperation(
        id: 'older',
        createdAt: baseTime.subtract(const Duration(minutes: 2)),
      );
      final newer = buildOperation(
        id: 'newer',
        createdAt: baseTime.subtract(const Duration(minutes: 1)),
      );

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(
          asOf: any(named: 'asOf'),
        ),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [newer, older];
        }
        return <PaymentSyncOperation>[];
      });

      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: older.subscriptionId,
          memberId: older.memberId,
          amount: older.amount,
          paymentDate: older.createdAt,
          markedBy: older.markedBy,
          notes: older.notes,
          idempotencyKey: older.idempotencyKey,
        ),
      ).thenThrow(
        SubscriptionRemoteException('permission denied code 42501'),
      );

      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: newer.subscriptionId,
          memberId: newer.memberId,
          amount: newer.amount,
          paymentDate: newer.createdAt,
          markedBy: newer.markedBy,
          notes: newer.notes,
          idempotencyKey: newer.idempotencyKey,
        ),
      ).thenAnswer((_) async => buildHistory('history-newer'));

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
        now: () => baseTime,
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      verifyInOrder([
        () => mockQueueService.markProcessing(
              older.id,
              attemptedAt: any(named: 'attemptedAt'),
            ),
        () => mockRemoteDataSource.markPaymentAsPaid(
              subscriptionId: older.subscriptionId,
              memberId: older.memberId,
              amount: older.amount,
              paymentDate: older.createdAt,
              markedBy: older.markedBy,
              notes: older.notes,
              idempotencyKey: older.idempotencyKey,
            ),
        () => mockQueueService.markTerminal(
              older.id,
              retryCount: 1,
              terminalReason: 'non_retryable_remote_failure',
              terminalAt: any(named: 'terminalAt'),
              lastAttemptAt: any(named: 'lastAttemptAt'),
              lastErrorClass: 'remote_terminal',
              lastErrorCode: '42501',
            ),
        () => mockQueueService.markProcessing(
              newer.id,
              attemptedAt: any(named: 'attemptedAt'),
            ),
        () => mockRemoteDataSource.markPaymentAsPaid(
              subscriptionId: newer.subscriptionId,
              memberId: newer.memberId,
              amount: newer.amount,
              paymentDate: newer.createdAt,
              markedBy: newer.markedBy,
              notes: newer.notes,
              idempotencyKey: newer.idempotencyKey,
            ),
        () => mockQueueService.markSynced(newer.id),
      ]);

      verifyNever(() => mockQueueService.markSynced(older.id));
    });

    test('schedules exponential retry with jitter for transient failures',
        () async {
      final fixedNow = DateTime(2026, 1, 10, 12);
      final operation = buildOperation(
        id: 'retryable',
        createdAt: fixedNow.subtract(const Duration(minutes: 1)),
      );

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(
          asOf: any(named: 'asOf'),
        ),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });

      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
          amount: operation.amount,
          paymentDate: operation.createdAt,
          markedBy: operation.markedBy,
          notes: operation.notes,
          idempotencyKey: operation.idempotencyKey,
        ),
      ).thenThrow(TimeoutException('socket timeout'));

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
        now: () => fixedNow,
        random: Random(0),
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      final captured = verify(
        () => mockQueueService.scheduleRetry(
          operation.id,
          retryCount: captureAny(named: 'retryCount'),
          nextAttemptAt: captureAny(named: 'nextAttemptAt'),
          lastAttemptAt: captureAny(named: 'lastAttemptAt'),
          lastErrorClass: captureAny(named: 'lastErrorClass'),
          lastErrorCode: captureAny(named: 'lastErrorCode'),
        ),
      ).captured;

      expect(captured[0], 1);
      final nextAttemptAt = captured[1] as DateTime;
      final retryDelay = nextAttemptAt.difference(fixedNow);
      expect(retryDelay.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(retryDelay.inMilliseconds, lessThanOrEqualTo(2400));
      expect(captured[3], 'network');
      expect(captured[4], 'timeout');
      verifyNever(
        () => mockQueueService.markTerminal(
          any(),
          retryCount: any(named: 'retryCount'),
          terminalReason: any(named: 'terminalReason'),
          terminalAt: any(named: 'terminalAt'),
          lastAttemptAt: any(named: 'lastAttemptAt'),
          lastErrorClass: any(named: 'lastErrorClass'),
          lastErrorCode: any(named: 'lastErrorCode'),
        ),
      );
    });

    test('moves operation to terminal after maxAttempts is reached', () async {
      final fixedNow = DateTime(2026, 1, 10, 12);
      final operation = buildOperation(
        id: 'attempt-5',
        createdAt: fixedNow.subtract(const Duration(minutes: 1)),
        retryCount: 4,
      );

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(
          asOf: any(named: 'asOf'),
        ),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });

      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
          amount: operation.amount,
          paymentDate: operation.createdAt,
          markedBy: operation.markedBy,
          notes: operation.notes,
          idempotencyKey: operation.idempotencyKey,
        ),
      ).thenThrow(TimeoutException('socket timeout'));

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
        now: () => fixedNow,
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      verify(
        () => mockQueueService.markTerminal(
          operation.id,
          retryCount: 5,
          terminalReason: 'timeout',
          terminalAt: any(named: 'terminalAt'),
          lastAttemptAt: any(named: 'lastAttemptAt'),
          lastErrorClass: 'network',
          lastErrorCode: 'timeout',
        ),
      ).called(1);
      verifyNever(
        () => mockQueueService.scheduleRetry(
          any(),
          retryCount: any(named: 'retryCount'),
          nextAttemptAt: any(named: 'nextAttemptAt'),
          lastAttemptAt: any(named: 'lastAttemptAt'),
          lastErrorClass: any(named: 'lastErrorClass'),
          lastErrorCode: any(named: 'lastErrorCode'),
        ),
      );
    });

    test('keeps singleFlight lock and avoids duplicate processors', () async {
      final fixedNow = DateTime(2026, 1, 10, 12);
      final operation = buildOperation(
        id: 'single-flight',
        createdAt: fixedNow.subtract(const Duration(minutes: 1)),
      );
      final remoteCompleter = Completer<PaymentHistoryModel>();

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(
          asOf: any(named: 'asOf'),
        ),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });

      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
          amount: operation.amount,
          paymentDate: operation.createdAt,
          markedBy: operation.markedBy,
          notes: operation.notes,
          idempotencyKey: operation.idempotencyKey,
        ),
      ).thenAnswer((_) => remoteCompleter.future);

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
        now: () => fixedNow,
      );
      await orchestrator.start();

      final firstTrigger = orchestrator.triggerSync(reason: 'test');
      final secondTrigger = orchestrator.triggerSync(reason: 'test');

      await Future<void>.delayed(Duration.zero);
      expect(orchestrator.singleFlightInProgress, isTrue);

      remoteCompleter.complete(buildHistory('single-flight-history'));
      await Future.wait([firstTrigger, secondTrigger]);

      verify(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
          amount: operation.amount,
          paymentDate: operation.createdAt,
          markedBy: operation.markedBy,
          notes: operation.notes,
          idempotencyKey: operation.idempotencyKey,
        ),
      ).called(1);
    });
  });
}
