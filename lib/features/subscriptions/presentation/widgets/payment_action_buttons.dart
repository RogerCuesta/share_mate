// lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payment action buttons widget for bulk operations
///
/// Features:
/// - "Mark All as Paid" button (only shows if there are pending payments)
/// - Shows loading state during operation
/// - Success/error feedback via SnackBar
/// - Material 3 dark theme styling
class PaymentActionButtons extends ConsumerWidget {
  const PaymentActionButtons({
    required this.subscriptionId,
    required this.hasPendingPayments,
    super.key,
  });

  final String subscriptionId;
  final bool hasPendingPayments;

  /// Handle mark all as paid action
  Future<void> _handleMarkAllAsPaid(BuildContext context, WidgetRef ref) async {
    debugPrint('🔍 [PaymentActionButtons] Marking all payments as paid...');
    debugPrint('   Subscription: $subscriptionId');

    final paymentNotifier = ref.read(paymentActionProvider.notifier);
    final count = await paymentNotifier.markAllAsPaid(
      subscriptionId: subscriptionId,
    );

    if (!context.mounted) return;

    if (count > 0) {
      // Success - show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All $count payment${count > 1 ? 's' : ''} marked as paid',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E2D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Reset state after showing success
      Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted) {
          ref.read(paymentActionProvider.notifier).reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to payment action state for error handling
    ref.listen<PaymentActionState>(
      paymentActionProvider,
      (previous, next) {
        next.maybeWhen(
          error: (message) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E1E2D),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          orElse: () {},
        );
      },
    );

    final isLoading = ref.watch(paymentActionProvider).maybeWhen(
          loading: () => true,
          orElse: () => false,
        );

    // Don't show button if no pending payments
    if (!hasPendingPayments) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => _handleMarkAllAsPaid(context, ref),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6B4FBB),
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          isLoading ? 'Marking all as paid...' : 'Mark All as Paid',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6B4FBB),
          disabledForegroundColor: const Color(0xFF6B4FBB).withValues(alpha: 0.5),
          side: BorderSide(
            color: isLoading
                ? const Color(0xFF6B4FBB).withValues(alpha: 0.5)
                : const Color(0xFF6B4FBB),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
