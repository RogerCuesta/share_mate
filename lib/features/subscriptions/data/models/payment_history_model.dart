import 'package:hive_ce/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/payment_history.dart';

part 'payment_history_model.g.dart';

/// Data model for PaymentHistory with Hive persistence
///
/// **Denormalization**: Fields 9-12 store denormalized data to preserve
/// audit trail even if members or subscriptions are deleted.
@HiveType(typeId: HiveTypeIds.paymentHistory)
class PaymentHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subscriptionId;

  @HiveField(2)
  final String memberId;

  @HiveField(9, defaultValue: 'Unknown Member')
  final String memberName;

  @HiveField(10, defaultValue: 'Unknown Subscription')
  final String subscriptionName;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime paymentDate;

  @HiveField(5)
  final String markedBy;

  @HiveField(6)
  final String action; // 'paid' or 'unpaid'

  @HiveField(7)
  final String? notes;

  @HiveField(11)
  final String? paymentMethod;

  @HiveField(12, defaultValue: null)
  final Map<String, dynamic>? metadata;

  @HiveField(8)
  final DateTime createdAt;

  PaymentHistoryModel({
    required this.id,
    required this.subscriptionId,
    required this.memberId,
    required this.memberName,
    required this.subscriptionName,
    required this.amount,
    required this.paymentDate,
    required this.markedBy,
    required this.action,
    this.notes,
    this.paymentMethod,
    this.metadata,
    required this.createdAt,
  });

  /// Convert to domain entity
  PaymentHistory toEntity() {
    return PaymentHistory(
      id: id,
      subscriptionId: subscriptionId,
      memberId: memberId,
      memberName: memberName,
      subscriptionName: subscriptionName,
      amount: amount,
      paymentDate: paymentDate,
      markedBy: markedBy,
      action: _parseAction(action),
      notes: notes,
      paymentMethod: paymentMethod,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory PaymentHistoryModel.fromEntity(PaymentHistory entity) {
    return PaymentHistoryModel(
      id: entity.id,
      subscriptionId: entity.subscriptionId,
      memberId: entity.memberId,
      memberName: entity.memberName,
      subscriptionName: entity.subscriptionName,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      markedBy: entity.markedBy,
      action: _actionToString(entity.action),
      notes: entity.notes,
      paymentMethod: entity.paymentMethod,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
    );
  }

  /// Create from Supabase JSON
  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String? ?? 'Unknown Member',
      subscriptionName: json['subscription_name'] as String? ?? 'Unknown Subscription',
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      markedBy: json['marked_by'] as String,
      action: json['action'] as String,
      notes: json['notes'] as String?,
      paymentMethod: json['payment_method'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'member_id': memberId,
      'member_name': memberName,
      'subscription_name': subscriptionName,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'marked_by': markedBy,
      'action': action,
      'notes': notes,
      'payment_method': paymentMethod,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods for enum conversion
  static PaymentAction _parseAction(String value) {
    return value == 'paid' ? PaymentAction.paid : PaymentAction.unpaid;
  }

  static String _actionToString(PaymentAction action) {
    return action == PaymentAction.paid ? 'paid' : 'unpaid';
  }
}
