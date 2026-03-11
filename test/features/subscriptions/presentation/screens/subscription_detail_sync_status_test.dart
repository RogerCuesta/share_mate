import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('SubscriptionDetailSyncStatusCard', () {
    testWidgets('shows Synced label and contextual message', (tester) async {
      final lastSync = DateTime.utc(2026, 3, 8, 15, 30);
      final status = SyncStatus(
        kind: SyncStatusKind.synced,
        pendingCount: 0,
        terminalCount: 0,
        lastSuccessfulSyncAt: lastSync,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionDetailSyncStatusCard(syncStatus: status),
          ),
        ),
      );

      final expectedLastSync =
          'Last successful sync: ${DateFormat('MMM dd, HH:mm').format(lastSync.toLocal())}';
      expect(find.text(syncedStatusLabel), findsOneWidget);
      expect(
        find.text('Changes for this subscription are synchronized.'),
        findsOneWidget,
      );
      expect(find.text(expectedLastSync), findsOneWidget);
    });

    testWidgets('shows Pending label and background sync message',
        (tester) async {
      const status = SyncStatus(
        kind: SyncStatusKind.pending,
        pendingCount: 3,
        terminalCount: 0,
        lastSuccessfulSyncAt: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SubscriptionDetailSyncStatusCard(syncStatus: status),
          ),
        ),
      );

      expect(find.text(pendingStatusLabel), findsOneWidget);
      expect(
        find.text('Pending changes are syncing in the background.'),
        findsOneWidget,
      );
      expect(find.text('Last successful sync: Not available'), findsOneWidget);
    });

    testWidgets('shows Requires action label and recovery hint',
        (tester) async {
      const status = SyncStatus(
        kind: SyncStatusKind.requiresAction,
        pendingCount: 1,
        terminalCount: 2,
        lastSuccessfulSyncAt: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SubscriptionDetailSyncStatusCard(syncStatus: status),
          ),
        ),
      );

      expect(find.text(requiresActionStatusLabel), findsOneWidget);
      expect(
        find.text(
          'Requires action: recover terminal sync failures in Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows backend cycle reset reconciliation copy in detail flow',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: _DetailReconciliationHarness(),
          ),
        ),
      );

      container.read(paymentReconciliationProvider.notifier).emit(
            reason: PaymentReconciliationReason.backendCycleReset,
            emittedAt: DateTime(2026, 4, 10, 8),
          );
      await tester.pump();

      expect(
        find.text('New billing cycle started. Pending payments were refreshed.'),
        findsOneWidget,
      );
    });
  });
}

class _DetailReconciliationHarness extends ConsumerWidget {
  const _DetailReconciliationHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PaymentReconciliationSignal?>(
      paymentReconciliationProvider,
      (previous, next) {
        if (next == null || previous?.sequence == next.sequence) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(paymentReconciliationMessage(next.reason)),
            ),
          );
      },
    );

    return const Scaffold(
      body: SizedBox.expand(),
    );
  }
}
