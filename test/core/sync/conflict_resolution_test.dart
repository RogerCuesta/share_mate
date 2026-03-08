import 'package:flutter_project_agents/core/sync/payment_sync_conflict_resolver.dart';
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
  group('Payment sync conflict resolution', () {
    late MockPaymentSyncQueueService mockQueueService;
    late MockSubscriptionRemoteDataSource mockRemoteDataSource;

    PaymentSyncOperation buildOperation({
      required String id,
      String action = 'paid',
      DateTime? cycleDueDate,
    }) {
      final createdAt = DateTime(2026, 1, 10, 12);
      return PaymentSyncOperation(
        id: id,
        memberId: 'member-$id',
        subscriptionId: 'subscription-$id',
        amount: 12.5,
        markedBy: 'owner-id',
        action: action,
        createdAt: createdAt,
        cycleDueDate: cycleDueDate ?? DateTime(2026, 1, 1),
        idempotencyKey: 'sync:$action:subscription-$id:member-$id:fixed-anchor',
      );
    }

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

    setUpAll(() {
      registerFallbackValue(FakePaymentSyncOperation());
      registerFallbackValue(DateTime(2026, 1, 1));
    });

    setUp(() {
      mockQueueService = MockPaymentSyncQueueService();
      mockRemoteDataSource = MockSubscriptionRemoteDataSource();

      when(() => mockQueueService.init()).thenAnswer((_) async {});
      when(
        () => mockQueueService.getPendingOrdered(asOf: any(named: 'asOf')),
      ).thenAnswer((_) async => []);
      when(
        () => mockQueueService.markProcessing(
          any(),
          attemptedAt: any(named: 'attemptedAt'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockQueueService.markSynced(any())).thenAnswer((_) async {});
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
    });

    test('stale-cycle operation is terminal no-op and skips mutation',
        () async {
      final operation = buildOperation(id: 'stale');

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(asOf: any(named: 'asOf')),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });
      when(
        () => mockRemoteDataSource.getPaymentSyncMemberCycleContext(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
        ),
      ).thenAnswer(
        (_) async => PaymentSyncMemberCycleContext(
          cycleDueDate: DateTime(2026, 2, 1),
          hasPaid: false,
        ),
      );

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
        now: () => DateTime(2026, 1, 10, 12),
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      verifyNever(
        () => mockQueueService.markProcessing(
          any(),
          attemptedAt: any(named: 'attemptedAt'),
        ),
      );
      verifyNever(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
      verifyNever(
        () => mockRemoteDataSource.unmarkPayment(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
      verify(
        () => mockQueueService.markTerminal(
          operation.id,
          retryCount: operation.retryCount,
          terminalReason: cycleConflictNoopReason,
          terminalAt: any(named: 'terminalAt'),
          lastAttemptAt: any(named: 'lastAttemptAt'),
          lastErrorClass: 'sync_conflict',
          lastErrorCode: cycleConflictNoopReason,
        ),
      ).called(1);
      verify(
        () => mockRemoteDataSource.recordPaymentSyncConflictAudit(
          operationId: operation.id,
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
          action: operation.action,
          terminalReason: cycleConflictNoopReason,
          queuedCycleDueDate: operation.cycleDueDate,
          backendCycleDueDate: DateTime(2026, 2, 1),
          retryCount: operation.retryCount,
          idempotencyKey: operation.idempotencyKey,
        ),
      ).called(1);
    });

    test('stale-cycle unpaid operation skips unmark RPC and is audited',
        () async {
      final operation = buildOperation(id: 'stale-unpaid', action: 'unpaid');

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(asOf: any(named: 'asOf')),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });
      when(
        () => mockRemoteDataSource.getPaymentSyncMemberCycleContext(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
        ),
      ).thenAnswer(
        (_) async => PaymentSyncMemberCycleContext(
          cycleDueDate: DateTime(2026, 2, 1),
          hasPaid: true,
        ),
      );

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      verifyNever(
        () => mockRemoteDataSource.unmarkPayment(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
      verify(
        () => mockRemoteDataSource.recordPaymentSyncConflictAudit(
          operationId: operation.id,
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
          action: operation.action,
          terminalReason: cycleConflictNoopReason,
          queuedCycleDueDate: operation.cycleDueDate,
          backendCycleDueDate: DateTime(2026, 2, 1),
          retryCount: operation.retryCount,
          idempotencyKey: operation.idempotencyKey,
        ),
      ).called(1);
    });

    test('same-cycle already-applied operation is treated as success',
        () async {
      final operation = buildOperation(id: 'already-applied');

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(asOf: any(named: 'asOf')),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });
      when(
        () => mockRemoteDataSource.getPaymentSyncMemberCycleContext(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
        ),
      ).thenAnswer(
        (_) async => PaymentSyncMemberCycleContext(
          cycleDueDate: operation.cycleDueDate,
          hasPaid: true,
        ),
      );

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      verify(() => mockQueueService.markSynced(operation.id)).called(1);
      verifyNever(
        () => mockQueueService.markProcessing(
          any(),
          attemptedAt: any(named: 'attemptedAt'),
        ),
      );
      verifyNever(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
    });

    test('same-cycle operation applies mutation with idempotency key',
        () async {
      final operation = buildOperation(id: 'apply');

      var readCount = 0;
      when(
        () => mockQueueService.getPendingOrdered(asOf: any(named: 'asOf')),
      ).thenAnswer((_) async {
        readCount += 1;
        if (readCount == 1) {
          return [operation];
        }
        return <PaymentSyncOperation>[];
      });
      when(
        () => mockRemoteDataSource.getPaymentSyncMemberCycleContext(
          subscriptionId: operation.subscriptionId,
          memberId: operation.memberId,
        ),
      ).thenAnswer(
        (_) async => PaymentSyncMemberCycleContext(
          cycleDueDate: operation.cycleDueDate,
          hasPaid: false,
        ),
      );

      final orchestrator = PaymentSyncOrchestrator(
        queueService: mockQueueService,
        remoteDataSource: mockRemoteDataSource,
      );
      await orchestrator.start();
      await orchestrator.triggerSync(reason: 'test');

      verifyInOrder([
        () => mockQueueService.markProcessing(
              operation.id,
              attemptedAt: any(named: 'attemptedAt'),
            ),
        () => mockRemoteDataSource.markPaymentAsPaid(
              subscriptionId: operation.subscriptionId,
              memberId: operation.memberId,
              amount: operation.amount,
              paymentDate: operation.createdAt,
              markedBy: operation.markedBy,
              notes: operation.notes,
              idempotencyKey: operation.idempotencyKey,
            ),
        () => mockQueueService.markSynced(operation.id),
      ]);
    });
  });
}
