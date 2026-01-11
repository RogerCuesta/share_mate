// lib/features/subscriptions/presentation/providers/payment_provider.dart
import 'package:flutter/foundation.dart';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/payment_history.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscription_detail_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_provider.freezed.dart';
part 'payment_provider.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT ACTION STATE
// ═══════════════════════════════════════════════════════════════════════════

/// State for payment actions (mark as paid, unmark, bulk operations)
///
/// Uses sealed class pattern for exhaustive state handling.
@freezed
class PaymentActionState with _$PaymentActionState {
  /// Initial idle state - no action in progress
  const factory PaymentActionState.idle() = _Idle;

  /// Loading state - action in progress
  const factory PaymentActionState.loading() = _Loading;

  /// Success state - single payment marked
  const factory PaymentActionState.success(PaymentHistory payment) = _Success;

  /// Bulk success state - multiple payments marked
  const factory PaymentActionState.bulkSuccess(int count) = _BulkSuccess;

  /// Error state - action failed
  const factory PaymentActionState.error(String message) = _Error;
}

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENT ACTION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier for managing payment actions
///
/// Provides methods to:
/// - Mark a single payment as paid
/// - Mark all pending payments as paid (bulk operation)
/// - Unmark a payment (undo functionality)
///
/// After successful operations, automatically invalidates relevant providers
/// to trigger UI updates.
@riverpod
class PaymentAction extends _$PaymentAction {
  @override
  PaymentActionState build() {
    return const PaymentActionState.idle();
  }

  /// Mark a single member's payment as paid
  ///
  /// [subscriptionId] - ID of the subscription
  /// [memberId] - ID of the member making the payment
  /// [amount] - Amount being paid
  /// [notes] - Optional notes about the payment
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> markAsPaid({
    required String subscriptionId,
    required String memberId,
    required double amount,
    String? notes,
  }) async {
    debugPrint('🔍 [PaymentAction] Marking payment as paid...');
    debugPrint('   Subscription: $subscriptionId');
    debugPrint('   Member: $memberId');
    debugPrint('   Amount: \$${amount.toStringAsFixed(2)}');

    // Set loading state
    state = const PaymentActionState.loading();

    try {
      // Get current user ID
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        debugPrint('❌ [PaymentAction] No authenticated user');
        state = const PaymentActionState.error('Not authenticated');
        return false;
      }

      // Execute use case
      final markPaymentAsPaidUseCase = ref.read(markPaymentAsPaidProvider);
      final result = await markPaymentAsPaidUseCase(
        subscriptionId: subscriptionId,
        memberId: memberId,
        amount: amount,
        markedBy: userId,
        notes: notes,
      );

      return result.fold(
        (failure) {
          final message = failure.maybeWhen(
            notFound: () => 'Payment not found',
            networkError: () => 'Network error. Please check your connection.',
            invalidData: (msg) => msg,
            orElse: () => 'Failed to mark payment as paid',
          );
          debugPrint('❌ [PaymentAction] Error: $message');
          state = PaymentActionState.error(message);
          return false;
        },
        (payment) {
          debugPrint('✅ [PaymentAction] Payment marked successfully');
          state = PaymentActionState.success(payment);

          // Invalidate relevant providers to refresh UI
          _invalidateProviders(subscriptionId);

          return true;
        },
      );
    } catch (e) {
      debugPrint('❌ [PaymentAction] Unexpected error: $e');
      state = PaymentActionState.error('Unexpected error: $e');
      return false;
    }
  }

  /// Mark all pending payments as paid for a subscription
  ///
  /// [subscriptionId] - ID of the subscription
  /// [notes] - Optional notes about the bulk payment
  ///
  /// Returns the count of payments marked if successful, 0 otherwise.
  Future<int> markAllAsPaid({
    required String subscriptionId,
    String? notes,
  }) async {
    debugPrint('🔍 [PaymentAction] Marking all payments as paid...');
    debugPrint('   Subscription: $subscriptionId');

    // Set loading state
    state = const PaymentActionState.loading();

    try {
      // Get current user ID
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        debugPrint('❌ [PaymentAction] No authenticated user');
        state = const PaymentActionState.error('Not authenticated');
        return 0;
      }

      // Execute use case
      final markAllPaymentsAsPaidUseCase =
          ref.read(markAllPaymentsAsPaidProvider);
      final result = await markAllPaymentsAsPaidUseCase(
        subscriptionId: subscriptionId,
        markedBy: userId,
        notes: notes,
      );

      return result.fold(
        (failure) {
          final message = failure.maybeWhen(
            notFound: () => 'Subscription not found',
            networkError: () => 'Network error. Please check your connection.',
            invalidData: (msg) => msg,
            orElse: () => 'Failed to mark all payments as paid',
          );
          debugPrint('❌ [PaymentAction] Error: $message');
          state = PaymentActionState.error(message);
          return 0;
        },
        (count) {
          debugPrint('✅ [PaymentAction] $count payments marked successfully');
          state = PaymentActionState.bulkSuccess(count);

          // Invalidate relevant providers to refresh UI
          _invalidateProviders(subscriptionId);

          return count;
        },
      );
    } catch (e) {
      debugPrint('❌ [PaymentAction] Unexpected error: $e');
      state = PaymentActionState.error('Unexpected error: $e');
      return 0;
    }
  }

  /// Unmark a payment (undo paid status)
  ///
  /// [subscriptionId] - ID of the subscription
  /// [memberId] - ID of the member
  /// [amount] - Amount to unmark
  /// [notes] - Optional notes about why unmarking
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> unmark({
    required String subscriptionId,
    required String memberId,
    required double amount,
    String? notes,
  }) async {
    debugPrint('🔍 [PaymentAction] Unmarking payment...');
    debugPrint('   Subscription: $subscriptionId');
    debugPrint('   Member: $memberId');
    debugPrint('   Amount: \$${amount.toStringAsFixed(2)}');

    // Set loading state
    state = const PaymentActionState.loading();

    try {
      // Get current user ID
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        debugPrint('❌ [PaymentAction] No authenticated user');
        state = const PaymentActionState.error('Not authenticated');
        return false;
      }

      // Execute use case
      final unmarkPaymentUseCase = ref.read(unmarkPaymentProvider);
      final result = await unmarkPaymentUseCase(
        subscriptionId: subscriptionId,
        memberId: memberId,
        amount: amount,
        markedBy: userId,
        notes: notes,
      );

      return result.fold(
        (failure) {
          final message = failure.maybeWhen(
            notFound: () => 'Payment not found',
            networkError: () => 'Network error. Please check your connection.',
            invalidData: (msg) => msg,
            orElse: () => 'Failed to unmark payment',
          );
          debugPrint('❌ [PaymentAction] Error: $message');
          state = PaymentActionState.error(message);
          return false;
        },
        (payment) {
          debugPrint('✅ [PaymentAction] Payment unmarked successfully');
          state = PaymentActionState.success(payment);

          // Invalidate relevant providers to refresh UI
          _invalidateProviders(subscriptionId);

          return true;
        },
      );
    } catch (e) {
      debugPrint('❌ [PaymentAction] Unexpected error: $e');
      state = PaymentActionState.error('Unexpected error: $e');
      return false;
    }
  }

  /// Reset state back to idle
  void reset() {
    state = const PaymentActionState.idle();
  }

  /// Invalidate relevant providers after payment mutations
  ///
  /// This ensures the UI updates to reflect the new payment status.
  void _invalidateProviders(String subscriptionId) {
    debugPrint('🔄 [PaymentAction] Invalidating providers...');

    // Invalidate subscription members (payment status changed)
    ref.invalidate(subscriptionMembersProvider(subscriptionId));

    // Invalidate subscription stats (collected/remaining amounts changed)
    ref.invalidate(subscriptionStatsProvider(subscriptionId));

    // Invalidate monthly stats (pending to collect changed)
    ref.invalidate(monthlyStatsProvider);

    // Invalidate pending payments (may have decreased)
    ref.invalidate(pendingPaymentsProvider);

    debugPrint('✅ [PaymentAction] Providers invalidated');
  }
}
