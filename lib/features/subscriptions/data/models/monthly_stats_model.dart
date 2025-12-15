import '../../domain/entities/monthly_stats.dart';

/// Data model for MonthlyStats
///
/// This model does NOT use Hive as stats are calculated in real-time
/// from subscriptions and members data.
class MonthlyStatsModel {
  final double totalMonthlyCost;
  final double pendingToCollect;
  final int activeSubscriptionsCount;
  final int overduePaymentsCount;
  final double collectedAmount;
  final int paidMembersCount;
  final int unpaidMembersCount;

  MonthlyStatsModel({
    required this.totalMonthlyCost,
    required this.pendingToCollect,
    required this.activeSubscriptionsCount,
    required this.overduePaymentsCount,
    required this.collectedAmount,
    required this.paidMembersCount,
    required this.unpaidMembersCount,
  });

  /// Convert to domain entity
  MonthlyStats toEntity() {
    return MonthlyStats(
      totalMonthlyCost: totalMonthlyCost,
      pendingToCollect: pendingToCollect,
      activeSubscriptionsCount: activeSubscriptionsCount,
      overduePaymentsCount: overduePaymentsCount,
      collectedAmount: collectedAmount,
      paidMembersCount: paidMembersCount,
      unpaidMembersCount: unpaidMembersCount,
    );
  }

  /// Create from domain entity
  factory MonthlyStatsModel.fromEntity(MonthlyStats entity) {
    return MonthlyStatsModel(
      totalMonthlyCost: entity.totalMonthlyCost,
      pendingToCollect: entity.pendingToCollect,
      activeSubscriptionsCount: entity.activeSubscriptionsCount,
      overduePaymentsCount: entity.overduePaymentsCount,
      collectedAmount: entity.collectedAmount,
      paidMembersCount: entity.paidMembersCount,
      unpaidMembersCount: entity.unpaidMembersCount,
    );
  }

  /// Create from JSON (if needed for API response)
  factory MonthlyStatsModel.fromJson(Map<String, dynamic> json) {
    return MonthlyStatsModel(
      totalMonthlyCost: (json['total_monthly_cost'] as num).toDouble(),
      pendingToCollect: (json['pending_to_collect'] as num).toDouble(),
      activeSubscriptionsCount: json['active_subscriptions_count'] as int,
      overduePaymentsCount: json['overdue_payments_count'] as int,
      collectedAmount: (json['collected_amount'] as num?)?.toDouble() ?? 0.0,
      paidMembersCount: json['paid_members_count'] as int? ?? 0,
      unpaidMembersCount: json['unpaid_members_count'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_monthly_cost': totalMonthlyCost,
      'pending_to_collect': pendingToCollect,
      'active_subscriptions_count': activeSubscriptionsCount,
      'overdue_payments_count': overduePaymentsCount,
      'collected_amount': collectedAmount,
      'paid_members_count': paidMembersCount,
      'unpaid_members_count': unpaidMembersCount,
    };
  }
}
