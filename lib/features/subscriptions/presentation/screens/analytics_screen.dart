// lib/features/subscriptions/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/time_range.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics/overview_cards_section.dart';

/// Analytics Dashboard Screen
///
/// Displays comprehensive analytics including:
/// - Overview cards (monthly cost, active subscriptions, members, avg cost)
/// - Time range filter
/// - Spending trends chart
/// - Subscription spending chart
/// - Payment distribution pie chart
/// - Payment analytics stats
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final selectedTimeRange = ref.watch(selectedTimeRangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Invalidate provider to trigger refetch
            ref.invalidate(analyticsDataProvider);
          },
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF2D2D44),
          child: analyticsAsync.when(
            data: (analytics) => _buildAnalyticsContent(
              context,
              ref,
              analytics,
              selectedTimeRange,
            ),
            loading: () => const _AnalyticsLoadingState(),
            error: (error, stackTrace) => _AnalyticsErrorState(
              error: error,
              onRetry: () {
                ref.invalidate(analyticsDataProvider);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    WidgetRef ref,
    AnalyticsData analytics,
    TimeRange selectedTimeRange,
  ) {
    return CustomScrollView(
      slivers: [
        // Header
        const SliverToBoxAdapter(
          child: _AnalyticsHeader(),
        ),

        // Time Range Filter
        SliverToBoxAdapter(
          child: _TimeRangeFilter(
            selectedTimeRange: selectedTimeRange,
            onTimeRangeChanged: (range) {
              ref.read(selectedTimeRangeProvider.notifier).setRange(range);
            },
          ),
        ),

        // Overview Cards Section
        SliverToBoxAdapter(
          child: OverviewCardsSection(
            overview: analytics.overview,
          ),
        ),

        // TODO: Spending Trends Chart
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // TODO: Subscription Spending Chart
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // TODO: Payment Distribution Chart
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // TODO: Payment Analytics Section
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // Bottom padding for navigation bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your spending and payment trends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIME RANGE FILTER
// ═══════════════════════════════════════════════════════════════════════════

class _TimeRangeFilter extends StatelessWidget {
  final TimeRange selectedTimeRange;
  final ValueChanged<TimeRange> onTimeRangeChanged;

  const _TimeRangeFilter({
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: TimeRange.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final range = TimeRange.values[index];
          final isSelected = range == selectedTimeRange;

          return _TimeRangeChip(
            label: range.displayName,
            isSelected: isSelected,
            onTap: () => onTimeRangeChanged(range),
          );
        },
      ),
    );
  }
}

class _TimeRangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeRangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF)
              : const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// OVERVIEW CARDS SECTION (PLACEHOLDER)
// ═══════════════════════════════════════════════════════════════════════════

class _OverviewCardsSection extends StatelessWidget {
  final dynamic overview; // TODO: Replace with AnalyticsOverview type

  const _OverviewCardsSection({
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Overview Cards (TODO)',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

class _AnalyticsLoadingState extends StatelessWidget {
  const _AnalyticsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR STATE
// ═══════════════════════════════════════════════════════════════════════════

class _AnalyticsErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _AnalyticsErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF6B6B),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
