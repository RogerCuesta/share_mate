import 'package:hive/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/subscription_member.dart';

part 'subscription_member_model.g.dart';

/// Data model for SubscriptionMember with Hive persistence
@HiveType(typeId: HiveTypeIds.subscriptionMember)
class SubscriptionMemberModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subscriptionId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String userName;

  @HiveField(4)
  final String userEmail;

  @HiveField(5)
  final String? userAvatar;

  @HiveField(6)
  final double amountToPay;

  @HiveField(7)
  final bool hasPaid;

  @HiveField(8)
  final DateTime? lastPaymentDate;

  @HiveField(9)
  final DateTime dueDate;

  @HiveField(10)
  final DateTime createdAt;

  SubscriptionMemberModel({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.amountToPay,
    required this.hasPaid,
    this.lastPaymentDate,
    required this.dueDate,
    required this.createdAt,
  });

  /// Convert to domain entity
  SubscriptionMember toEntity() {
    return SubscriptionMember(
      id: id,
      subscriptionId: subscriptionId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userAvatar: userAvatar,
      amountToPay: amountToPay,
      hasPaid: hasPaid,
      lastPaymentDate: lastPaymentDate,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory SubscriptionMemberModel.fromEntity(SubscriptionMember entity) {
    return SubscriptionMemberModel(
      id: entity.id,
      subscriptionId: entity.subscriptionId,
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      userAvatar: entity.userAvatar,
      amountToPay: entity.amountToPay,
      hasPaid: entity.hasPaid,
      lastPaymentDate: entity.lastPaymentDate,
      dueDate: entity.dueDate,
      createdAt: entity.createdAt,
    );
  }

  /// Create from Supabase JSON
  factory SubscriptionMemberModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionMemberModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      userAvatar: json['user_avatar'] as String?,
      amountToPay: (json['amount_to_pay'] as num).toDouble(),
      hasPaid: json['has_paid'] as bool? ?? false,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'] as String)
          : null,
      dueDate: DateTime.parse(json['due_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_avatar': userAvatar,
      'amount_to_pay': amountToPay,
      'has_paid': hasPaid,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
