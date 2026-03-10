import 'dart:async';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_orchestrator.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String syncedStatusLabel = 'Synced';
const String pendingStatusLabel = 'Pending';
const String requiresActionStatusLabel = 'Requires action';

String syncStatusLabel(SyncStatus status) {
  return switch (status.kind) {
    SyncStatusKind.synced => syncedStatusLabel,
    SyncStatusKind.pending => pendingStatusLabel,
    SyncStatusKind.requiresAction => requiresActionStatusLabel,
  };
}

abstract class SyncQueueStatusSource {
  int get pendingCount;
  int get terminalCount;
}

abstract class SyncOrchestratorStatusSource {
  bool get isSyncInProgress;
  DateTime? get lastSuccessfulSyncAt;
}

abstract class SyncQueueRecoverySource {
  Future<int> retryTerminal({DateTime? retryAt});
  Future<int> clearTerminalOnly();
}

// ignore: one_member_abstracts
abstract class SyncOrchestratorCommandSource {
  Future<void> triggerSync({
    String reason,
    bool force,
  });
}

class _PaymentSyncQueueStatusSource implements SyncQueueStatusSource {
  _PaymentSyncQueueStatusSource(this._queueService);

  final PaymentSyncQueueService _queueService;

  @override
  int get pendingCount => _queueService.pendingCount;

  @override
  int get terminalCount => _queueService.terminalCount;
}

class _PaymentSyncOrchestratorStatusSource
    implements SyncOrchestratorStatusSource {
  _PaymentSyncOrchestratorStatusSource(this._orchestrator);

  final PaymentSyncOrchestrator _orchestrator;

  @override
  bool get isSyncInProgress => _orchestrator.singleFlightInProgress;

  @override
  DateTime? get lastSuccessfulSyncAt => _orchestrator.lastSuccessfulSyncAt;
}

class _PaymentSyncQueueRecoverySource implements SyncQueueRecoverySource {
  _PaymentSyncQueueRecoverySource(this._queueService);

  final PaymentSyncQueueService _queueService;

  @override
  Future<int> retryTerminal({DateTime? retryAt}) {
    return _queueService.retryTerminal(retryAt: retryAt);
  }

  @override
  Future<int> clearTerminalOnly() {
    return _queueService.clearTerminalOnly();
  }
}

class _PaymentSyncOrchestratorCommandSource
    implements SyncOrchestratorCommandSource {
  _PaymentSyncOrchestratorCommandSource(this._orchestrator);

  final PaymentSyncOrchestrator _orchestrator;

  @override
  Future<void> triggerSync({
    String reason = 'manual',
    bool force = false,
  }) {
    return _orchestrator.triggerSync(
      reason: reason,
      force: force,
    );
  }
}

final syncQueueStatusSourceProvider = Provider<SyncQueueStatusSource>((ref) {
  return _PaymentSyncQueueStatusSource(
    ref.watch(paymentSyncQueueServiceProvider),
  );
});

final syncOrchestratorStatusSourceProvider =
    Provider<SyncOrchestratorStatusSource>((ref) {
  return _PaymentSyncOrchestratorStatusSource(
    ref.watch(paymentSyncOrchestratorProvider),
  );
});

final syncStatusRefreshIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 2);
});

final syncQueueRecoverySourceProvider =
    Provider<SyncQueueRecoverySource>((ref) {
  return _PaymentSyncQueueRecoverySource(
    ref.watch(paymentSyncQueueServiceProvider),
  );
});

final syncOrchestratorCommandSourceProvider =
    Provider<SyncOrchestratorCommandSource>((ref) {
  return _PaymentSyncOrchestratorCommandSource(
    ref.watch(paymentSyncOrchestratorProvider),
  );
});

class SyncStatusController extends AutoDisposeNotifier<SyncStatus> {
  Timer? _pollTimer;

  @override
  SyncStatus build() {
    _pollTimer?.cancel();
    final refreshInterval = ref.watch(syncStatusRefreshIntervalProvider);
    _pollTimer = Timer.periodic(refreshInterval, (_) {
      refresh();
    });
    ref.onDispose(() => _pollTimer?.cancel());
    return _readStatus();
  }

  void refresh() {
    final previous = state;
    final next = _readStatus();
    _emitReconciliationIfNeeded(previous: previous, next: next);
    state = next;
  }

  Future<int> retryAll() async {
    final queueRecovery = ref.read(syncQueueRecoverySourceProvider);
    final orchestratorCommand = ref.read(syncOrchestratorCommandSourceProvider);
    final retried = await queueRecovery.retryTerminal(
      retryAt: DateTime.now(),
    );
    await orchestratorCommand.triggerSync(
      reason: 'settings_retry_all',
      force: true,
    );
    refresh();
    return retried;
  }

  Future<int> clearTerminalOnly() async {
    final queueRecovery = ref.read(syncQueueRecoverySourceProvider);
    final cleared = await queueRecovery.clearTerminalOnly();
    refresh();
    return cleared;
  }

  SyncStatus _readStatus() {
    final queueStatus = ref.read(syncQueueStatusSourceProvider);
    final orchestratorStatus = ref.read(syncOrchestratorStatusSourceProvider);

    return SyncStatus.fromSignals(
      pendingCount: queueStatus.pendingCount,
      terminalCount: queueStatus.terminalCount,
      inFlight: orchestratorStatus.isSyncInProgress,
      lastSuccessfulSyncAt: orchestratorStatus.lastSuccessfulSyncAt,
    );
  }

  void _emitReconciliationIfNeeded({
    required SyncStatus previous,
    required SyncStatus next,
  }) {
    final controller = ref.read(paymentReconciliationProvider.notifier);

    final enteredRequiresAction =
        previous.kind != SyncStatusKind.requiresAction &&
            next.kind == SyncStatusKind.requiresAction;
    if (enteredRequiresAction) {
      controller.emit(reason: PaymentReconciliationReason.cycleConflictNoop);
      return;
    }

    final recoveredFromTerminal =
        previous.kind == SyncStatusKind.requiresAction &&
            next.kind != SyncStatusKind.requiresAction;
    if (recoveredFromTerminal) {
      controller.emit(reason: PaymentReconciliationReason.terminalRecovery);
      return;
    }

    final movedToSynced = previous.kind == SyncStatusKind.pending &&
        next.kind == SyncStatusKind.synced;
    if (movedToSynced &&
        _syncTimestampAdvanced(
          previous.lastSuccessfulSyncAt,
          next.lastSuccessfulSyncAt,
        )) {
      controller.emit(reason: PaymentReconciliationReason.canonicalSyncRefresh);
    }
  }

  bool _syncTimestampAdvanced(
    DateTime? previousTimestamp,
    DateTime? nextTimestamp,
  ) {
    if (nextTimestamp == null) {
      return false;
    }
    if (previousTimestamp == null) {
      return true;
    }
    return nextTimestamp.isAfter(previousTimestamp);
  }
}

final syncStatusProvider =
    AutoDisposeNotifierProvider<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);

final homeSyncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncStatusProvider);
});

final subscriptionDetailSyncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncStatusProvider);
});

final settingsSyncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncStatusProvider);
});
