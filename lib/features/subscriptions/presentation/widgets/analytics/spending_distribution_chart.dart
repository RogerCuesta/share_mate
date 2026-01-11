// lib/features/subscriptions/presentation/widgets/analytics/spending_distribution_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_spending.dart';

/// Spending Distribution Pie Chart Widget
///
/// Displays a donut chart showing spending distribution by subscription
/// with interactive touch, legend, and percentage labels.
///
/// Features:
/// - Donut chart with subscription colors
/// - Touch interaction to highlight sections
/// - Center hole showing total amount
/// - Legend with color dots, names, amounts, and percentages
/// - Groups excess subscriptions into "Others"
/// - Loading and empty states
class SpendingDistributionChart extends StatefulWidget {

  const SpendingDistributionChart({
    required this.data, super.key,
    this.isLoading = false,
  });
  final List<SubscriptionSpending> data;
  final bool isLoading;

  @override
  State<SpendingDistributionChart> createState() =>
      _SpendingDistributionChartState();
}

class _SpendingDistributionChartState extends State<SpendingDistributionChart> {
  int touchedIndex = -1;
  static const int maxSections = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Spending Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Chart or State
          if (widget.isLoading)
            const _LoadingState()
          else if (widget.data.isEmpty)
            const _EmptyState()
          else
            _buildChartWithLegend(),
        ],
      ),
    );
  }

  Widget _buildChartWithLegend() {
    final processedData = _processData(widget.data);
    final totalAmount = _calculateTotal(processedData);

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _buildSections(processedData, totalAmount),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Legend
        _buildLegend(processedData, totalAmount),
      ],
    );
  }

  /// Process data: Sort by amount, group extras into "Others"
  List<SubscriptionSpending> _processData(List<SubscriptionSpending> data) {
    // Sort by amount descending
    final sorted = List<SubscriptionSpending>.from(data)
      ..sort((a, b) => b.totalAmountPaid.compareTo(a.totalAmountPaid));

    // If more than maxSections, group the rest into "Others"
    if (sorted.length <= maxSections) {
      return sorted;
    }

    final top = sorted.take(maxSections - 1).toList();
    final others = sorted.skip(maxSections - 1).toList();

    // Calculate "Others" total
    final othersTotal = others.fold<double>(
      0,
      (sum, item) => sum + item.totalAmountPaid,
    );

    // Create "Others" entry
    final othersEntry = SubscriptionSpending(
      subscriptionId: 'others',
      subscriptionName: 'Others',
      totalAmountPaid: othersTotal,
      paymentCount: others.fold<int>(0, (sum, item) => sum + item.paymentCount),
      color: '#757575', // Grey color for "Others"
    );

    return [...top, othersEntry];
  }

  double _calculateTotal(List<SubscriptionSpending> data) {
    return data.fold<double>(0, (sum, item) => sum + item.totalAmountPaid);
  }

  List<PieChartSectionData> _buildSections(
    List<SubscriptionSpending> data,
    double total,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == touchedIndex;
      final percentage = (item.totalAmountPaid / total) * 100;

      final radius = isTouched ? 70.0 : 60.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      return PieChartSectionData(
        color: _parseColor(item.color),
        value: item.totalAmountPaid,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black45,
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.subscriptionName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildLegend(List<SubscriptionSpending> data, double total) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = (item.totalAmountPaid / total) * 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Color dot
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _parseColor(item.color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == touchedIndex
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Subscription name
                  Expanded(
                    child: Text(
                      item.subscriptionName,
                      style: TextStyle(
                        color: index == touchedIndex
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: index == touchedIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Amount
                  Text(
                    '\$${item.totalAmountPaid.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: index == touchedIndex
                          ? const Color(0xFF6C63FF)
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Percentage
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: index == touchedIndex
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: index == touchedIndex
                            ? const Color(0xFF6C63FF)
                            : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF6C63FF); // Default purple
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CENTER LABEL WIDGET (Total Amount in Center)
// ═══════════════════════════════════════════════════════════════════════════

/// Custom center label for donut chart

// ═══════════════════════════════════════════════════════════════════════════
// LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading distribution...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No spending data',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mark payments to see distribution',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
