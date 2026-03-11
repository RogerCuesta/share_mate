import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentReconciliationReason {
  cycleConflictNoop,
  backendCycleReset,
  canonicalSyncRefresh,
  terminalRecovery,
}

@immutable
class PaymentReconciliationSignal {
  const PaymentReconciliationSignal({
    required this.sequence,
    required this.reason,
    required this.emittedAt,
  });

  final int sequence;
  final PaymentReconciliationReason reason;
  final DateTime emittedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PaymentReconciliationSignal &&
        other.sequence == sequence &&
        other.reason == reason &&
        other.emittedAt == emittedAt;
  }

  @override
  int get hashCode => Object.hash(sequence, reason, emittedAt);
}

String paymentReconciliationMessage(PaymentReconciliationReason reason) {
  return switch (reason) {
    PaymentReconciliationReason.cycleConflictNoop =>
      'Cycle changed. We refreshed totals to match synced data.',
    PaymentReconciliationReason.backendCycleReset =>
      'New billing cycle started. Pending payments were refreshed.',
    PaymentReconciliationReason.canonicalSyncRefresh =>
      'Synced updates refreshed payment totals.',
    PaymentReconciliationReason.terminalRecovery =>
      'Sync recovered. Showing the latest payment totals.',
  };
}

class PaymentReconciliationController
    extends Notifier<PaymentReconciliationSignal?> {
  int _sequence = 0;

  @override
  PaymentReconciliationSignal? build() => null;

  void emit({
    required PaymentReconciliationReason reason,
    DateTime? emittedAt,
  }) {
    _sequence += 1;
    state = PaymentReconciliationSignal(
      sequence: _sequence,
      reason: reason,
      emittedAt: emittedAt ?? DateTime.now(),
    );
  }
}

final paymentReconciliationProvider = NotifierProvider<
    PaymentReconciliationController, PaymentReconciliationSignal?>(
  PaymentReconciliationController.new,
);
