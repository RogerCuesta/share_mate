import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/billing_automation/data/platform/local_notification_adapter.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('HomeSyncStatusBadge', () {
    testWidgets('renders Synced state with formatted timestamp',
        (tester) async {
      final lastSync = DateTime.utc(2026, 3, 8, 14, 45);
      final status = SyncStatus(
        kind: SyncStatusKind.synced,
        pendingCount: 0,
        terminalCount: 0,
        lastSuccessfulSyncAt: lastSync,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HomeSyncStatusBadge(status: status)),
        ),
      );

      final expected =
          'Last sync: ${DateFormat('MMM d, HH:mm').format(lastSync.toLocal())}';
      expect(find.text(syncedStatusLabel), findsOneWidget);
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('renders Pending state with timestamp fallback',
        (tester) async {
      const status = SyncStatus(
        kind: SyncStatusKind.pending,
        pendingCount: 2,
        terminalCount: 0,
        lastSuccessfulSyncAt: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeSyncStatusBadge(status: status)),
        ),
      );

      expect(find.text(pendingStatusLabel), findsOneWidget);
      expect(find.text('Last sync: Not available'), findsOneWidget);
    });

    testWidgets('renders Requires action state', (tester) async {
      const status = SyncStatus(
        kind: SyncStatusKind.requiresAction,
        pendingCount: 1,
        terminalCount: 1,
        lastSuccessfulSyncAt: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeSyncStatusBadge(status: status)),
        ),
      );

      expect(find.text(requiresActionStatusLabel), findsOneWidget);
    });

    testWidgets('renders billing automation warning details', (tester) async {
      const status = SyncStatus(
        kind: SyncStatusKind.synced,
        pendingCount: 0,
        terminalCount: 0,
        lastSuccessfulSyncAt: null,
      );
      const automationHealth = BillingAutomationHealth(
        remindersEnabled: true,
        permissionStatus: NotificationPermissionStatus.denied,
        scheduledCount: 0,
        timezoneId: 'Europe/Madrid',
        lastRunAt: null,
        lastRunReason: 'app_resume',
        issue: BillingAutomationIssue.permissionDenied,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeSyncStatusBadge(
              status: status,
              automationHealth: automationHealth,
            ),
          ),
        ),
      );

      expect(find.text('Reminder permission needed'), findsNothing);
      expect(
        find.text('Enable notifications to schedule payment reminders.'),
        findsOneWidget,
      );
    });
  });
}
