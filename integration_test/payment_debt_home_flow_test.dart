import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/subscription_repository_mock.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'detail payment actions update Home debt and next collection without refresh',
    (tester) async {
      final user = User(
        id: 'owner-1',
        email: 'owner@test.dev',
        fullName: 'Owner',
        createdAt: DateTime(2026, 1, 1),
      );
      final now = DateTime.now();
      final repository = _InMemorySubscriptionRepository(
        subscriptions: [
          Subscription(
            id: 'sub-netflix',
            name: 'Netflix',
            color: '#E50914',
            totalCost: 20,
            billingCycle: BillingCycle.monthly,
            dueDate: DateTime(now.year, now.month, now.day - 1),
            ownerId: user.id,
            createdAt: DateTime(2026, 1, 1),
          ),
          Subscription(
            id: 'sub-spotify',
            name: 'Spotify',
            color: '#1DB954',
            totalCost: 10,
            billingCycle: BillingCycle.monthly,
            dueDate: DateTime(now.year, now.month, now.day + 2),
            ownerId: user.id,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        members: [
          _member(
            id: 'member-a',
            subscriptionId: 'sub-netflix',
            userName: 'Alex',
            amountToPay: 20,
            dueDate: DateTime(now.year, now.month, now.day - 1),
          ),
          _member(
            id: 'member-c',
            subscriptionId: 'sub-spotify',
            userName: 'Casey',
            amountToPay: 10,
            dueDate: DateTime(now.year, now.month, now.day + 2),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/subscription/:id',
            builder: (_, state) => SubscriptionDetailScreen(
                subscriptionId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
            subscriptionRepositoryProvider.overrideWithValue(repository),
            homeSyncStatusProvider.overrideWithValue(_syncedStatus()),
            subscriptionDetailSyncStatusProvider
                .overrideWithValue(_syncedStatus()),
            syncStatusRefreshIntervalProvider
                .overrideWithValue(const Duration(minutes: 10)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      _expectHomeSummary(
        tester,
        debtAmount: r'$30.00',
        nextCollectionName: 'Netflix',
        nextCollectionAmount: r'$20.00',
      );

      await _openSubscriptionByRoute(
        tester: tester,
        router: router,
        subscriptionId: 'sub-netflix',
      );

      expect(find.text('Subscription Details'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('marked as paid'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Action undone'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      _expectHomeSummary(
        tester,
        debtAmount: r'$30.00',
        nextCollectionName: 'Netflix',
        nextCollectionAmount: r'$20.00',
      );

      await _openSubscriptionByRoute(
        tester: tester,
        router: router,
        subscriptionId: 'sub-netflix',
      );
      await _scrollToBulkAction(tester);
      await tester.tap(find.text('Mark All as Paid'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('All 1 payment marked as paid'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      _expectHomeSummary(
        tester,
        debtAmount: r'$10.00',
        nextCollectionName: 'Spotify',
        nextCollectionAmount: r'$10.00',
      );

      await _openSubscriptionByRoute(
        tester: tester,
        router: router,
        subscriptionId: 'sub-spotify',
      );
      await _scrollToBulkAction(tester);
      await tester.tap(find.text('Mark All as Paid'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('debt-home-kpi-card')),
          matching: find.text(r'$0.00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('next-collection-card')),
          matching: find.text('Todo al dia'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('next-collection-card')),
          matching: find.text('No hay cobros pendientes.'),
        ),
        findsOneWidget,
      );
    },
  );
}

void _expectHomeSummary(
  WidgetTester tester, {
  required String debtAmount,
  required String nextCollectionName,
  required String nextCollectionAmount,
}) {
  expect(
    find.descendant(
      of: find.byKey(const Key('debt-home-kpi-card')),
      matching: find.text(debtAmount),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key('next-collection-card')),
      matching: find.text(nextCollectionName),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key('next-collection-card')),
      matching: find.text(nextCollectionAmount),
    ),
    findsOneWidget,
  );
}

Future<void> _openSubscriptionByRoute({
  required WidgetTester tester,
  required GoRouter router,
  required String subscriptionId,
}) async {
  router.push('/subscription/$subscriptionId');
  await tester.pumpAndSettle();
}

Future<void> _scrollToBulkAction(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Mark All as Paid'),
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

SyncStatus _syncedStatus() {
  return const SyncStatus(
    kind: SyncStatusKind.synced,
    pendingCount: 0,
    terminalCount: 0,
    lastSuccessfulSyncAt: null,
  );
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
      : super(
          checkAuthStatus: CheckAuthStatus(_FakeAuthRepository(user)),
          getCurrentUser: GetCurrentUser(_FakeAuthRepository(user)),
          logoutUser: LogoutUser(_FakeAuthRepository(user)),
        ) {
    setAuthenticated(user);
  }
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
    return Right(user.copyWith(email: email, fullName: fullName));
  }
}

class _InMemorySubscriptionRepository extends SubscriptionRepositoryMock {
  _InMemorySubscriptionRepository({
    required List<Subscription> subscriptions,
    required List<SubscriptionMember> members,
  }) : _subscriptions = List<Subscription>.from(subscriptions) {
    _membersBySubscription = <String, List<SubscriptionMember>>{};
    for (final member in members) {
      _membersBySubscription
          .putIfAbsent(member.subscriptionId, () => <SubscriptionMember>[])
          .add(member);
    }
  }

  final List<Subscription> _subscriptions;
  late final Map<String, List<SubscriptionMember>> _membersBySubscription;
  final List<PaymentHistory> _history = <PaymentHistory>[];

  @override
  Future<Either<SubscriptionFailure, MonthlyStats>> getMonthlyStats(
    String userId,
  ) async {
    final members = _allMembers();
    final pending = members.where((member) => !member.hasPaid).toList();
    final paid = members.where((member) => member.hasPaid).toList();

    final totalMonthlyCost = _subscriptions
        .where(
            (subscription) => subscription.status == SubscriptionStatus.active)
        .fold<double>(0, (sum, subscription) => sum + subscription.monthlyCost);

    return Right(
      MonthlyStats(
        totalMonthlyCost: totalMonthlyCost,
        pendingToCollect:
            pending.fold<double>(0, (sum, member) => sum + member.amountToPay),
        activeSubscriptionsCount: _subscriptions
            .where((subscription) =>
                subscription.status == SubscriptionStatus.active)
            .length,
        overduePaymentsCount: pending
            .where((member) => DateTime.now().isAfter(
                  DateTime(
                    member.dueDate.year,
                    member.dueDate.month,
                    member.dueDate.day,
                  ),
                ))
            .length,
        collectedAmount:
            paid.fold<double>(0, (sum, member) => sum + member.amountToPay),
        paidMembersCount: paid.length,
        unpaidMembersCount: pending.length,
      ),
    );
  }

  @override
  Future<Either<SubscriptionFailure, List<Subscription>>>
      getActiveSubscriptions(
    String userId,
  ) async {
    return Right(
      _subscriptions
          .where((subscription) =>
              subscription.status == SubscriptionStatus.active)
          .toList(growable: false),
    );
  }

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>>
      getPendingPayments(
    String userId,
  ) async {
    final pending = _allMembers().where((member) => !member.hasPaid).toList();
    return Right(pending);
  }

  @override
  Future<Either<SubscriptionFailure, Subscription>> getSubscriptionById(
    String subscriptionId,
  ) async {
    try {
      final subscription =
          _subscriptions.firstWhere((item) => item.id == subscriptionId);
      return Right(subscription);
    } catch (_) {
      return const Left(SubscriptionFailure.notFound());
    }
  }

  @override
  Future<Either<SubscriptionFailure, List<SubscriptionMember>>>
      getSubscriptionMembers(String subscriptionId) async {
    return Right(
      List<SubscriptionMember>.from(
          _membersBySubscription[subscriptionId] ?? const []),
    );
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
    final member = _updateMember(
      subscriptionId: subscriptionId,
      memberId: memberId,
      hasPaid: true,
      paymentDate: paymentDate,
    );
    if (member == null) {
      return const Left(SubscriptionFailure.notFound());
    }

    final payment = _paymentHistory(
      subscriptionId: subscriptionId,
      member: member,
      amount: amount,
      markedBy: markedBy,
      paymentDate: paymentDate,
      action: PaymentAction.paid,
      notes: notes,
    );
    _history.add(payment);
    return Right(payment);
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
    final member = _updateMember(
      subscriptionId: subscriptionId,
      memberId: memberId,
      hasPaid: false,
      paymentDate: null,
    );
    if (member == null) {
      return const Left(SubscriptionFailure.notFound());
    }

    final payment = _paymentHistory(
      subscriptionId: subscriptionId,
      member: member,
      amount: amount,
      markedBy: markedBy,
      paymentDate: paymentDate,
      action: PaymentAction.unpaid,
      notes: notes,
    );
    _history.add(payment);
    return Right(payment);
  }

  @override
  Future<Either<SubscriptionFailure, int>> markAllPaymentsAsPaid({
    required String subscriptionId,
    required DateTime paymentDate,
    required String markedBy,
    String? notes,
  }) async {
    final members = _membersBySubscription[subscriptionId];
    if (members == null || members.isEmpty) {
      return const Right(0);
    }

    var changed = 0;
    for (var i = 0; i < members.length; i++) {
      final current = members[i];
      if (current.hasPaid) {
        continue;
      }
      final updated =
          current.copyWith(hasPaid: true, lastPaymentDate: paymentDate);
      members[i] = updated;
      changed += 1;
      _history.add(
        _paymentHistory(
          subscriptionId: subscriptionId,
          member: updated,
          amount: updated.amountToPay,
          markedBy: markedBy,
          paymentDate: paymentDate,
          action: PaymentAction.paid,
          notes: notes,
        ),
      );
    }

    return Right(changed);
  }

  SubscriptionMember? _updateMember({
    required String subscriptionId,
    required String memberId,
    required bool hasPaid,
    required DateTime? paymentDate,
  }) {
    final members = _membersBySubscription[subscriptionId];
    if (members == null) {
      return null;
    }

    final index = members.indexWhere((member) => member.id == memberId);
    if (index == -1) {
      return null;
    }

    final updated = members[index].copyWith(
      hasPaid: hasPaid,
      lastPaymentDate: paymentDate,
    );
    members[index] = updated;
    return updated;
  }

  PaymentHistory _paymentHistory({
    required String subscriptionId,
    required SubscriptionMember member,
    required double amount,
    required String markedBy,
    required DateTime paymentDate,
    required PaymentAction action,
    String? notes,
  }) {
    final subscription =
        _subscriptions.firstWhere((item) => item.id == subscriptionId);

    return PaymentHistory(
      id: 'history-${_history.length + 1}',
      subscriptionId: subscriptionId,
      memberId: member.id,
      memberName: member.userName,
      subscriptionName: subscription.name,
      amount: amount,
      paymentDate: paymentDate,
      markedBy: markedBy,
      action: action,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  List<SubscriptionMember> _allMembers() {
    return _membersBySubscription.values
        .expand((members) => members)
        .toList(growable: false);
  }
}

SubscriptionMember _member({
  required String id,
  required String subscriptionId,
  required String userName,
  required double amountToPay,
  required DateTime dueDate,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: subscriptionId,
    userId: 'user-$id',
    userName: userName,
    amountToPay: amountToPay,
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
  );
}
