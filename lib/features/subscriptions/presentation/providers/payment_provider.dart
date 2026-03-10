// lib/features/subscriptions/presentation/providers/payment_provider.dart
import 'package:flutter/foundation.dart';

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/sync_logger.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
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

  /// Loading state for a single member action.
  const factory PaymentActionState.loadingMember(String memberId) =
      _LoadingMember;

  /// Loading state for bulk action in a specific subscription.
  const factory PaymentActionState.loadingBulk(String subscriptionId) =
      _LoadingBulk;

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
  static const SyncLogger _syncLogger = SyncLogger(scope: 'PaymentAction');
  final Set<String> _loadingMembers = <String>{};
  final Set<String> _loadingBulkSubscriptions = <String>{};
  final Map<String, Set<String>> _loadingMembersBySubscription =
      <String, Set<String>>{};

  @override
  PaymentActionState build() {
    return const PaymentActionState.idle();
  }

  /// Returns true when the given member has an in-flight action.
  bool loadingMember(String memberId) {
    return _loadingMembers.contains(memberId);
  }

  /// Returns true when a bulk action for the given subscription is in-flight.
  bool loadingBulk(String subscriptionId) {
    return _loadingBulkSubscriptions.contains(subscriptionId);
  }

  bool hasLoadingMembersInSubscription(String subscriptionId) {
    return (_loadingMembersBySubscription[subscriptionId]?.isNotEmpty ?? false);
  }

  void _startMemberLoading({
    required String subscriptionId,
    required String memberId,
  }) {
    _loadingMembers.add(memberId);
    _loadingMembersBySubscription
        .putIfAbsent(subscriptionId, () => <String>{})
        .add(memberId);
    state = PaymentActionState.loadingMember(memberId);
  }

  void _finishMemberLoading({
    required String subscriptionId,
    required String memberId,
  }) {
    _loadingMembers.remove(memberId);
    final members = _loadingMembersBySubscription[subscriptionId];
    if (members != null) {
      members.remove(memberId);
      if (members.isEmpty) {
        _loadingMembersBySubscription.remove(subscriptionId);
      }
    }
  }

  void _startBulkLoading(String subscriptionId) {
    _loadingBulkSubscriptions.add(subscriptionId);
    state = PaymentActionState.loadingBulk(subscriptionId);
  }

  void _finishBulkLoading(String subscriptionId) {
    _loadingBulkSubscriptions.remove(subscriptionId);
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
    if (loadingMember(memberId) || loadingBulk(subscriptionId)) {
      return false;
    }

    _syncLogger.logSync(
      event: 'payment_mark_as_paid_started',
      actionType: 'paid',
      metadata: {'source': 'provider'},
    );

    // Set scoped loading state
    _startMemberLoading(subscriptionId: subscriptionId, memberId: memberId);

    try {
      // Get current user ID
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        _syncLogger.logTerminal(
          event: 'payment_mark_as_paid_auth_blocked',
          operationId: 'payment_mark_as_paid_auth',
          terminalReason: 'not_authenticated',
          errorClass: 'auth',
          errorCode: 'not_authenticated',
        );
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
          _syncLogger.logSync(
            event: 'payment_mark_as_paid_failed',
            actionType: 'paid',
            errorClass: 'domain_failure',
            errorCode: failure.runtimeType.toString(),
            metadata: {'source': 'provider'},
          );
          state = PaymentActionState.error(message);
          return false;
        },
        (payment) {
          _syncLogger.logSync(
            event: 'payment_mark_as_paid_succeeded',
            actionType: 'paid',
            metadata: {'source': 'provider'},
          );
          state = PaymentActionState.success(payment);

          // Invalidate relevant providers to refresh UI
          _invalidateProviders(subscriptionId);

          return true;
        },
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'payment_mark_as_paid_exception',
        operationId: 'payment_mark_as_paid_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
      state = PaymentActionState.error('Unexpected error: $e');
      return false;
    } finally {
      _finishMemberLoading(subscriptionId: subscriptionId, memberId: memberId);
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
    if (loadingBulk(subscriptionId) ||
        hasLoadingMembersInSubscription(subscriptionId)) {
      return 0;
    }

    _syncLogger.logSync(
      event: 'payment_mark_all_started',
      actionType: 'paid_bulk',
      metadata: {'source': 'provider'},
    );

    // Set scoped loading state
    _startBulkLoading(subscriptionId);

    try {
      // Get current user ID
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        _syncLogger.logTerminal(
          event: 'payment_mark_all_auth_blocked',
          operationId: 'payment_mark_all_auth',
          terminalReason: 'not_authenticated',
          errorClass: 'auth',
          errorCode: 'not_authenticated',
        );
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
          _syncLogger.logSync(
            event: 'payment_mark_all_failed',
            actionType: 'paid_bulk',
            errorClass: 'domain_failure',
            errorCode: failure.runtimeType.toString(),
            metadata: {'source': 'provider'},
          );
          state = PaymentActionState.error(message);
          return 0;
        },
        (count) {
          _syncLogger.logSync(
            event: 'payment_mark_all_succeeded',
            actionType: 'paid_bulk',
            metadata: {'source': 'provider', 'updated_count': count},
          );
          state = PaymentActionState.bulkSuccess(count);

          // Invalidate relevant providers to refresh UI
          _invalidateProviders(subscriptionId);

          return count;
        },
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'payment_mark_all_exception',
        operationId: 'payment_mark_all_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
      state = PaymentActionState.error('Unexpected error: $e');
      return 0;
    } finally {
      _finishBulkLoading(subscriptionId);
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
    if (loadingMember(memberId) || loadingBulk(subscriptionId)) {
      return false;
    }

    _syncLogger.logSync(
      event: 'payment_unmark_started',
      actionType: 'unpaid',
      metadata: {'source': 'provider'},
    );

    // Set scoped loading state
    _startMemberLoading(subscriptionId: subscriptionId, memberId: memberId);

    try {
      // Get current user ID
      final authState = ref.read(authProvider);
      final userId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        _syncLogger.logTerminal(
          event: 'payment_unmark_auth_blocked',
          operationId: 'payment_unmark_auth',
          terminalReason: 'not_authenticated',
          errorClass: 'auth',
          errorCode: 'not_authenticated',
        );
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
          _syncLogger.logSync(
            event: 'payment_unmark_failed',
            actionType: 'unpaid',
            errorClass: 'domain_failure',
            errorCode: failure.runtimeType.toString(),
            metadata: {'source': 'provider'},
          );
          state = PaymentActionState.error(message);
          return false;
        },
        (payment) {
          _syncLogger.logSync(
            event: 'payment_unmark_succeeded',
            actionType: 'unpaid',
            metadata: {'source': 'provider'},
          );
          state = PaymentActionState.success(payment);

          // Invalidate relevant providers to refresh UI
          _invalidateProviders(subscriptionId);

          return true;
        },
      );
    } catch (e) {
      _syncLogger.logTerminal(
        event: 'payment_unmark_exception',
        operationId: 'payment_unmark_exception',
        terminalReason: 'unexpected_exception',
        errorClass: e.runtimeType.toString(),
      );
      state = PaymentActionState.error('Unexpected error: $e');
      return false;
    } finally {
      _finishMemberLoading(subscriptionId: subscriptionId, memberId: memberId);
    }
  }

  /// Reset state back to idle
  void reset() {
    _loadingMembers.clear();
    _loadingBulkSubscriptions.clear();
    _loadingMembersBySubscription.clear();
    state = const PaymentActionState.idle();
  }

  /// Invalidate relevant providers after payment mutations
  ///
  /// This ensures the UI updates to reflect the new payment status.
  void _invalidateProviders(String subscriptionId) {
    _syncLogger.logSync(
      event: 'payment_provider_invalidation_started',
      metadata: {'source': 'provider'},
    );

    // Invalidate subscription members (payment status changed)
    ref.invalidate(subscriptionMembersProvider(subscriptionId));

    // Invalidate subscription stats (collected/remaining amounts changed)
    ref.invalidate(subscriptionStatsProvider(subscriptionId));

    // Invalidate monthly stats (pending to collect changed)
    ref.invalidate(monthlyStatsProvider);

    // Invalidate pending payments (may have decreased)
    ref.invalidate(pendingPaymentsProvider);

    // Invalidate debt-home snapshot (Home debt card + next collection)
    ref.invalidate(debtHomeSnapshotProvider);

    _syncLogger.logSync(
      event: 'payment_provider_invalidation_completed',
      metadata: {'source': 'provider'},
    );
  }
}
