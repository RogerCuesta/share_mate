import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
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
      expect(find.text('Synced'), findsOneWidget);
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

      expect(find.text('Pending'), findsOneWidget);
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

      expect(find.text('Requires action'), findsOneWidget);
      expect(
        find.text(
          'Requires action: recover terminal sync failures in Settings.',
        ),
        findsOneWidget,
      );
    });
  });
}
