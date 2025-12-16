// lib/features/subscriptions/domain/entities/subscription_member_input.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_member_input.freezed.dart';

/// Input entity for adding members to a subscription (form data)
///
/// This is used in the Create Group Subscription form to collect
/// member information before creating the actual subscription.
@freezed
class SubscriptionMemberInput with _$SubscriptionMemberInput {
  const factory SubscriptionMemberInput({
    /// Temporary ID for the member (generated locally)
    required String id,

    /// Display name of the member
    required String name,

    /// Email address of the member
    required String email,

    /// Optional avatar URL
    String? avatar,
  }) = _SubscriptionMemberInput;

  const SubscriptionMemberInput._();

  /// Validate member input
  String? validate() {
    // Validate name
    if (name.trim().isEmpty) {
      return 'Member name cannot be empty';
    }

    if (name.trim().length < 2) {
      return 'Member name must be at least 2 characters';
    }

    // Validate email
    if (email.trim().isEmpty) {
      return 'Email cannot be empty';
    }

    // Email regex validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email.trim())) {
      return 'Invalid email format';
    }

    return null;
  }

  /// Check if input is valid
  bool get isValid => validate() == null;
}
