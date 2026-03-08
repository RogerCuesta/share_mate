import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/subscription_repository_mock.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateGroupSubscriptionForm e2e orchestration', () {
    test(
        'create/select/edit/delete contact flow keeps persistence payload correct',
        () async {
      final repository = _RecordingSubscriptionRepository();
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );
      notifier.updateServiceName('Co-working Office');
      notifier.updateTotalPrice('18.00');
      notifier.updateRenewalDate(DateTime.now().add(const Duration(days: 60)));

      notifier.addOrReplaceMemberFromContact(
        _contact(id: 'local-1', name: 'Alex', email: null),
      );
      notifier.addOrReplaceMemberFromContact(
        _contact(id: 'local-2', name: 'Blair', email: 'blair@old.dev'),
      );
      notifier.syncMemberFromUpdatedContact(
        _contact(id: 'local-2', name: 'Blair Updated', email: 'blair@new.dev'),
      );
      notifier.removeMemberByContactId('local-1');
      notifier.addOrReplaceMemberFromContact(
        _contact(id: 'local-3', name: 'Casey', email: 'casey@test.dev'),
      );

      final beforeSubmit = container.read(createGroupSubscriptionFormProvider);
      expect(beforeSubmit.members, hasLength(2));
      expect(beforeSubmit.members.first.id, 'local-2');
      expect(beforeSubmit.members.first.name, 'Blair Updated');
      expect(beforeSubmit.members.first.email, 'blair@new.dev');
      expect(beforeSubmit.memberFloorSplitAmount, closeTo(6.0, 0.001));
      expect(beforeSubmit.breakdown, hasLength(3));

      await notifier.submit();

      expect(repository.createdSubscriptions, hasLength(1));
      expect(repository.addedMembers, hasLength(2));
      expect(
        repository.addedMembers.map((call) => call.userId).toSet(),
        equals({'local-2', 'local-3'}),
      );
      final updatedBlair = repository.addedMembers.firstWhere(
        (call) => call.userId == 'local-2',
      );
      expect(updatedBlair.userName, 'Blair Updated');
      expect(updatedBlair.userEmail, 'blair@new.dev');
      expect(updatedBlair.amountToPay, closeTo(6.0, 0.001));
    });
  });
}

ProviderContainer _buildContainer(_RecordingSubscriptionRepository repository) {
  final user = User(
    id: 'owner-1',
    email: 'owner@test.dev',
    fullName: 'Owner',
    createdAt: DateTime.now(),
  );
  final authRepository = _FakeAuthRepository(user);

  final container = ProviderContainer(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(repository),
      checkAuthStatusProvider
          .overrideWithValue(CheckAuthStatus(authRepository)),
      getCurrentUserProvider.overrideWithValue(GetCurrentUser(authRepository)),
      logoutUserProvider.overrideWithValue(LogoutUser(authRepository)),
    ],
  );
  container.read(authProvider.notifier).setAuthenticated(user);
  return container;
}

Contact _contact({
  required String id,
  required String name,
  required String? email,
}) {
  return Contact(
    id: id,
    userId: 'owner-1',
    name: name,
    email: email,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

class _RecordingSubscriptionRepository extends SubscriptionRepositoryMock {
  final List<Subscription> createdSubscriptions = [];
  final List<_AddMemberCall> addedMembers = [];

  @override
  Future<Either<SubscriptionFailure, Subscription>> createSubscription(
    Subscription subscription,
  ) async {
    createdSubscriptions.add(subscription);
    return Right(subscription);
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
    addedMembers.add(
      _AddMemberCall(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        amountToPay: amountToPay,
      ),
    );
    return Right(
      SubscriptionMember(
        id: 'generated-$userId',
        subscriptionId: subscriptionId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        amountToPay: amountToPay ?? 0,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _AddMemberCall {
  const _AddMemberCall({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amountToPay,
  });

  final String userId;
  final String userName;
  final String? userEmail;
  final double? amountToPay;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  final User user;

  @override
  Future<Either<AuthFailure, bool>> checkAuthStatus() async =>
      const Right(true);

  @override
  Future<Either<AuthFailure, AuthSession>> getCurrentSession() async {
    return Right(
      AuthSession(
        userId: user.id,
        token: 'token',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, User>> getCurrentUser() async => Right(user);

  @override
  bool isValidEmail(String email) => true;

  @override
  bool isValidPassword(String password) => true;

  @override
  Future<Either<AuthFailure, AuthSession>> loginUser({
    required String email,
    required String password,
  }) async {
    return Right(
      AuthSession(
        userId: user.id,
        token: 'token',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> logoutUser() async => const Right(unit);

  @override
  Future<Either<AuthFailure, User>> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return Right(
      user.copyWith(
        email: email,
        fullName: fullName,
      ),
    );
  }
}
