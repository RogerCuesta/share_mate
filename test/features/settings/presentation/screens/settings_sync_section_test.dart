import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSyncQueueStatusSource implements SyncQueueStatusSource {
  FakeSyncQueueStatusSource({
    required this.pendingCount,
    required this.terminalCount,
  });

  @override
  int pendingCount;

  @override
  int terminalCount;
}

class FakeSyncOrchestratorStatusSource implements SyncOrchestratorStatusSource {
  FakeSyncOrchestratorStatusSource({
    this.isSyncInProgress = false,
    this.lastSuccessfulSyncAt,
  });

  @override
  bool isSyncInProgress;

  @override
  DateTime? lastSuccessfulSyncAt;
}

class FakeSyncQueueRecoverySource implements SyncQueueRecoverySource {
  FakeSyncQueueRecoverySource({
    required FakeSyncQueueStatusSource queueStatus,
    this.retryResult = 0,
    this.clearResult = 0,
  }) : _queueStatus = queueStatus;

  final FakeSyncQueueStatusSource _queueStatus;
  final int retryResult;
  final int clearResult;
  int retryCalls = 0;
  int clearCalls = 0;

  @override
  Future<int> retryTerminal({DateTime? retryAt}) async {
    retryCalls += 1;
    _queueStatus.terminalCount = 0;
    return retryResult;
  }

  @override
  Future<int> clearTerminalOnly() async {
    clearCalls += 1;
    _queueStatus.terminalCount = 0;
    return clearResult;
  }
}

class FakeSyncOrchestratorCommandSource
    implements SyncOrchestratorCommandSource {
  int triggerCalls = 0;
  String? lastReason;
  bool? lastForce;

  @override
  Future<void> triggerSync({
    String reason = 'manual',
    bool force = false,
  }) async {
    triggerCalls += 1;
    lastReason = reason;
    lastForce = force;
  }
}

void main() {
  group('SyncStatusController manual recovery actions', () {
    test('retryAll retries terminal operations and triggers forced sync',
        () async {
      final queueStatus = FakeSyncQueueStatusSource(
        pendingCount: 2,
        terminalCount: 3,
      );
      final queueRecovery = FakeSyncQueueRecoverySource(
        queueStatus: queueStatus,
        retryResult: 3,
      );
      final orchestratorStatus = FakeSyncOrchestratorStatusSource();
      final orchestratorCommand = FakeSyncOrchestratorCommandSource();

      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueStatus),
          syncOrchestratorStatusSourceProvider
              .overrideWithValue(orchestratorStatus),
          syncQueueRecoverySourceProvider.overrideWithValue(queueRecovery),
          syncOrchestratorCommandSourceProvider
              .overrideWithValue(orchestratorCommand),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final retried =
          await container.read(syncStatusProvider.notifier).retryAll();

      expect(retried, 3);
      expect(queueRecovery.retryCalls, 1);
      expect(orchestratorCommand.triggerCalls, 1);
      expect(orchestratorCommand.lastReason, 'settings_retry_all');
      expect(orchestratorCommand.lastForce, isTrue);
      final status = container.read(syncStatusProvider);
      expect(status.kind, SyncStatusKind.pending);
      expect(status.pendingCount, 2);
      expect(status.terminalCount, 0);
    });

    test('clearTerminalOnly removes terminal rows without touching pending',
        () async {
      final queueStatus = FakeSyncQueueStatusSource(
        pendingCount: 4,
        terminalCount: 2,
      );
      final queueRecovery = FakeSyncQueueRecoverySource(
        queueStatus: queueStatus,
        clearResult: 2,
      );
      final orchestratorStatus = FakeSyncOrchestratorStatusSource();
      final orchestratorCommand = FakeSyncOrchestratorCommandSource();

      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueStatus),
          syncOrchestratorStatusSourceProvider
              .overrideWithValue(orchestratorStatus),
          syncQueueRecoverySourceProvider.overrideWithValue(queueRecovery),
          syncOrchestratorCommandSourceProvider
              .overrideWithValue(orchestratorCommand),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final cleared =
          await container.read(syncStatusProvider.notifier).clearTerminalOnly();

      expect(cleared, 2);
      expect(queueRecovery.clearCalls, 1);
      expect(queueRecovery.retryCalls, 0);
      expect(orchestratorCommand.triggerCalls, 0);
      final status = container.read(syncStatusProvider);
      expect(status.pendingCount, 4);
      expect(status.terminalCount, 0);
      expect(status.kind, SyncStatusKind.pending);
    });
  });

  group('SettingsSyncHealthSection', () {
    testWidgets('renders sync status and action controls', (tester) async {
      const status = SyncStatus(
        kind: SyncStatusKind.requiresAction,
        pendingCount: 1,
        terminalCount: 2,
        lastSuccessfulSyncAt: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSyncHealthSection(
              syncStatus: status,
              onRetryAll: () async => 2,
              onClearTerminalOnly: () async => 2,
            ),
          ),
        ),
      );

      expect(find.text('Requires action'), findsOneWidget);
      expect(find.text('Pending operations: 1'), findsOneWidget);
      expect(find.text('Requires action: 2'), findsOneWidget);
      expect(find.text('Retry all'), findsOneWidget);
      expect(find.text('Clear terminal only'), findsOneWidget);
    });
  });
}
