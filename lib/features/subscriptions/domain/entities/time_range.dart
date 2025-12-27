// lib/features/subscriptions/domain/entities/time_range.dart

/// Time range options for filtering analytics data
enum TimeRange {
  last30Days,
  last3Months,
  last6Months,
  lastYear,
  allTime;

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case TimeRange.last30Days:
        return 'Last 30 Days';
      case TimeRange.last3Months:
        return 'Last 3 Months';
      case TimeRange.last6Months:
        return 'Last 6 Months';
      case TimeRange.lastYear:
        return 'Last Year';
      case TimeRange.allTime:
        return 'All Time';
    }
  }

  /// Get start date for filtering
  /// Returns null for allTime (no filter)
  DateTime? getStartDate() {
    final now = DateTime.now();
    switch (this) {
      case TimeRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case TimeRange.last3Months:
        return DateTime(now.year, now.month - 3, now.day);
      case TimeRange.last6Months:
        return DateTime(now.year, now.month - 6, now.day);
      case TimeRange.lastYear:
        return DateTime(now.year - 1, now.month, now.day);
      case TimeRange.allTime:
        return null; // No filter
    }
  }

  /// Get number of months to display in trends chart
  int get monthsToShow {
    switch (this) {
      case TimeRange.last30Days:
        return 2;
      case TimeRange.last3Months:
        return 3;
      case TimeRange.last6Months:
        return 6;
      case TimeRange.lastYear:
        return 12;
      case TimeRange.allTime:
        return 12; // Default to last 12 months
    }
  }
}
