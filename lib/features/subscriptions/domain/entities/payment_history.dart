import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_history.freezed.dart';

/// Payment action type for tracking payment status changes
enum PaymentAction {
  /// Payment marked as paid
  paid,

  /// Payment marked as unpaid (undo action)
  unpaid;

  /// Get display name for the action
  String get displayName {
    switch (this) {
      case PaymentAction.paid:
        return 'Paid';
      case PaymentAction.unpaid:
        return 'Unpaid';
    }
  }

  /// Check if this is a paid action
  bool get isPaid => this == PaymentAction.paid;
}

/// Payment history entity representing a payment status change
///
/// This entity tracks the history of payment actions for subscription members.
/// It provides an audit trail for when payments are marked as paid or unpaid.
@freezed
class PaymentHistory with _$PaymentHistory {
  const factory PaymentHistory({
    /// Unique identifier for this payment history record
    required String id,

    /// ID of the subscription this payment belongs to
    required String subscriptionId,

    /// ID of the subscription member who made the payment
    required String memberId,

    /// Amount that was paid
    required double amount,

    /// Date when the payment was made
    required DateTime paymentDate,

    /// ID of the user who marked this payment (usually the subscription owner)
    required String markedBy,

    /// The action performed (paid or unpaid)
    required PaymentAction action,

    /// Optional notes about the payment
    String? notes,

    /// When this history record was created
    required DateTime createdAt,
  }) = _PaymentHistory;

  const PaymentHistory._();

  /// Check if this is a payment record (as opposed to unpayment)
  bool get isPayment => action.isPaid;

  /// Get a human-readable description of this payment action
  String get description {
    final actionText = action.displayName;
    return 'Payment of \$${amount.toStringAsFixed(2)} marked as $actionText';
  }
}
