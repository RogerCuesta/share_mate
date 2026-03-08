import 'dart:async';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_orchestrator.dart';
import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class SyncQueueStatusSource {
  int get pendingCount;
  int get terminalCount;
}

abstract class SyncOrchestratorStatusSource {
  bool get isSyncInProgress;
  DateTime? get lastSuccessfulSyncAt;
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
    state = _readStatus();
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
