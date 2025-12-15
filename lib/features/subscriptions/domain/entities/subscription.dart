import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';

/// Billing cycle for subscriptions
enum BillingCycle {
  monthly,
  yearly;

  /// Get the number of months for this billing cycle
  int get months {
    switch (this) {
      case BillingCycle.monthly:
        return 1;
      case BillingCycle.yearly:
        return 12;
    }
  }

  /// Get display name for the billing cycle
  String get displayName {
    switch (this) {
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }
}

/// Status of a subscription
enum SubscriptionStatus {
  active,
  cancelled,
  paused;

  /// Check if the subscription is active
  bool get isActive => this == SubscriptionStatus.active;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.paused:
        return 'Paused';
    }
  }
}

/// Subscription entity representing a shared subscription service
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    /// Unique identifier for the subscription
    required String id,

    /// Name of the subscription service (e.g., "Netflix", "Spotify")
    required String name,

    /// URL for the service icon/logo
    String? iconUrl,

    /// Hex color for the subscription card (e.g., "#E50914" for Netflix)
    required String color,

    /// Total monthly cost of the subscription
    required double totalCost,

    /// Billing cycle (monthly or yearly)
    required BillingCycle billingCycle,

    /// Due date for the next payment
    required DateTime dueDate,

    /// ID of the user who owns/pays for the main subscription
    required String ownerId,

    /// List of user IDs who share this subscription
    @Default([]) List<String> sharedWith,

    /// Current status of the subscription
    @Default(SubscriptionStatus.active) SubscriptionStatus status,

    /// When the subscription was created
    required DateTime createdAt,
  }) = _Subscription;

  const Subscription._();

  /// Calculate cost per person based on total members
  double get costPerPerson {
    final totalMembers = sharedWith.length + 1; // +1 for owner
    return totalCost / totalMembers;
  }

  /// Get total number of members (including owner)
  int get totalMembers => sharedWith.length + 1;

  /// Check if subscription is overdue
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status.isActive;

  /// Get days until due date (negative if overdue)
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  /// Check if subscription is due soon (within 3 days)
  bool get isDueSoon {
    return daysUntilDue <= 3 && daysUntilDue >= 0 && status.isActive;
  }

  /// Get monthly cost (convert from yearly if needed)
  double get monthlyCost {
    return billingCycle == BillingCycle.monthly
        ? totalCost
        : totalCost / 12;
  }
}
