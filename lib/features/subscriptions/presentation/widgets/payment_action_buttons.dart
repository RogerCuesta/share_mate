import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_operational_snackbar.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payment action buttons widget for bulk operations.
class PaymentActionButtons extends ConsumerWidget {
  const PaymentActionButtons({
    required this.subscriptionId,
    required this.hasPendingPayments,
    super.key,
  });

  final String subscriptionId;
  final bool hasPendingPayments;

  Future<void> _handleMarkAllAsPaid(BuildContext context, WidgetRef ref) async {
    final paymentNotifier = ref.read(paymentActionProvider.notifier);
    final count = await paymentNotifier.markAllAsPaid(
      subscriptionId: subscriptionId,
    );

    if (!context.mounted || count <= 0) {
      return;
    }

    AppOperationalSnackbar.show(
      context,
      message: 'All $count payment${count > 1 ? 's' : ''} marked as paid',
      tone: AppOperationalTone.success,
      duration: const Duration(seconds: 3),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        ref.read(paymentActionProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).appTokens;

    ref.listen<PaymentActionState>(
      paymentActionProvider,
      (previous, next) {
        next.maybeWhen(
          error: (message) {
            if (!context.mounted) {
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
          loadingBulk: (id) => id == subscriptionId,
          orElse: () => false,
        ) ||
        paymentNotifier.hasLoadingMembersInSubscription(subscriptionId);

    if (!hasPendingPayments) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : () => _handleMarkAllAsPaid(context, ref),
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.ctaPrimary,
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          isLoading ? 'Marking all as paid...' : 'Mark All as Paid',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ctaPrimary,
          disabledForegroundColor: tokens.ctaPrimary.withValues(alpha: 0.55),
          side: BorderSide(
            color: isLoading
                ? tokens.ctaPrimary.withValues(alpha: 0.55)
                : tokens.ctaPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.borderRadiusMedium),
          ),
        ),
      ),
    );
  }
}
