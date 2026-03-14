import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_operational_snackbar.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payment status toggle widget with checkbox and undo functionality.
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
  Timer? _undoTimer;
  bool _canUndo = false;
  bool _lastPaidStatus = false;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  Future<void> _togglePaymentStatus(bool? newValue) async {
    if (newValue == null) {
      return;
    }

    _undoTimer?.cancel();
    _canUndo = false;

    final paymentNotifier = ref.read(paymentActionProvider.notifier);
    if (paymentNotifier.loadingMember(widget.member.id) ||
        paymentNotifier.loadingBulk(widget.subscriptionId)) {
      return;
    }

    if (newValue) {
      _lastPaidStatus = true;
      final success = await paymentNotifier.markAsPaid(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
      );

      if (success && mounted) {
        _showUndoableSuccess(
          '${widget.member.userName} marked as paid (\$${widget.member.amountToPay.toStringAsFixed(2)})',
        );
      }
      return;
    }

    _lastPaidStatus = false;
    final success = await paymentNotifier.unmark(
      subscriptionId: widget.subscriptionId,
      memberId: widget.member.id,
      amount: widget.member.amountToPay,
    );

    if (success && mounted) {
      _showUndoableSuccess(
        '${widget.member.userName} unmarked (\$${widget.member.amountToPay.toStringAsFixed(2)})',
      );
    }
  }

  void _showUndoableSuccess(String message) {
    setState(() {
      _canUndo = true;
    });

    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _canUndo = false;
      });
    });

    AppOperationalSnackbar.show(
      context,
      message: message,
      tone: AppOperationalTone.success,
      duration: const Duration(seconds: 5),
      actionLabel: 'Undo',
      onAction: _handleUndo,
    );
  }

  Future<void> _handleUndo() async {
    if (!_canUndo) {
      return;
    }

    _undoTimer?.cancel();
    if (mounted) {
      setState(() {
        _canUndo = false;
      });
    }

    final paymentNotifier = ref.read(paymentActionProvider.notifier);

    if (_lastPaidStatus) {
      await paymentNotifier.unmark(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
        notes: 'Undo - Unmarked via undo button',
      );
    } else {
      await paymentNotifier.markAsPaid(
        subscriptionId: widget.subscriptionId,
        memberId: widget.member.id,
        amount: widget.member.amountToPay,
        notes: 'Undo - Marked as paid via undo button',
      );
    }

    if (!mounted) {
      return;
    }

    AppOperationalSnackbar.show(
      context,
      message: 'Action undone',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    ref.listen<PaymentActionState>(
      paymentActionProvider,
      (previous, next) {
        next.maybeWhen(
          error: (message) {
            if (!mounted) {
              return;
            }
            AppOperationalSnackbar.show(
              context,
              message: message,
              tone: AppOperationalTone.error,
              duration: const Duration(seconds: 3),
            );
          },
          orElse: () {},
        );
      },
    );

    final paymentState = ref.watch(paymentActionProvider);
    final paymentNotifier = ref.read(paymentActionProvider.notifier);
    final isLoading = paymentState.maybeWhen(
          loadingMember: (memberId) => memberId == widget.member.id,
          loadingBulk: (subscriptionId) =>
              subscriptionId == widget.subscriptionId,
          orElse: () => false,
        ) ||
        paymentNotifier.loadingMember(widget.member.id) ||
        paymentNotifier.loadingBulk(widget.subscriptionId);

    final isPaid = widget.member.hasPaid;
    final paidAccent = tokens.statusSuccess;

    return GestureDetector(
      onTap: isLoading ? null : () => _togglePaymentStatus(!isPaid),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surfaceAccent,
          borderRadius: BorderRadius.circular(tokens.borderRadiusMedium),
          border: Border.all(
            color: isPaid
                ? paidAccent.withValues(alpha: 0.3)
                : tokens.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: tokens.surfaceRaised,
              child: Text(
                widget.member.userName[0].toUpperCase(),
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member.userName,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${widget.member.amountToPay.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPaid ? paidAccent : tokens.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.ctaPrimary,
                ),
              )
            else
              Checkbox(
                value: isPaid,
                onChanged: _togglePaymentStatus,
                activeColor: paidAccent,
                checkColor: tokens.textOnAccent,
                side: BorderSide(
                  color: isPaid ? paidAccent : tokens.borderStrong,
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
