import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../widgets/action_required_section.dart';
import '../widgets/active_subscriptions_section.dart';
import '../widgets/home_header.dart';
import '../widgets/stats_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final subscriptionsAsync = ref.watch(activeSubscriptionsProvider);
    final pendingAsync = ref.watch(pendingPaymentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Header
            const SliverToBoxAdapter(
              child: HomeHeader(),
            ),

            // 2. Stats Cards (Monthly Cost + Pending)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                child: monthlyStatsAsync.when(
                  data: (stats) => StatsCards(stats: stats),
                  loading: () => const StatsCardsLoading(),
                  error: (error, _) => StatsCardsError(error: error),
                ),
              ),
            ),

            // 3. Action Required Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: pendingAsync.when(
                  data: (pending) => ActionRequiredSection(
                    pendingPayments: pending.take(2).toList(),
                  ),
                  loading: () => const ActionRequiredLoading(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // 4. Active Subscriptions Grid
            SliverToBoxAdapter(
              child: subscriptionsAsync.when(
                data: (subs) => ActiveSubscriptionsSection(
                  subscriptions: subs,
                ),
                loading: () => const ActiveSubscriptionsLoading(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
