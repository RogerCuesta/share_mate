import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart'
    as history;
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_all_payments_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_payment_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/unmark_payment.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/payment_action_buttons.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/payment_status_toggle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepositoryStub extends Mock implements AuthRepository {}

class _SubscriptionRepositoryStub extends Mock
    implements SubscriptionRepository {}

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
  final owner = User(
    id: 'owner-1',
    email: 'owner@example.com',
    fullName: 'Owner',
    createdAt: DateTime(2026, 1, 1),
  );

  List<Override> _overrides({
    required MarkPaymentAsPaid markPaymentAsPaid,
    required MarkAllPaymentsAsPaid markAllPaymentsAsPaid,
    required UnmarkPayment unmarkPayment,
  }) {
    return [
      authProvider.overrideWith((ref) => _TestAuthNotifier(owner)),
      markPaymentAsPaidProvider.overrideWithValue(markPaymentAsPaid),
      markAllPaymentsAsPaidProvider.overrideWithValue(markAllPaymentsAsPaid),
      unmarkPaymentProvider.overrideWithValue(unmarkPayment),
    ];
  }

  Widget _host({required List<Override> overrides, required Widget child}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('PaymentStatusToggle', () {
    testWidgets('prevents duplicate tap requests for the same member',
        (tester) async {
      final completer =
          Completer<Either<SubscriptionFailure, history.PaymentHistory>>();
      var markCalls = 0;

      await tester.pumpWidget(
        _host(
          overrides: _overrides(
            markPaymentAsPaid: _TestMarkPaymentAsPaid(
              ({
                required subscriptionId,
                required memberId,
                required amount,
                required markedBy,
                paymentDate,
                notes,
              }) {
                markCalls++;
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
          ),
          child: PaymentStatusToggle(
            member: _member(id: memberIdA, userName: 'Alice'),
            subscriptionId: subscriptionId,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(markCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Alice'));
      await tester.pump();
      expect(markCalls, 1);

      completer.complete(Right(_payment(memberId: memberIdA)));
      await tester.pumpAndSettle();
    });

    testWidgets('keeps undo success flow and triggers unmark on undo',
        (tester) async {
      var unmarkCalls = 0;

      await tester.pumpWidget(
        _host(
          overrides: _overrides(
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
              }) async {
                unmarkCalls++;
                return Right(_payment(memberId: memberId));
              },
            ),
          ),
          child: PaymentStatusToggle(
            member: _member(id: memberIdA, userName: 'Alice'),
            subscriptionId: subscriptionId,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.textContaining('marked as paid'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(unmarkCalls, 1);
      expect(find.text('Action undone'), findsOneWidget);
    });

    testWidgets('shows error snackbar when action fails', (tester) async {
      await tester.pumpWidget(
        _host(
          overrides: _overrides(
            markPaymentAsPaid: _TestMarkPaymentAsPaid(
              ({
                required subscriptionId,
                required memberId,
                required amount,
                required markedBy,
                paymentDate,
                notes,
              }) async =>
                  const Left(SubscriptionFailure.networkError()),
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
          ),
          child: PaymentStatusToggle(
            member: _member(id: memberIdA, userName: 'Alice'),
            subscriptionId: subscriptionId,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(
        find.text('Network error. Please check your connection.'),
        findsOneWidget,
      );
    });
  });

  group('PaymentActionButtons', () {
    testWidgets(
      'disables bulk action while a member action is in flight but keeps other rows actionable',
      (tester) async {
        final memberACompleter =
            Completer<Either<SubscriptionFailure, history.PaymentHistory>>();
        var markCallsA = 0;
        var markCallsB = 0;
        var bulkCalls = 0;

        await tester.pumpWidget(
          _host(
            overrides: _overrides(
              markPaymentAsPaid: _TestMarkPaymentAsPaid(
                ({
                  required subscriptionId,
                  required memberId,
                  required amount,
                  required markedBy,
                  paymentDate,
                  notes,
                }) {
                  if (memberId == memberIdA) {
                    markCallsA++;
                    return memberACompleter.future;
                  }
                  markCallsB++;
                  return Future.value(Right(_payment(memberId: memberId)));
                },
              ),
              markAllPaymentsAsPaid: _TestMarkAllPaymentsAsPaid(
                ({
                  required subscriptionId,
                  required markedBy,
                  paymentDate,
                  notes,
                }) async {
                  bulkCalls++;
                  return const Right(2);
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
            ),
            child: Column(
              children: [
                PaymentStatusToggle(
                  member: _member(id: memberIdA, userName: 'Alice'),
                  subscriptionId: subscriptionId,
                ),
                PaymentStatusToggle(
                  member: _member(id: memberIdB, userName: 'Bob'),
                  subscriptionId: subscriptionId,
                ),
                const SizedBox(height: 16),
                const PaymentActionButtons(
                  subscriptionId: subscriptionId,
                  hasPendingPayments: true,
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        expect(markCallsA, 1);

        final bulkButton =
            tester.widget<OutlinedButton>(find.byType(OutlinedButton));
        expect(bulkButton.onPressed, isNull);

        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(markCallsB, 1);
        expect(bulkCalls, 0);

        memberACompleter.complete(Right(_payment(memberId: memberIdA)));
        await tester.pumpAndSettle();
      },
    );
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
  required String userName,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: 'sub-1',
    userId: 'user-$id',
    userName: userName,
    amountToPay: 10,
    dueDate: DateTime(2026, 3, 10),
    createdAt: DateTime(2026, 1, 1),
  );
}
