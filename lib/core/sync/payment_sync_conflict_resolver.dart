import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';

const String cycleConflictNoopReason = 'cycle_conflict_noop';

enum PaymentSyncPreflightDecision {
  applyMutation,
  alreadyAppliedNoop,
  terminalCycleConflictNoop,
}

class PaymentSyncPreflightResult {
  const PaymentSyncPreflightResult._({
    required this.decision,
    required this.backendCycleDueDate,
  });

  final PaymentSyncPreflightDecision decision;
  final DateTime backendCycleDueDate;

  bool get shouldApplyMutation =>
      decision == PaymentSyncPreflightDecision.applyMutation;

  bool get shouldMarkAsAlreadySynced =>
      decision == PaymentSyncPreflightDecision.alreadyAppliedNoop;

  bool get shouldMarkTerminalConflict =>
      decision == PaymentSyncPreflightDecision.terminalCycleConflictNoop;

  String? get terminalReason =>
      shouldMarkTerminalConflict ? cycleConflictNoopReason : null;

  factory PaymentSyncPreflightResult.applyMutation({
    required DateTime backendCycleDueDate,
  }) {
    return PaymentSyncPreflightResult._(
      decision: PaymentSyncPreflightDecision.applyMutation,
      backendCycleDueDate: backendCycleDueDate,
    );
  }

  factory PaymentSyncPreflightResult.alreadyApplied({
    required DateTime backendCycleDueDate,
  }) {
    return PaymentSyncPreflightResult._(
      decision: PaymentSyncPreflightDecision.alreadyAppliedNoop,
      backendCycleDueDate: backendCycleDueDate,
    );
  }

  factory PaymentSyncPreflightResult.cycleConflict({
    required DateTime backendCycleDueDate,
  }) {
    return PaymentSyncPreflightResult._(
      decision: PaymentSyncPreflightDecision.terminalCycleConflictNoop,
      backendCycleDueDate: backendCycleDueDate,
    );
  }
}

class PaymentSyncConflictResolver {
  const PaymentSyncConflictResolver({
    required SubscriptionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SubscriptionRemoteDataSource _remoteDataSource;

  Future<PaymentSyncPreflightResult> preflight(
    PaymentSyncOperation operation,
  ) async {
    final backendContext =
        await _remoteDataSource.getPaymentSyncMemberCycleContext(
      subscriptionId: operation.subscriptionId,
      memberId: operation.memberId,
    );

    if (!_sameCycleAnchor(
        operation.cycleDueDate, backendContext.cycleDueDate)) {
      return PaymentSyncPreflightResult.cycleConflict(
        backendCycleDueDate: backendContext.cycleDueDate,
      );
    }

    final wantsPaidState = operation.action == 'paid';
    if (backendContext.hasPaid == wantsPaidState) {
      return PaymentSyncPreflightResult.alreadyApplied(
        backendCycleDueDate: backendContext.cycleDueDate,
      );
    }

    return PaymentSyncPreflightResult.applyMutation(
      backendCycleDueDate: backendContext.cycleDueDate,
    );
  }

  bool _sameCycleAnchor(DateTime first, DateTime second) {
    final firstUtc = first.toUtc();
    final secondUtc = second.toUtc();
    return firstUtc.year == secondUtc.year &&
        firstUtc.month == secondUtc.month &&
        firstUtc.day == secondUtc.day;
  }
}
