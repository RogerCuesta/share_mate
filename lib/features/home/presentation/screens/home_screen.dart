import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_operational_snackbar.dart';
import 'package:flutter_project_agents/core/widgets/app_screen_scaffold.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/features/home/presentation/providers/debt_home_provider.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/action_required_section.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/active_subscriptions_section.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/debt_home_kpi_card.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/next_collection_card.dart';
import 'package:flutter_project_agents/features/home/presentation/widgets/stats_cards.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtSnapshotAsync = ref.watch(debtHomeSnapshotProvider);
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);
    final pendingAsync = ref.watch(pendingPaymentsProvider);

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

    return AppScreenScaffold.slivers(
      slivers: [
        const SliverToBoxAdapter(child: HomeHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: debtSnapshotAsync.when(
              data: (snapshot) => Column(
                key: const Key('home-debt-priority-section'),
                children: [
                  DebtHomeKpiCard(snapshot: snapshot),
                  const SizedBox(height: 16),
                  NextCollectionCard(snapshot: snapshot),
                ],
              ),
              loading: () => const _DebtPriorityLoading(),
              error: (error, _) => _DebtPriorityError(error: error),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: monthlyStatsAsync.when(
              data: (stats) => StatsCards(stats: stats),
              loading: () => const StatsCardsLoading(),
              error: (error, _) => StatsCardsError(error: error),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: pendingAsync.when(
              data: (pending) => ActionRequiredSection(
                pendingPayments: pending.take(2).toList(),
              ),
              loading: () => const ActionRequiredLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: subscriptionsAsync.when(
            data: (subs) => ActiveSubscriptionsSection(subscriptions: subs),
            loading: () => const ActiveSubscriptionsLoading(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _handleReconciliationSignal({
    required BuildContext context,
    required WidgetRef ref,
    required PaymentReconciliationSignal signal,
  }) {
    ref
      ..invalidate(debtHomeSnapshotProvider)
      ..invalidate(monthlyStatsProvider)
      ..invalidate(pendingPaymentsProvider)
      ..invalidate(activeSubscriptionsProvider);

    if (!context.mounted) {
      return;
    }

    AppOperationalSnackbar.show(
      context,
      message: paymentReconciliationMessage(signal.reason),
    );
  }
}

class _DebtPriorityLoading extends StatelessWidget {
  const _DebtPriorityLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _DebtPriorityPlaceholder(height: 142),
        SizedBox(height: 16),
        _DebtPriorityPlaceholder(height: 164),
      ],
    );
  }
}

class _DebtPriorityPlaceholder extends StatelessWidget {
  const _DebtPriorityPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      tone: AppSectionCardTone.raised,
      child: SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DebtPriorityError extends StatelessWidget {
  const _DebtPriorityError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      tone: AppSectionCardTone.critical,
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
