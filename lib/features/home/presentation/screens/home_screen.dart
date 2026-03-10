import 'package:flutter/material.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Header
            const SliverToBoxAdapter(
              child: HomeHeader(),
            ),

            // 2. Debt-priority section (primary)
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

            // 3. Stats cards (secondary context)
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

            // 4. Action-required section (secondary context)
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

            // 5. Active subscriptions grid
            SliverToBoxAdapter(
              child: subscriptionsAsync.when(
                data: (subs) => ActiveSubscriptionsSection(
                  subscriptions: subs,
                ),
                loading: () => const ActiveSubscriptionsLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Bottom padding (accounts for BottomAppBar + FAB + SafeArea)
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
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
      ..invalidate(debtHomeSnapshotProvider)
      ..invalidate(monthlyStatsProvider)
      ..invalidate(pendingPaymentsProvider)
      ..invalidate(activeSubscriptionsProvider);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E2D),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF4FC3F7),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  paymentReconciliationMessage(signal.reason),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white70,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF5350).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
