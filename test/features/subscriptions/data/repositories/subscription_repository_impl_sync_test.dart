import 'dart:io';

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/hive_type_ids.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionRemoteDataSource extends Mock
    implements SubscriptionRemoteDataSource {}

class MockSubscriptionLocalDataSource extends Mock
    implements SubscriptionLocalDataSource {}

class FakeSubscriptionMemberModel extends Fake
    implements SubscriptionMemberModel {}

void main() {
  group('SubscriptionRepositoryImpl sync enqueue metadata', () {
    late Directory hiveDir;
    late List<int> encryptionKey;
    late PaymentSyncQueueService queueService;
    late MockSubscriptionRemoteDataSource mockRemoteDataSource;
    late MockSubscriptionLocalDataSource mockLocalDataSource;
    late SubscriptionRepositoryImpl repository;

    const subscriptionId = 'subscription-1';
    const memberId = 'member-1';
    const markedBy = 'owner-1';

    SubscriptionMemberModel buildMember({
      required String id,
      required DateTime dueDate,
      bool hasPaid = false,
    }) {
      return SubscriptionMemberModel(
        id: id,
        subscriptionId: subscriptionId,
        userId: id,
        userName: 'Member $id',
        userEmail: '$id@test.dev',
        amountToPay: 12.5,
        hasPaid: hasPaid,
        dueDate: dueDate,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    SubscriptionModel buildSubscription({required DateTime dueDate}) {
      return SubscriptionModel(
        id: subscriptionId,
        name: 'Netflix',
        color: '#FF0000',
        totalCost: 25,
        billingCycle: 'monthly',
        dueDate: dueDate,
        ownerId: markedBy,
        sharedWith: const [],
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );
    }

    setUpAll(() {
      registerFallbackValue(FakeSubscriptionMemberModel());
      registerFallbackValue(DateTime(2026, 1, 1));
    });

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'subscription_repository_sync_test',
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

      mockRemoteDataSource = MockSubscriptionRemoteDataSource();
      mockLocalDataSource = MockSubscriptionLocalDataSource();
      repository = SubscriptionRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
      );

      when(() => mockLocalDataSource.updateMember(any())).thenAnswer(
        (_) async {},
      );
    });

    tearDown(() async {
      HiveService.overrideEncryptionKeyProviderForTesting(null);
      HiveService.clearKeyFailureSafeModeForTesting();
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test(
        'queues paid fallback operation with cycle due date and idempotency key',
        () async {
      final memberDueDate = DateTime(2026, 3, 3);
      final paymentDate = DateTime(2026, 3, 2);

      when(() => mockLocalDataSource.getMemberById(memberId)).thenAnswer(
        (_) async => buildMember(id: memberId, dueDate: memberDueDate),
      );
      when(
        () => mockLocalDataSource.getSubscriptionById(subscriptionId),
      ).thenAnswer(
        (_) async => buildSubscription(dueDate: DateTime(2026, 3, 15)),
      );
      when(
        () => mockRemoteDataSource.markPaymentAsPaid(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
        ),
      ).thenThrow(SubscriptionRemoteException('offline'));

      final result = await repository.markPaymentAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberId,
        amount: 12.5,
        paymentDate: paymentDate,
        markedBy: markedBy,
      );

      expect(result.isRight(), isTrue);
      final queued = await queueService.getPendingOrdered(
        asOf: DateTime(2030, 1, 1),
      );
      expect(queued, hasLength(1));
      expect(queued.first.action, 'paid');
      expect(queued.first.cycleDueDate, memberDueDate);
      expect(
        queued.first.idempotencyKey,
        'sync:paid:$subscriptionId:$memberId:${memberDueDate.toUtc().toIso8601String()}',
      );
    });

    test('queues unpaid fallback operation with cycle metadata', () async {
      final memberDueDate = DateTime(2026, 4, 8);
      final paymentDate = DateTime(2026, 4, 9);

      when(() => mockLocalDataSource.getMemberById(memberId)).thenAnswer(
        (_) async => buildMember(id: memberId, dueDate: memberDueDate),
      );
      when(
        () => mockLocalDataSource.getSubscriptionById(subscriptionId),
      ).thenAnswer(
        (_) async => buildSubscription(dueDate: DateTime(2026, 4, 15)),
      );
      when(
        () => mockRemoteDataSource.unmarkPayment(
          subscriptionId: any(named: 'subscriptionId'),
          memberId: any(named: 'memberId'),
          amount: any(named: 'amount'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
        ),
      ).thenThrow(SubscriptionRemoteException('offline'));

      final result = await repository.unmarkPayment(
        subscriptionId: subscriptionId,
        memberId: memberId,
        amount: 12.5,
        paymentDate: paymentDate,
        markedBy: markedBy,
      );

      expect(result.isRight(), isTrue);
      final queued = await queueService.getPendingOrdered(
        asOf: DateTime(2030, 1, 1),
      );
      expect(queued, hasLength(1));
      expect(queued.first.action, 'unpaid');
      expect(queued.first.cycleDueDate, memberDueDate);
      expect(
        queued.first.idempotencyKey,
        startsWith('sync:unpaid:$subscriptionId:$memberId:'),
      );
    });

    test('queues per-member cycle anchors for bulk paid fallback', () async {
      final memberA = buildMember(
        id: 'member-a',
        dueDate: DateTime(2026, 5, 1),
        hasPaid: false,
      );
      final memberB = buildMember(
        id: 'member-b',
        dueDate: DateTime(2026, 5, 2),
        hasPaid: false,
      );

      when(
        () => mockLocalDataSource.getMembersBySubscriptionId(subscriptionId),
      ).thenAnswer((_) async => [memberA, memberB]);
      when(
        () => mockRemoteDataSource.markAllPaymentsAsPaid(
          subscriptionId: any(named: 'subscriptionId'),
          paymentDate: any(named: 'paymentDate'),
          markedBy: any(named: 'markedBy'),
          notes: any(named: 'notes'),
        ),
      ).thenThrow(SubscriptionRemoteException('offline'));

      final result = await repository.markAllPaymentsAsPaid(
        subscriptionId: subscriptionId,
        paymentDate: DateTime(2026, 5, 10),
        markedBy: markedBy,
      );

      expect(result.getOrElse(() => -1), 2);
      final queued = await queueService.getPendingOrdered(
        asOf: DateTime(2030, 1, 1),
      );
      expect(queued, hasLength(2));

      final byMemberId = {
        for (final operation in queued) operation.memberId: operation,
      };
      expect(byMemberId['member-a']!.cycleDueDate, memberA.dueDate);
      expect(byMemberId['member-b']!.cycleDueDate, memberB.dueDate);
      expect(
        byMemberId['member-a']!.idempotencyKey,
        'sync:paid:$subscriptionId:${memberA.id}:${memberA.dueDate.toUtc().toIso8601String()}',
      );
      expect(
        byMemberId['member-b']!.idempotencyKey,
        'sync:paid:$subscriptionId:${memberB.id}:${memberB.dueDate.toUtc().toIso8601String()}',
      );

      verify(
        () => mockRemoteDataSource.markAllPaymentsAsPaid(
          subscriptionId: subscriptionId,
          paymentDate: any(named: 'paymentDate'),
          markedBy: markedBy,
          notes: any(named: 'notes'),
        ),
      ).called(1);
    });

    test('uses bulk remote contract and keeps queue empty when remote succeeds',
        () async {
      final memberA = buildMember(
        id: 'member-a',
        dueDate: DateTime(2026, 6, 1),
        hasPaid: false,
      );
      final memberB = buildMember(
        id: 'member-b',
        dueDate: DateTime(2026, 6, 2),
        hasPaid: false,
      );
      final paymentDate = DateTime(2026, 6, 10);

      when(
        () => mockLocalDataSource.getMembersBySubscriptionId(subscriptionId),
      ).thenAnswer((_) async => [memberA, memberB]);
      when(
        () => mockRemoteDataSource.markAllPaymentsAsPaid(
          subscriptionId: subscriptionId,
          paymentDate: paymentDate,
          markedBy: markedBy,
          notes: null,
        ),
      ).thenAnswer((_) async => 2);

      final result = await repository.markAllPaymentsAsPaid(
        subscriptionId: subscriptionId,
        paymentDate: paymentDate,
        markedBy: markedBy,
      );

      expect(result.getOrElse(() => -1), 2);
      verify(
        () => mockRemoteDataSource.markAllPaymentsAsPaid(
          subscriptionId: subscriptionId,
          paymentDate: paymentDate,
          markedBy: markedBy,
          notes: null,
        ),
      ).called(1);
      verify(() => mockLocalDataSource.updateMember(any())).called(2);

      final queued = await queueService.getPendingOrdered(
        asOf: DateTime(2030, 1, 1),
      );
      expect(queued, isEmpty);
    });
  });
}
