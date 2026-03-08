import 'package:flutter/foundation.dart';

enum SyncStatusKind { synced, pending, requiresAction }

@immutable
class SyncStatus {
  const SyncStatus({
    required this.kind,
    required this.pendingCount,
    required this.terminalCount,
    required this.lastSuccessfulSyncAt,
    this.inFlight = false,
  });

  factory SyncStatus.fromSignals({
    required int pendingCount,
    required int terminalCount,
    required bool inFlight,
    required DateTime? lastSuccessfulSyncAt,
  }) {
    final normalizedPendingCount = pendingCount < 0 ? 0 : pendingCount;
    final normalizedTerminalCount = terminalCount < 0 ? 0 : terminalCount;

    final kind = normalizedTerminalCount > 0
        ? SyncStatusKind.requiresAction
        : (normalizedPendingCount > 0 || inFlight)
            ? SyncStatusKind.pending
            : SyncStatusKind.synced;

    return SyncStatus(
      kind: kind,
      pendingCount: normalizedPendingCount,
      terminalCount: normalizedTerminalCount,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      inFlight: inFlight,
    );
  }

  final SyncStatusKind kind;
  final int pendingCount;
  final int terminalCount;
  final DateTime? lastSuccessfulSyncAt;
  final bool inFlight;

  bool get synced => kind == SyncStatusKind.synced;
  bool get pending => kind == SyncStatusKind.pending;
  bool get requiresAction => kind == SyncStatusKind.requiresAction;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SyncStatus &&
        other.kind == kind &&
        other.pendingCount == pendingCount &&
        other.terminalCount == terminalCount &&
        other.lastSuccessfulSyncAt == lastSuccessfulSyncAt &&
        other.inFlight == inFlight;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        pendingCount,
        terminalCount,
        lastSuccessfulSyncAt,
        inFlight,
      );
}
