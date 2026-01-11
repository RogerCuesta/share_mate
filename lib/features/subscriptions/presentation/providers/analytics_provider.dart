// lib/features/subscriptions/presentation/providers/analytics_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/analytics_data.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/time_range.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_provider.g.dart';

/// Provider for the selected time range filter
@riverpod
class SelectedTimeRange extends _$SelectedTimeRange {
  @override
  TimeRange build() {
    return TimeRange.last6Months; // Default time range
  }

  /// Update the selected time range
  void setRange(TimeRange range) {
    state = range;
  }
}

/// Provider for analytics data
///
/// Automatically refetches when:
/// - User authentication changes
/// - Time range filter changes
@riverpod
Future<AnalyticsData> analyticsData(AnalyticsDataRef ref) async {
  // Watch auth state - refetch when user changes
  final authState = ref.watch(authProvider);

  // Watch selected time range - refetch when filter changes
  final timeRange = ref.watch(selectedTimeRangeProvider);

  // Get analytics based on auth state
  return authState.maybeWhen(
    authenticated: (user) async {
      // Get use case from DI
      final useCase = ref.watch(getAnalyticsDataProvider);

      // Fetch analytics data
      final result = await useCase(
        userId: user.id,
        timeRange: timeRange,
      );

      // Handle result
      return result.fold(
        (failure) => throw failure,
        (analytics) => analytics,
      );
    },
    orElse: () => throw Exception('User not authenticated'),
  );
}
