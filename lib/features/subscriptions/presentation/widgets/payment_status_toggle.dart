// lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payment status toggle widget with checkbox and undo functionality
///
/// Features:
/// - Checkbox to mark payment as paid/unpaid
/// - Shows amount to pay
/// - Undo functionality with 5-second window
/// - SnackBar feedback with undo button
/// - Material 3 dark theme styling
class PaymentStatusToggle extends ConsumerStatefulWidget {
  const PaymentStatusToggle({
    required this.member,
    required this.subscriptionId,
    super.key,
  });

  final SubscriptionMember member;
  final String subscriptionId;

  @override
  ConsumerState<PaymentStatusToggle> createState() =>
      _PaymentStatusToggleState();
}

class _PaymentStatusToggleState extends ConsumerState<PaymentStatusToggle> {
  // Timer for undo window
  Timer? _undoTimer;

  // Track if we're in undo window
  bool _canUndo = false;

  // Store last action for undo
  bool _lastPaidStatus = false;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  /// Toggle payment status
  Future<void> _togglePaymentStatus(bool? newValue) async {
    if (newValue == null) return;

    debugPrint('🔍 [PaymentStatusToggle] Toggling payment status...');
    debugPrint('   Member: ${widget.member.userName}');
    debugPrint('   Current: ${widget.member.hasPaid}, New: $newValue');

    // Cancel existing undo timer if any
    _undoTimer?.cancel();
    _canUndo = false;

    final paymentNotifier = ref.read(paymentActionProvider.notifier);

    if (newValue) {
      // Mark as paid
      _lastPaidStatus = true;
      final success = await paymentNotifier.markAsPaid(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
      );

      if (success && mounted) {
        _showSuccessSnackBar(
          '${widget.member.userName} marked as paid (\$${widget.member.amountToPay.toStringAsFixed(2)})',
        );
      }
    } else {
      // Unmark payment
      _lastPaidStatus = false;
      final success = await paymentNotifier.unmark(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
      );

      if (success && mounted) {
        _showSuccessSnackBar(
          '${widget.member.userName} unmarked (\$${widget.member.amountToPay.toStringAsFixed(2)})',
        );
      }
    }
  }

  /// Show success SnackBar with undo button
  void _showSuccessSnackBar(String message) {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Enable undo
    setState(() {
      _canUndo = true;
    });

    // Start undo timer (5 seconds)
    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _canUndo = false;
        });
      }
    });

    // Show SnackBar
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
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF6B4FBB),
          onPressed: _handleUndo,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Handle undo action
  Future<void> _handleUndo() async {
    if (!_canUndo) return;

    debugPrint('🔄 [PaymentStatusToggle] Undoing last action...');

    // Cancel undo timer
    _undoTimer?.cancel();
    setState(() {
      _canUndo = false;
    });

    final paymentNotifier = ref.read(paymentActionProvider.notifier);

    // Reverse the last action
    if (_lastPaidStatus) {
      // Last action was marking as paid, so unmark
      await paymentNotifier.unmark(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
        notes: 'Undo - Unmarked via undo button',
      );
    } else {
      // Last action was unmarking, so mark as paid
      await paymentNotifier.markAsPaid(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
        notes: 'Undo - Marked as paid via undo button',
      );
    }

    // Show undo feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.undo,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Action undone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E2D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to payment action state for error handling
    ref.listen<PaymentActionState>(
      paymentActionProvider,
      (previous, next) {
        next.maybeWhen(
          error: (message) {
            if (mounted) {
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

    final isPaid = widget.member.hasPaid;

    return GestureDetector(
      onTap: isLoading ? null : () => _togglePaymentStatus(!isPaid),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPaid
                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[700],
              child: Text(
                widget.member.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${widget.member.amountToPay.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPaid
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6B4FBB),
                ),
              )
            else
              Checkbox(
                value: isPaid,
                onChanged: _togglePaymentStatus,
                activeColor: const Color(0xFF4CAF50),
                checkColor: Colors.white,
                side: BorderSide(
                  color: isPaid
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF9E9E9E),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
