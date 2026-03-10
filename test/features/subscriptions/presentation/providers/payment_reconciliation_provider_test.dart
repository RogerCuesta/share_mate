import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart';
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
  group('paymentReconciliationProvider', () {
    test('stores sequence, reason, and timestamp on emit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(paymentReconciliationProvider.notifier);
      final firstAt = DateTime(2026, 3, 10, 20, 30);
      notifier.emit(
        reason: PaymentReconciliationReason.canonicalSyncRefresh,
        emittedAt: firstAt,
      );

      final firstSignal = container.read(paymentReconciliationProvider);
      expect(firstSignal, isNotNull);
      expect(firstSignal!.sequence, 1);
      expect(
        firstSignal.reason,
        PaymentReconciliationReason.canonicalSyncRefresh,
      );
      expect(firstSignal.emittedAt, firstAt);

      final secondAt = DateTime(2026, 3, 10, 20, 31);
      notifier.emit(
        reason: PaymentReconciliationReason.terminalRecovery,
        emittedAt: secondAt,
      );
      final secondSignal = container.read(paymentReconciliationProvider);
      expect(secondSignal!.sequence, 2);
      expect(secondSignal.reason, PaymentReconciliationReason.terminalRecovery);
      expect(secondSignal.emittedAt, secondAt);
    });

    test('returns concise non-blocking reconciliation copy per reason', () {
      expect(
        paymentReconciliationMessage(
          PaymentReconciliationReason.cycleConflictNoop,
        ),
        isNotEmpty,
      );
      expect(
        paymentReconciliationMessage(
          PaymentReconciliationReason.canonicalSyncRefresh,
        ),
        contains('refreshed'),
      );
      expect(
        paymentReconciliationMessage(
          PaymentReconciliationReason.terminalRecovery,
        ),
        contains('recovered'),
      );
    });
  });

  group('syncStatusProvider reconciliation wiring', () {
    test('emits cycle conflict signal when status enters requiresAction', () {
      final queueSource = FakeSyncQueueStatusSource(pendingCount: 1);
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

      final notifier = container.read(syncStatusProvider.notifier);
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.pending);
      expect(container.read(paymentReconciliationProvider), isNull);

      queueSource.terminalCount = 1;
      notifier.refresh();

      final signal = container.read(paymentReconciliationProvider);
      expect(signal, isNotNull);
      expect(signal!.reason, PaymentReconciliationReason.cycleConflictNoop);
      expect(container.read(syncStatusProvider).kind,
          SyncStatusKind.requiresAction);
    });

    test('emits terminal recovery signal once terminal rows are cleared', () {
      final queueSource = FakeSyncQueueStatusSource(
        pendingCount: 2,
        terminalCount: 1,
      );
      final orchestratorSource = FakeSyncOrchestratorStatusSource(
        isSyncInProgress: false,
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
      expect(
        container.read(syncStatusProvider).kind,
        SyncStatusKind.requiresAction,
      );

      queueSource.terminalCount = 0;
      notifier.refresh();

      final signal = container.read(paymentReconciliationProvider);
      expect(signal, isNotNull);
      expect(signal!.reason, PaymentReconciliationReason.terminalRecovery);
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.pending);
    });

    test('emits canonical sync refresh when pending converges to synced', () {
      final queueSource = FakeSyncQueueStatusSource(pendingCount: 1);
      final orchestratorSource = FakeSyncOrchestratorStatusSource(
        isSyncInProgress: false,
        lastSuccessfulSyncAt: DateTime(2026, 3, 10, 20, 20),
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
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.pending);

      queueSource.pendingCount = 0;
      orchestratorSource.lastSuccessfulSyncAt = DateTime(2026, 3, 10, 20, 21);
      notifier.refresh();

      final signal = container.read(paymentReconciliationProvider);
      expect(signal, isNotNull);
      expect(signal!.reason, PaymentReconciliationReason.canonicalSyncRefresh);
      expect(container.read(syncStatusProvider).kind, SyncStatusKind.synced);
    });
  });
}
