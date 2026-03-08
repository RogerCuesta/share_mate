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

class FakeSubscriptionModel extends Fake implements SubscriptionModel {}

class FakeSubscriptionMemberModel extends Fake
    implements SubscriptionMemberModel {}

void main() {
  group('SubscriptionRepository member email contract', () {
    late MockSubscriptionRemoteDataSource remoteDataSource;
    late MockSubscriptionLocalDataSource localDataSource;
    late SubscriptionRepositoryImpl repository;

    setUpAll(() {
      registerFallbackValue(FakeSubscriptionModel());
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
        (_) async => null,
      );
      when(() => localDataSource.cacheSubscription(any())).thenAnswer(
        (_) async {},
      );
      when(() => localDataSource.cacheMember(any())).thenAnswer(
        (_) async {},
      );
      when(() => remoteDataSource.getSubscriptionById(any())).thenAnswer(
        (_) async => _buildSubscriptionModel(),
      );
      when(() => remoteDataSource.addMember(any())).thenAnswer(
        (invocation) async {
          final input =
              invocation.positionalArguments.first as SubscriptionMemberModel;
          return SubscriptionMemberModel(
            id: 'member-row-1',
            subscriptionId: input.subscriptionId,
            userId: input.userId,
            userName: input.userName,
            userEmail: input.userEmail,
            userAvatar: input.userAvatar,
            amountToPay: input.amountToPay,
            hasPaid: false,
            dueDate: input.dueDate,
            createdAt: DateTime.utc(2026, 3, 1),
          );
        },
      );
    });

    test('persists null user_email when input email is blank', () async {
      final result = await repository.addMemberToSubscription(
        subscriptionId: 'sub-1',
        userId: 'contact-local-1',
        userName: 'Local Contact',
        userEmail: '   ',
      );

      expect(result.isRight(), isTrue);

      final captured = verify(
        () => remoteDataSource.addMember(captureAny()),
      ).captured.single as SubscriptionMemberModel;
      expect(captured.userEmail, isNull);
    });

    test('keeps legacy non-null email normalized to lowercase', () async {
      final result = await repository.addMemberToSubscription(
        subscriptionId: 'sub-1',
        userId: 'contact-legacy-1',
        userName: 'Legacy Contact',
        userEmail: 'LEGACY@EXAMPLE.COM',
      );

      expect(result.isRight(), isTrue);

      final captured = verify(
        () => remoteDataSource.addMember(captureAny()),
      ).captured.single as SubscriptionMemberModel;
      expect(captured.userEmail, 'legacy@example.com');
    });
  });
}

SubscriptionModel _buildSubscriptionModel() {
  return SubscriptionModel(
    id: 'sub-1',
    name: 'Netflix',
    color: '#6C63FF',
    totalCost: 20,
    billingCycle: 'monthly',
    dueDate: DateTime.utc(2026, 3, 31),
    ownerId: 'owner-1',
    sharedWith: const ['member-a'],
    status: 'active',
    createdAt: DateTime.utc(2026, 3, 1),
  );
}
