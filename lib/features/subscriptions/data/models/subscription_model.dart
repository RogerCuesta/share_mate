import 'package:hive_ce/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/subscription.dart';

part 'subscription_model.g.dart';

/// Data model for Subscription with Hive persistence
@HiveType(typeId: HiveTypeIds.subscription)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? iconUrl;

  @HiveField(3)
  final String color;

  @HiveField(4)
  final double totalCost;

  @HiveField(5)
  final String billingCycle; // 'monthly' or 'yearly'

  @HiveField(6)
  final DateTime dueDate;

  @HiveField(7)
  final String ownerId;

  @HiveField(8)
  final List<String> sharedWith;

  @HiveField(9)
  final String status; // 'active', 'cancelled', 'paused'

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11, defaultValue: null)
  final DateTime? updatedAt;

  SubscriptionModel({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.color,
    required this.totalCost,
    required this.billingCycle,
    required this.dueDate,
    required this.ownerId,
    required this.sharedWith,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert to domain entity
  Subscription toEntity() {
    return Subscription(
      id: id,
      name: name,
      iconUrl: iconUrl,
      color: color,
      totalCost: totalCost,
      billingCycle: _parseBillingCycle(billingCycle),
      dueDate: dueDate,
      ownerId: ownerId,
      sharedWith: sharedWith,
      status: _parseStatus(status),
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory SubscriptionModel.fromEntity(Subscription entity) {
    return SubscriptionModel(
      id: entity.id,
      name: entity.name,
      iconUrl: entity.iconUrl,
      color: entity.color,
      totalCost: entity.totalCost,
      billingCycle: _billingCycleToString(entity.billingCycle),
      dueDate: entity.dueDate,
      ownerId: entity.ownerId,
      sharedWith: entity.sharedWith,
      status: _statusToString(entity.status),
      createdAt: entity.createdAt,
      updatedAt: DateTime.now(), // Will be overwritten by Supabase trigger
    );
  }

  /// Create from Supabase JSON
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String,
      totalCost: (json['total_cost'] as num).toDouble(),
      billingCycle: json['billing_cycle'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      ownerId: json['owner_id'] as String,
      sharedWith: json['shared_with'] != null
          ? List<String>.from(json['shared_with'] as List)
          : [],
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON
  /// Note: shared_with is NOT sent to Supabase as it's derived from subscription_members table
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'color': color,
      'total_cost': totalCost,
      'billing_cycle': billingCycle,
      'due_date': dueDate.toIso8601String(),
      'owner_id': ownerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods for enum conversion
  static BillingCycle _parseBillingCycle(String value) {
    return value == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
  }

  static String _billingCycleToString(BillingCycle cycle) {
    return cycle == BillingCycle.yearly ? 'yearly' : 'monthly';
  }

  static SubscriptionStatus _parseStatus(String value) {
    switch (value) {
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'paused':
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.active;
    }
  }

  static String _statusToString(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.paused:
        return 'paused';
      case SubscriptionStatus.active:
        return 'active';
    }
  }
}
