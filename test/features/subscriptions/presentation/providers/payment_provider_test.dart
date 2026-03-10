import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart'
    as history;
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_all_payments_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_payment_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/unmark_payment.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscription_detail_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _SubscriptionRepositoryStub extends Mock
    implements SubscriptionRepository {}

class _AuthRepositoryStub extends Mock implements AuthRepository {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
      : super(
          checkAuthStatus: CheckAuthStatus(_AuthRepositoryStub()),
          getCurrentUser: GetCurrentUser(_AuthRepositoryStub()),
          logoutUser: LogoutUser(_AuthRepositoryStub()),
        ) {
    setAuthenticated(user);
  }
}

class _TestMarkPaymentAsPaid extends MarkPaymentAsPaid {
  _TestMarkPaymentAsPaid(this._handler) : super(_SubscriptionRepositoryStub());

  final Future<Either<SubscriptionFailure, history.PaymentHistory>> Function({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy,
    DateTime? paymentDate,
    String? notes,
  }) _handler;

  @override
  Future<Either<SubscriptionFailure, history.PaymentHistory>> call({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy,
    DateTime? paymentDate,
    String? notes,
  }) {
    return _handler(
      subscriptionId: subscriptionId,
      memberId: memberId,
      amount: amount,
      markedBy: markedBy,
      paymentDate: paymentDate,
      notes: notes,
    );
  }
}

class _TestMarkAllPaymentsAsPaid extends MarkAllPaymentsAsPaid {
  _TestMarkAllPaymentsAsPaid(this._handler)
      : super(_SubscriptionRepositoryStub());

  final Future<Either<SubscriptionFailure, int>> Function({
    required String subscriptionId,
    required String markedBy,
    DateTime? paymentDate,
    String? notes,
  }) _handler;

  @override
  Future<Either<SubscriptionFailure, int>> call({
    required String subscriptionId,
    required String markedBy,
    DateTime? paymentDate,
    String? notes,
  }) {
    return _handler(
      subscriptionId: subscriptionId,
      markedBy: markedBy,
      paymentDate: paymentDate,
      notes: notes,
    );
  }
}

class _TestUnmarkPayment extends UnmarkPayment {
  _TestUnmarkPayment(this._handler) : super(_SubscriptionRepositoryStub());

  final Future<Either<SubscriptionFailure, history.PaymentHistory>> Function({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy,
    DateTime? paymentDate,
    String? notes,
  }) _handler;

  @override
  Future<Either<SubscriptionFailure, history.PaymentHistory>> call({
    required String subscriptionId,
    required String memberId,
    required double amount,
    required String markedBy,
    DateTime? paymentDate,
    String? notes,
  }) {
    return _handler(
      subscriptionId: subscriptionId,
      memberId: memberId,
      amount: amount,
      markedBy: markedBy,
      paymentDate: paymentDate,
      notes: notes,
    );
  }
}

void main() {
  const subscriptionId = 'sub-1';
  const memberIdA = 'member-a';
  const memberIdB = 'member-b';

  final testUser = User(
    id: 'owner-1',
    email: 'owner@example.com',
    fullName: 'Owner',
    createdAt: DateTime(2026, 1, 1),
  );

  ProviderContainer buildContainer({
    required MarkPaymentAsPaid markPaymentAsPaid,
    required MarkAllPaymentsAsPaid markAllPaymentsAsPaid,
    required UnmarkPayment unmarkPayment,
    List<Override> extraOverrides = const [],
  }) {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _TestAuthNotifier(testUser)),
        markPaymentAsPaidProvider.overrideWithValue(markPaymentAsPaid),
        markAllPaymentsAsPaidProvider.overrideWithValue(markAllPaymentsAsPaid),
        unmarkPaymentProvider.overrideWithValue(unmarkPayment),
        ...extraOverrides,
      ],
    );
  }

  group('PaymentAction', () {
    test('tracks loading per member and allows different member actions',
        () async {
      final completers = <String,
          Completer<Either<SubscriptionFailure, history.PaymentHistory>>>{
        memberIdA:
            Completer<Either<SubscriptionFailure, history.PaymentHistory>>(),
        memberIdB:
            Completer<Either<SubscriptionFailure, history.PaymentHistory>>(),
      };
      var callCount = 0;

      final container = buildContainer(
        markPaymentAsPaid: _TestMarkPaymentAsPaid(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) {
            callCount++;
            return completers[memberId]!.future;
          },
        ),
        markAllPaymentsAsPaid: _TestMarkAllPaymentsAsPaid(
          ({
            required subscriptionId,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              const Right(0),
        ),
        unmarkPayment: _TestUnmarkPayment(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              Right(_payment(memberId: memberId)),
        ),
      );
      addTearDown(container.dispose);

      final notifier = container.read(paymentActionProvider.notifier);

      final first = notifier.markAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberIdA,
        amount: 10,
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.loadingMember(memberIdA), isTrue);
      expect(notifier.loadingMember(memberIdB), isFalse);

      final second = notifier.markAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberIdB,
        amount: 12,
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.loadingMember(memberIdA), isTrue);
      expect(notifier.loadingMember(memberIdB), isTrue);
      expect(callCount, 2);

      completers[memberIdB]!.complete(Right(_payment(memberId: memberIdB)));
      expect(await second, isTrue);
      expect(notifier.loadingMember(memberIdA), isTrue);
      expect(notifier.loadingMember(memberIdB), isFalse);

      completers[memberIdA]!.complete(Right(_payment(memberId: memberIdA)));
      expect(await first, isTrue);
      expect(notifier.loadingMember(memberIdA), isFalse);
    });

    test('prevents duplicate requests for the same member while in flight',
        () async {
      final completer =
          Completer<Either<SubscriptionFailure, history.PaymentHistory>>();
      var callCount = 0;

      final container = buildContainer(
        markPaymentAsPaid: _TestMarkPaymentAsPaid(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) {
            callCount++;
            return completer.future;
          },
        ),
        markAllPaymentsAsPaid: _TestMarkAllPaymentsAsPaid(
          ({
            required subscriptionId,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              const Right(0),
        ),
        unmarkPayment: _TestUnmarkPayment(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              Right(_payment(memberId: memberId)),
        ),
      );
      addTearDown(container.dispose);

      final notifier = container.read(paymentActionProvider.notifier);

      final first = notifier.markAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberIdA,
        amount: 10,
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.loadingMember(memberIdA), isTrue);

      final duplicate = await notifier.markAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberIdA,
        amount: 10,
      );
      expect(duplicate, isFalse);
      expect(callCount, 1);

      completer.complete(Right(_payment(memberId: memberIdA)));
      expect(await first, isTrue);
      expect(notifier.loadingMember(memberIdA), isFalse);
    });

    test('tracks bulk loading and blocks other actions in the same scope',
        () async {
      final bulkCompleter = Completer<Either<SubscriptionFailure, int>>();
      var bulkCalls = 0;
      var singleCalls = 0;

      final container = buildContainer(
        markPaymentAsPaid: _TestMarkPaymentAsPaid(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) async {
            singleCalls++;
            return Right(_payment(memberId: memberId));
          },
        ),
        markAllPaymentsAsPaid: _TestMarkAllPaymentsAsPaid(
          ({
            required subscriptionId,
            required markedBy,
            paymentDate,
            notes,
          }) {
            bulkCalls++;
            return bulkCompleter.future;
          },
        ),
        unmarkPayment: _TestUnmarkPayment(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              Right(_payment(memberId: memberId)),
        ),
      );
      addTearDown(container.dispose);

      final notifier = container.read(paymentActionProvider.notifier);

      final firstBulk = notifier.markAllAsPaid(subscriptionId: subscriptionId);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.loadingBulk(subscriptionId), isTrue);

      final duplicateBulk =
          await notifier.markAllAsPaid(subscriptionId: subscriptionId);
      expect(duplicateBulk, 0);
      expect(bulkCalls, 1);

      final blockedSingle = await notifier.markAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberIdA,
        amount: 10,
      );
      expect(blockedSingle, isFalse);
      expect(singleCalls, 0);

      bulkCompleter.complete(const Right(3));
      expect(await firstBulk, 3);
      expect(notifier.loadingBulk(subscriptionId), isFalse);
    });

    test('invalidates detail and home debt dependencies after success',
        () async {
      var membersBuilds = 0;
      var monthlyBuilds = 0;
      var pendingBuilds = 0;
      var debtBuilds = 0;

      final container = buildContainer(
        markPaymentAsPaid: _TestMarkPaymentAsPaid(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              Right(_payment(memberId: memberId)),
        ),
        markAllPaymentsAsPaid: _TestMarkAllPaymentsAsPaid(
          ({
            required subscriptionId,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              const Right(0),
        ),
        unmarkPayment: _TestUnmarkPayment(
          ({
            required subscriptionId,
            required memberId,
            required amount,
            required markedBy,
            paymentDate,
            notes,
          }) async =>
              Right(_payment(memberId: memberId)),
        ),
        extraOverrides: [
          subscriptionMembersProvider(subscriptionId).overrideWith((ref) async {
            membersBuilds++;
            return [_member(id: memberIdA, subscriptionId: subscriptionId)];
          }),
          monthlyStatsProvider.overrideWith((ref) async {
            monthlyBuilds++;
            return const MonthlyStats(
              totalMonthlyCost: 60,
              pendingToCollect: 10,
              activeSubscriptionsCount: 2,
              overduePaymentsCount: 1,
            );
          }),
          pendingPaymentsProvider.overrideWith((ref) async {
            pendingBuilds++;
            return [_member(id: memberIdA, subscriptionId: subscriptionId)];
          }),
          debtHomeSnapshotProvider.overrideWith((ref) async {
            debtBuilds++;
            return const DebtHomeSnapshot.debtFree();
          }),
        ],
      );
      addTearDown(container.dispose);

      final membersSub = container.listen(
        subscriptionMembersProvider(subscriptionId),
        (_, __) {},
        fireImmediately: true,
      );
      final monthlySub = container.listen(
        monthlyStatsProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final pendingSub = container.listen(
        pendingPaymentsProvider,
        (_, __) {},
        fireImmediately: true,
      );
      final debtSub = container.listen(
        debtHomeSnapshotProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(membersSub.close);
      addTearDown(monthlySub.close);
      addTearDown(pendingSub.close);
      addTearDown(debtSub.close);

      await container.read(subscriptionMembersProvider(subscriptionId).future);
      await container.read(monthlyStatsProvider.future);
      await container.read(pendingPaymentsProvider.future);
      await container.read(debtHomeSnapshotProvider.future);

      expect(membersBuilds, greaterThanOrEqualTo(1));
      expect(monthlyBuilds, greaterThanOrEqualTo(1));
      expect(pendingBuilds, greaterThanOrEqualTo(1));
      expect(debtBuilds, greaterThanOrEqualTo(1));

      final notifier = container.read(paymentActionProvider.notifier);
      final success = await notifier.markAsPaid(
        subscriptionId: subscriptionId,
        memberId: memberIdA,
        amount: 10,
      );
      expect(success, isTrue);

      await container.read(subscriptionMembersProvider(subscriptionId).future);
      await container.read(monthlyStatsProvider.future);
      await container.read(pendingPaymentsProvider.future);
      await container.read(debtHomeSnapshotProvider.future);

      expect(membersBuilds, greaterThan(1));
      expect(monthlyBuilds, greaterThan(1));
      expect(pendingBuilds, greaterThan(1));
      expect(debtBuilds, greaterThan(1));
    });
  });
}

history.PaymentHistory _payment({required String memberId}) {
  return history.PaymentHistory(
    id: 'payment-$memberId',
    subscriptionId: 'sub-1',
    memberId: memberId,
    memberName: 'Member $memberId',
    subscriptionName: 'Netflix',
    amount: 10,
    paymentDate: DateTime(2026, 3, 10),
    markedBy: 'owner-1',
    action: history.PaymentAction.paid,
    createdAt: DateTime(2026, 3, 10),
  );
}

SubscriptionMember _member({
  required String id,
  required String subscriptionId,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: subscriptionId,
    userId: 'user-$id',
    userName: 'User $id',
    amountToPay: 10,
    dueDate: DateTime(2026, 3, 10),
    createdAt: DateTime(2026, 1, 1),
  );
}
