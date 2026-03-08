import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSyncQueueStatusSource implements SyncQueueStatusSource {
  FakeSyncQueueStatusSource({
    this.pendingCount = 0,
    this.terminalCount = 0,
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

void main() {
  group('syncStatusProvider', () {
    test('returns synced state when queue has no pending or terminal rows', () {
      final queueSource = FakeSyncQueueStatusSource();
      final orchestratorSource = FakeSyncOrchestratorStatusSource();

      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueSource),
          syncOrchestratorStatusSourceProvider.overrideWithValue(
            orchestratorSource,
          ),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final status = container.read(syncStatusProvider);
      expect(status.kind, SyncStatusKind.synced);
      expect(status.synced, isTrue);
      expect(status.pendingCount, 0);
      expect(status.terminalCount, 0);
    });

    test('prioritizes requiresAction when terminal rows exist', () {
      final queueSource = FakeSyncQueueStatusSource(
        pendingCount: 3,
        terminalCount: 1,
      );
      final orchestratorSource = FakeSyncOrchestratorStatusSource(
        isSyncInProgress: true,
      );

      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueSource),
          syncOrchestratorStatusSourceProvider.overrideWithValue(
            orchestratorSource,
          ),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final status = container.read(syncStatusProvider);
      expect(status.kind, SyncStatusKind.requiresAction);
      expect(status.requiresAction, isTrue);
      expect(status.pendingCount, 3);
      expect(status.terminalCount, 1);
    });

    test('transitions synced to pending to requiresAction deterministically',
        () {
      final queueSource = FakeSyncQueueStatusSource();
      final orchestratorSource = FakeSyncOrchestratorStatusSource(
        lastSuccessfulSyncAt: DateTime(2026, 3, 8, 10),
      );

      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueSource),
          syncOrchestratorStatusSourceProvider.overrideWithValue(
            orchestratorSource,
          ),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(syncStatusProvider.notifier);

      expect(container.read(syncStatusProvider).kind, SyncStatusKind.synced);

      queueSource.pendingCount = 2;
      notifier.refresh();
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.pending);

      queueSource.terminalCount = 1;
      notifier.refresh();
      final status = container.read(syncStatusProvider);
      expect(status.kind, SyncStatusKind.requiresAction);
      expect(status.lastSuccessfulSyncAt, DateTime(2026, 3, 8, 10));

      queueSource.pendingCount = 0;
      queueSource.terminalCount = 0;
      orchestratorSource.isSyncInProgress = true;
      notifier.refresh();
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.pending);
    });

    test('status aliases expose same read-only projection', () {
      final queueSource = FakeSyncQueueStatusSource(pendingCount: 1);
      final orchestratorSource = FakeSyncOrchestratorStatusSource();
      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueSource),
          syncOrchestratorStatusSourceProvider.overrideWithValue(
            orchestratorSource,
          ),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final homeStatus = container.read(homeSyncStatusProvider);
      final detailStatus = container.read(subscriptionDetailSyncStatusProvider);
      final settingsStatus = container.read(settingsSyncStatusProvider);

      expect(homeStatus, detailStatus);
      expect(detailStatus, settingsStatus);
      expect(settingsStatus.kind, SyncStatusKind.pending);
    });

    test('returns to synced after pending and terminal states are cleared', () {
      final queueSource = FakeSyncQueueStatusSource(
        pendingCount: 2,
        terminalCount: 1,
      );
      final orchestratorSource = FakeSyncOrchestratorStatusSource(
        isSyncInProgress: false,
        lastSuccessfulSyncAt: DateTime(2026, 3, 8, 12),
      );
      final container = ProviderContainer(
        overrides: [
          syncQueueStatusSourceProvider.overrideWithValue(queueSource),
          syncOrchestratorStatusSourceProvider.overrideWithValue(
            orchestratorSource,
          ),
          syncStatusRefreshIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(syncStatusProvider.notifier);
      expect(container.read(syncStatusProvider).kind,
          SyncStatusKind.requiresAction);

      queueSource.terminalCount = 0;
      notifier.refresh();
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.pending);

      queueSource.pendingCount = 0;
      notifier.refresh();
      final status = container.read(syncStatusProvider);
      expect(status.kind, SyncStatusKind.synced);
      expect(status.lastSuccessfulSyncAt, DateTime(2026, 3, 8, 12));
    });
  });
}
