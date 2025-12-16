import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_member.freezed.dart';

/// Subscription member entity representing a user sharing a subscription
@freezed
class SubscriptionMember with _$SubscriptionMember {
  const factory SubscriptionMember({
    /// Unique identifier for this membership
    required String id,

    /// ID of the subscription this member belongs to
    required String subscriptionId,

    /// ID of the user
    required String userId,

    /// Display name of the user
    required String userName,

    /// URL for the user's avatar/profile picture
    String? userAvatar,

    /// Amount this member needs to pay
    required double amountToPay,

    /// Whether the member has paid for the current billing cycle
    @Default(false) bool hasPaid,

    /// Date of the last payment made by this member
    DateTime? lastPaymentDate,

    /// Due date for this member's payment
    required DateTime dueDate,

    /// When the member was added to the subscription
    required DateTime createdAt,
  }) = _SubscriptionMember;

  const SubscriptionMember._();

  /// Calculate days overdue (null if not overdue or already paid)
  int? get daysOverdue {
    if (hasPaid) return null;

    final now = DateTime.now();
    if (now.isBefore(dueDate)) return null;

    final difference = now.difference(dueDate);
    return difference.inDays;
  }

  /// Check if payment is overdue
  bool get isOverdue {
    if (hasPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Check if payment is due soon (within 3 days)
  bool get isDueSoon {
    if (hasPaid) return false;

    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays <= 3 && difference.inDays >= 0;
  }

  /// Get days until payment is due (negative if overdue, null if paid)
  int? get daysUntilDue {
    if (hasPaid) return null;

    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  /// Get payment status as a human-readable string
  String get paymentStatus {
    if (hasPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    return 'Pending';
  }
}
