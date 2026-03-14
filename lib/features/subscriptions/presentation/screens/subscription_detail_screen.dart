import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_confirmation_dialog.dart';
import 'package:flutter_project_agents/core/widgets/app_operational_snackbar.dart';
import 'package:flutter_project_agents/core/widgets/app_screen_scaffold.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_section_header.dart';
import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscription_detail_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/payment_action_buttons.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/payment_stats_card.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/payment_status_toggle.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

export 'package:flutter_project_agents/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart';

@visibleForTesting
List<SubscriptionMember> sortMembersForDetail(
  Iterable<SubscriptionMember> members,
) {
  final sortedMembers = [...members]..sort((a, b) {
      if (a.hasPaid != b.hasPaid) {
        return a.hasPaid ? 1 : -1;
      }

      final dueDateComparison = a.dueDate.compareTo(b.dueDate);
      if (dueDateComparison != 0) {
        return dueDateComparison;
      }

      final nameComparison = a.userName.toLowerCase().compareTo(
            b.userName.toLowerCase(),
          );
      if (nameComparison != 0) {
        return nameComparison;
      }

      return a.id.compareTo(b.id);
    });
  return sortedMembers;
}

class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({
    required this.subscriptionId,
    super.key,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync =
        ref.watch(subscriptionDetailProvider(subscriptionId));
    final membersAsync = ref.watch(subscriptionMembersProvider(subscriptionId));
    final statsAsync = ref.watch(subscriptionStatsProvider(subscriptionId));
    final syncStatus = ref.watch(subscriptionDetailSyncStatusProvider);

    ref.listen<PaymentReconciliationSignal?>(
      paymentReconciliationProvider,
      (previous, next) {
        if (next == null || previous?.sequence == next.sequence) {
          return;
        }
        _handleReconciliationSignal(
          context: context,
          ref: ref,
          signal: next,
        );
      },
    );

    return subscriptionAsync.when(
      loading: () => _buildLoadingState(context),
      error: (error, _) => _buildErrorState(context, ref, error),
      data: (subscription) => _buildContent(
        context,
        ref,
        subscription,
        membersAsync,
        statsAsync,
        syncStatus,
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Loading...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final tokens = Theme.of(context).appTokens;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: tokens.statusError,
              ),
              SizedBox(height: tokens.spacingSmall),
              Text(
                'Failed to load subscription',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: tokens.spacingXSmall),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spacingMedium),
              ElevatedButton.icon(
                onPressed: () {
                  ref
                    ..invalidate(subscriptionDetailProvider(subscriptionId))
                    ..invalidate(subscriptionMembersProvider(subscriptionId))
                    ..invalidate(subscriptionStatsProvider(subscriptionId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReconciliationSignal({
    required BuildContext context,
    required WidgetRef ref,
    required PaymentReconciliationSignal signal,
  }) {
    ref
      ..invalidate(subscriptionMembersProvider(subscriptionId))
      ..invalidate(subscriptionStatsProvider(subscriptionId))
      ..invalidate(debtHomeSnapshotProvider)
      ..invalidate(monthlyStatsProvider)
      ..invalidate(pendingPaymentsProvider);

    if (!context.mounted) {
      return;
    }

    AppOperationalSnackbar.show(
      context,
      message: paymentReconciliationMessage(signal.reason),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
    AsyncValue<List<SubscriptionMember>> membersAsync,
    AsyncValue<SubscriptionStatsData> statsAsync,
    SyncStatus syncStatus,
  ) {
    final tokens = Theme.of(context).appTokens;
    final members = sortMembersForDetail(membersAsync.valueOrNull ?? []);
    final stats = statsAsync.valueOrNull;

    return AppScreenScaffold(
      appBar: _buildAppBar(context, ref, subscription),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingLarge,
        vertical: tokens.spacingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubscriptionDetailSummaryHero(subscription: subscription),
          SizedBox(height: tokens.spacingMedium),
          _CostInformationCard(subscription: subscription),
          SizedBox(height: tokens.spacingMedium),
          SubscriptionDetailSyncStatusCard(syncStatus: syncStatus),
          if (members.isNotEmpty) ...[
            SizedBox(height: tokens.spacingMedium),
            _MembersSection(
              members: members,
              subscriptionId: subscriptionId,
            ),
            SizedBox(height: tokens.spacingMedium),
            if (stats != null)
              _SplitInformationCard(
                stats: stats,
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            SizedBox(height: tokens.spacingMedium),
            PaymentStatsCard(subscriptionId: subscriptionId),
            SizedBox(height: tokens.spacingMedium),
          ],
          _ActionButtons(
            subscriptionId: subscriptionId,
            hasPendingPayments: members.any((member) => !member.hasPaid),
            onDeletePressed: () => _deleteSubscription(context, ref),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) {
    final tokens = Theme.of(context).appTokens;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: const Text('Subscription Details'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            context.push('/subscription/$subscriptionId/edit');
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: tokens.statusError,
          ),
          onPressed: () => _deleteSubscription(context, ref),
          tooltip: 'Delete Subscription',
        ),
      ],
    );
  }

  Future<void> _deleteSubscription(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Delete Subscription?',
      message:
          'This will permanently delete the subscription and all associated data. This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final deleteSubscriptionUseCase = ref.read(deleteSubscriptionProvider);
    final result = await deleteSubscriptionUseCase(subscriptionId);

    if (!context.mounted) {
      return;
    }

    result.fold(
      (failure) {
        final message = failure.maybeWhen(
          notFound: () => 'Subscription not found',
          networkError: () => 'Network error. Please check your connection.',
          orElse: () => 'Failed to delete subscription',
        );

        AppOperationalSnackbar.show(
          context,
          message: message,
          tone: AppOperationalTone.error,
        );
      },
      (_) {
        ref
          ..invalidate(activeSubscriptionsProvider)
          ..invalidate(monthlyStatsProvider)
          ..invalidate(debtHomeSnapshotProvider)
          ..invalidate(pendingPaymentsProvider);

        AppOperationalSnackbar.show(
          context,
          message: 'Subscription deleted successfully',
          tone: AppOperationalTone.success,
        );

        context.pop();
      },
    );
  }
}

class _CostInformationCard extends StatelessWidget {
  const _CostInformationCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      subscription.dueDate.year,
      subscription.dueDate.month,
      subscription.dueDate.day,
    );
    final dueDelta = dueDate.difference(today).inDays;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Cost Information',
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Total Cost',
            value: '\$${subscription.totalCost.toStringAsFixed(2)}',
            emphasized: true,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Billing Cycle',
            value: subscription.billingCycle.displayName,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Next Due Date',
            value: DateFormat('MMM dd, yyyy').format(subscription.dueDate),
            detail: _dueCopy(dueDelta),
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            label: 'Owner',
            value: 'You',
          ),
        ],
      ),
    );
  }

  String _dueCopy(int daysUntilDue) {
    if (daysUntilDue < 0) {
      final overdueDays = daysUntilDue.abs();
      return overdueDays == 1
          ? 'Overdue by 1 day'
          : 'Overdue by $overdueDays days';
    }
    if (daysUntilDue == 0) {
      return 'Due today';
    }
    if (daysUntilDue == 1) {
      return 'Due in 1 day';
    }
    return 'Due in $daysUntilDue days';
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.members,
    required this.subscriptionId,
  });

  final List<SubscriptionMember> members;
  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppSectionCard(
      tone: AppSectionCardTone.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Members',
            count: members.length,
          ),
          const SizedBox(height: 16),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PaymentStatusToggle(
                key: ValueKey('payment-toggle-${member.id}'),
                member: member,
                subscriptionId: subscriptionId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitInformationCard extends StatelessWidget {
  const _SplitInformationCard({required this.stats});

  final SubscriptionStatsData stats;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Split Information'),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Total Members',
            value: '${stats.totalMembers} people',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Your Share',
            value: '\$${stats.yourShare.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Collected So Far',
            value: '\$${stats.collectedAmount.toStringAsFixed(2)}',
            highlightedColorRole: _HighlightColorRole.success,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Remaining to Collect',
            value: '\$${stats.remainingAmount.toStringAsFixed(2)}',
            highlightedColorRole: _HighlightColorRole.warning,
          ),
        ],
      ),
    );
  }
}

enum _HighlightColorRole { none, success, warning }

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.detail,
    this.emphasized = false,
    this.highlightedColorRole = _HighlightColorRole.none,
  });

  final String label;
  final String value;
  final String? detail;
  final bool emphasized;
  final _HighlightColorRole highlightedColorRole;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    final valueColor = switch (highlightedColorRole) {
      _HighlightColorRole.success => tokens.statusSuccess,
      _HighlightColorRole.warning => tokens.statusWarning,
      _HighlightColorRole.none => tokens.textPrimary,
    };

    final valueStyle = emphasized
        ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: valueStyle),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(
                detail!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.textMuted,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.subscriptionId,
    required this.hasPendingPayments,
    required this.onDeletePressed,
  });

  final String subscriptionId;
  final bool hasPendingPayments;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Column(
      children: [
        PaymentActionButtons(
          subscriptionId: subscriptionId,
          hasPendingPayments: hasPendingPayments,
        ),
        if (hasPendingPayments) SizedBox(height: tokens.spacingSmall + 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/subscription/$subscriptionId/edit');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Subscription'),
          ),
        ),
        SizedBox(height: tokens.spacingSmall + 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onDeletePressed,
            icon: Icon(
              Icons.delete_outline,
              color: tokens.statusError,
            ),
            label: Text(
              'Delete Subscription',
              style: TextStyle(color: tokens.statusError),
            ),
            style: OutlinedButton.styleFrom(
              side:
                  BorderSide(color: tokens.statusError.withValues(alpha: 0.7)),
            ),
          ),
        ),
      ],
    );
  }
}
