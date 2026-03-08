import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionRemoteDataSource extends Mock
    implements SubscriptionRemoteDataSource {}

class MockSubscriptionLocalDataSource extends Mock
    implements SubscriptionLocalDataSource {}

class FakeSubscriptionMemberModel extends Fake
    implements SubscriptionMemberModel {}

void main() {
  group('SubscriptionRepository split persistence parity', () {
    late MockSubscriptionRemoteDataSource remoteDataSource;
    late MockSubscriptionLocalDataSource localDataSource;
    late SubscriptionRepositoryImpl repository;

    setUpAll(() {
      registerFallbackValue(FakeSubscriptionMemberModel());
    });

    setUp(() {
      remoteDataSource = MockSubscriptionRemoteDataSource();
      localDataSource = MockSubscriptionLocalDataSource();
      repository = SubscriptionRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      when(() => localDataSource.getSubscriptionById(any())).thenAnswer(
        (_) async => _subscriptionModel(
          totalCost: 10,
          sharedWith: const [],
        ),
      );
      when(() => localDataSource.cacheMember(any())).thenAnswer((_) async {});
      when(() => localDataSource.cacheMembers(any())).thenAnswer((_) async {});
      when(() => remoteDataSource.addMember(any())).thenAnswer(
        (invocation) async {
          final member =
              invocation.positionalArguments.first as SubscriptionMemberModel;
          return SubscriptionMemberModel(
            id: 'persisted-${member.userId}',
            subscriptionId: member.subscriptionId,
            userId: member.userId,
            userName: member.userName,
            userEmail: member.userEmail,
            userAvatar: member.userAvatar,
            amountToPay: member.amountToPay,
            hasPaid: member.hasPaid,
            dueDate: member.dueDate,
            createdAt: member.createdAt,
            lastPaymentDate: member.lastPaymentDate,
            updatedAt: member.updatedAt,
          );
        },
      );
    });

    test('uses explicit amount when provided by preview split', () async {
      when(() => remoteDataSource.getSubscriptionMembers(any())).thenAnswer(
        (_) async => const [],
      );

      final result = await repository.addMemberToSubscription(
        subscriptionId: 'sub-1',
        userId: 'member-1',
        userName: 'Alex',
        amountToPay: 4.25,
      );

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => remoteDataSource.addMember(captureAny()),
      ).captured.single as SubscriptionMemberModel;
      expect(captured.amountToPay, 4.25);
    });

    test('derives amount from shared split when amount is not provided',
        () async {
      when(() => remoteDataSource.getSubscriptionMembers(any())).thenAnswer(
        (_) async => [
          _memberModel(id: 'member-a', amount: 5),
          _memberModel(id: 'member-b', amount: 5),
        ],
      );

      final result = await repository.addMemberToSubscription(
        subscriptionId: 'sub-1',
        userId: 'member-c',
        userName: 'Casey',
      );

      expect(result.isRight(), isTrue);
      final captured = verify(
        () => remoteDataSource.addMember(captureAny()),
      ).captured.single as SubscriptionMemberModel;

      // 10.00 split among owner + 3 members => members 2.50 each.
      expect(captured.amountToPay, 2.5);
    });
  });
}

SubscriptionModel _subscriptionModel({
  required double totalCost,
  required List<String> sharedWith,
}) {
  return SubscriptionModel(
    id: 'sub-1',
    name: 'Netflix',
    color: '#FF0000',
    totalCost: totalCost,
    billingCycle: 'monthly',
    dueDate: DateTime(2026, 3, 31),
    ownerId: 'owner-1',
    sharedWith: sharedWith,
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );
}

SubscriptionMemberModel _memberModel({
  required String id,
  required double amount,
}) {
  return SubscriptionMemberModel(
    id: id,
    subscriptionId: 'sub-1',
    userId: id,
    userName: 'Member $id',
    amountToPay: amount,
    hasPaid: false,
    dueDate: DateTime(2026, 3, 31),
    createdAt: DateTime(2026, 1, 1),
  );
}
