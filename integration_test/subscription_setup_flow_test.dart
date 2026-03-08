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
import 'package:flutter_project_agents/features/subscriptions/domain/entities/service_template.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subscription setup flow integration', () {
    test('create flow persists template edits, split values, and billing day',
        () async {
      final repository = _RecordingSubscriptionRepository();
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );

      notifier
          .applyServiceTemplate(_template(slug: 'netflix', name: 'Netflix'));
      notifier.updateServiceName('Netflix Family+');
      notifier.updateTotalPrice('19.99');
      notifier.addOrReplaceMemberFromContact(
        _contact(id: 'contact-1', name: 'Alex', email: null),
      );
      notifier.addOrReplaceMemberFromContact(
        _contact(id: 'contact-2', name: 'Blair', email: 'blair@test.dev'),
      );

      final targetDate = DateTime.now().add(const Duration(days: 45));
      notifier.updateRenewalDate(
        DateTime(targetDate.year, targetDate.month, targetDate.day),
      );

      final beforeSubmit = container.read(createGroupSubscriptionFormProvider);
      expect(beforeSubmit.memberFloorSplitAmount, closeTo(6.66, 0.001));
      expect(beforeSubmit.breakdown, hasLength(3));

      await notifier.submit();

      final created = repository.createdSubscriptions.single;
      expect(created.name, 'Netflix Family+');
      expect(created.color, '#E50914');
      expect(created.billingAnchorDay, targetDate.day);
      expect(created.dueDate.day, targetDate.day);

      expect(repository.addedMembers, hasLength(2));
      expect(
        repository.addedMembers.map((call) => call.userId).toSet(),
        equals({'contact-1', 'contact-2'}),
      );
      for (final memberCall in repository.addedMembers) {
        expect(memberCall.amountToPay, closeTo(6.66, 0.001));
      }
    });

    test(
        'edit flow recalculates persistence and keeps overflow month normalized',
        () async {
      final repository = _RecordingSubscriptionRepository();
      final container = _buildContainer(repository);
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );

      final now = DateTime.now();
      final overflowDate = _nextShortMonthDate(now);
      final existing = Subscription(
        id: 'sub-1',
        name: 'Streaming Plus',
        color: '#6C63FF',
        totalCost: 12,
        billingCycle: BillingCycle.monthly,
        dueDate: overflowDate,
        ownerId: 'owner-1',
        billingAnchorDay: 31,
        createdAt: now.subtract(const Duration(days: 10)),
      );
      final existingMembers = <SubscriptionMember>[
        _member(
          id: 'row-a',
          subscriptionId: existing.id,
          userId: 'contact-a',
          userName: 'Ana',
          amountToPay: 4,
          dueDate: overflowDate,
        ),
        _member(
          id: 'row-b',
          subscriptionId: existing.id,
          userId: 'contact-b',
          userName: 'Ben',
          amountToPay: 4,
          dueDate: overflowDate,
        ),
      ];

      notifier.initializeWithSubscription(existing, existingMembers);

      final initialized = container.read(createGroupSubscriptionFormProvider);
      expect(initialized.hasBillingDayOverflowInSelectedMonth, isTrue);
      expect(initialized.normalizedRenewalDate.day, overflowDate.day);
      expect(initialized.billingAnchorDay, 31);

      notifier.updateTotalPrice('15.00');
      notifier.removeMemberByContactId('contact-b');
      notifier.addOrReplaceMemberFromContact(
        _contact(id: 'contact-c', name: 'Cara', email: 'cara@test.dev'),
      );

      await notifier.submit(existing.id);

      final updated = repository.updatedSubscriptions.single;
      expect(updated.totalCost, 15);
      expect(updated.billingAnchorDay, 31);
      expect(updated.dueDate.day, overflowDate.day);

      expect(repository.removedMemberIds, contains('row-b'));
      expect(
        repository.addedMembers.any((call) => call.userId == 'contact-c'),
        isTrue,
      );
      expect(
        repository.updatedAmounts.any(
          (call) =>
              call.memberId == 'row-a' &&
              call.resetPayment &&
              (call.newAmountToPay - 5).abs() < 0.001,
        ),
        isTrue,
      );
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

DateTime _nextShortMonthDate(DateTime from) {
  var monthStart = DateTime(from.year, from.month + 1);
  for (var i = 0; i < 18; i++) {
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    if (lastDay < 31) {
      return DateTime(monthStart.year, monthStart.month, lastDay);
    }
    monthStart = DateTime(monthStart.year, monthStart.month + 1);
  }

  return DateTime(from.year, from.month + 1, 30);
}

ServiceTemplate _template({
  required String slug,
  required String name,
}) {
  return ServiceTemplate(
    id: '$slug-id',
    slug: slug,
    name: name,
    logoUrl: 'https://example.com/$slug.svg',
    brandColor: '#E50914',
    aliases: const [],
    searchTerms: const [],
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
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

SubscriptionMember _member({
  required String id,
  required String subscriptionId,
  required String userId,
  required String userName,
  required double amountToPay,
  required DateTime dueDate,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: subscriptionId,
    userId: userId,
    userName: userName,
    userEmail: '$userId@test.dev',
    amountToPay: amountToPay,
    dueDate: dueDate,
    createdAt: DateTime.now(),
  );
}

class _RecordingSubscriptionRepository extends SubscriptionRepositoryMock {
  final List<Subscription> createdSubscriptions = [];
  final List<Subscription> updatedSubscriptions = [];
  final List<_AddMemberCall> addedMembers = [];
  final List<String> removedMemberIds = [];
  final List<_UpdateAmountCall> updatedAmounts = [];

  @override
  Future<Either<SubscriptionFailure, Subscription>> createSubscription(
    Subscription subscription,
  ) async {
    createdSubscriptions.add(subscription);
    return Right(subscription);
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> updateSubscription(
    Subscription subscription,
  ) async {
    updatedSubscriptions.add(subscription);
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
        subscriptionId: subscriptionId,
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

  @override
  Future<Either<SubscriptionFailure, Unit>> removeMemberFromSubscription(
    String memberId,
  ) async {
    removedMemberIds.add(memberId);
    return const Right(unit);
  }

  @override
  Future<Either<SubscriptionFailure, SubscriptionMember>> updateMemberAmount({
    required String memberId,
    required double newAmountToPay,
    bool resetPayment = false,
  }) async {
    updatedAmounts.add(
      _UpdateAmountCall(
        memberId: memberId,
        newAmountToPay: newAmountToPay,
        resetPayment: resetPayment,
      ),
    );
    return Right(
      SubscriptionMember(
        id: memberId,
        subscriptionId: 'sub-1',
        userId: 'contact-a',
        userName: 'Ana',
        amountToPay: newAmountToPay,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        hasPaid: !resetPayment,
      ),
    );
  }
}

class _AddMemberCall {
  const _AddMemberCall({
    required this.subscriptionId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amountToPay,
  });

  final String subscriptionId;
  final String userId;
  final String userName;
  final String? userEmail;
  final double? amountToPay;
}

class _UpdateAmountCall {
  const _UpdateAmountCall({
    required this.memberId,
    required this.newAmountToPay,
    required this.resetPayment,
  });

  final String memberId;
  final double newAmountToPay;
  final bool resetPayment;
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
