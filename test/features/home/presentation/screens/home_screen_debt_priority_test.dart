import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/home/presentation/models/debt_home_snapshot.dart';
import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
import 'package:flutter_project_agents/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthRepositoryStub extends Mock implements AuthRepository {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier()
      : super(
          checkAuthStatus: CheckAuthStatus(_AuthRepositoryStub()),
          getCurrentUser: GetCurrentUser(_AuthRepositoryStub()),
          logoutUser: LogoutUser(_AuthRepositoryStub()),
        ) {
    setAuthenticated(
      User(
        id: 'owner-1',
        email: 'owner@example.com',
        fullName: 'Owner',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }
}

void main() {
  group('HomeScreen debt priority', () {
    testWidgets(
        'renders debt blocks before action required and shows next collection details',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final snapshot = DebtHomeSnapshot(
        totalPendingDebt: 38,
        nextCollection: NextCollectionCandidate(
          subscriptionId: 'sub-netflix',
          subscriptionName: 'Netflix',
          dueDate: now.subtract(const Duration(days: 2)),
          pendingAmount: 38,
          isOverdue: true,
        ),
      );

      await tester.pumpWidget(
        _buildHome(
          snapshot: snapshot,
          pendingPayments: [
            _pendingMember(
              id: 'member-1',
              subscriptionId: 'sub-netflix',
              amount: 38,
              dueDate: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final debtCard = find.byKey(const Key('debt-home-kpi-card'));
      final actionSection = find.byKey(const Key('action-required-section'));

      if (actionSection.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          actionSection,
          320,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      expect(debtCard, findsOneWidget);
      expect(actionSection, findsOneWidget);
      expect(
        tester.getTopLeft(debtCard).dy,
        lessThan(tester.getTopLeft(actionSection).dy),
      );

      expect(find.text('Proximo cobro'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('next-collection-card')),
          matching: find.text('\$38.00'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Vencido'), findsOneWidget);
    });

    testWidgets('renders Todo al dia state with no overdue copy',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildHome(
          snapshot: const DebtHomeSnapshot.debtFree(),
          pendingPayments: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todo al dia'), findsNWidgets(2));
      expect(find.text(r'$0.00'), findsNWidgets(2));
      expect(find.textContaining('Vencido'), findsNothing);
      expect(find.byKey(const Key('action-required-section')), findsNothing);
    });
  });
}

Widget _buildHome({
  required DebtHomeSnapshot snapshot,
  required List<SubscriptionMember> pendingPayments,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _TestAuthNotifier()),
      homeSyncStatusProvider.overrideWithValue(
        const SyncStatus(
          kind: SyncStatusKind.synced,
          pendingCount: 0,
          terminalCount: 0,
          lastSuccessfulSyncAt: null,
        ),
      ),
      debtHomeSnapshotProvider.overrideWith((ref) async => snapshot),
      monthlyStatsProvider.overrideWith(
        (ref) async => const MonthlyStats(
          totalMonthlyCost: 99,
          pendingToCollect: 38,
          activeSubscriptionsCount: 2,
          overduePaymentsCount: 1,
        ),
      ),
      pendingPaymentsProvider.overrideWith((ref) async => pendingPayments),
      activeSubscriptionsProvider.overrideWith((ref) async => <Subscription>[]),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

SubscriptionMember _pendingMember({
  required String id,
  required String subscriptionId,
  required double amount,
  required DateTime dueDate,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: subscriptionId,
    userId: 'user-$id',
    userName: 'Member $id',
    amountToPay: amount,
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
  );
}
