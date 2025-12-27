// lib/features/friends/data/models/friendship_model.dart

import 'package:hive/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/friendship.dart';

part 'friendship_model.g.dart';

/// Data model for Friendship with Hive persistence
@HiveType(typeId: HiveTypeIds.friendship)
class FriendshipModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String friendId;

  @HiveField(3)
  final String status; // 'pending', 'accepted', 'rejected', 'removed'

  @HiveField(4)
  final String initiatorId;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.initiatorId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to domain entity
  Friendship toEntity() {
    return Friendship(
      id: id,
      userId: userId,
      friendId: friendId,
      status: _parseStatus(status),
      initiatorId: initiatorId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory FriendshipModel.fromEntity(Friendship entity) {
    return FriendshipModel(
      id: entity.id,
      userId: entity.userId,
      friendId: entity.friendId,
      status: _statusToString(entity.status),
      initiatorId: entity.initiatorId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create from Supabase JSON
  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: json['status'] as String,
      initiatorId: json['initiator_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status,
      'initiator_id': initiatorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for enum conversion
  static FriendshipStatus _parseStatus(String value) {
    switch (value) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'rejected':
        return FriendshipStatus.rejected;
      case 'removed':
        return FriendshipStatus.removed;
      default:
        return FriendshipStatus.pending;
    }
  }

  static String _statusToString(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.pending:
        return 'pending';
      case FriendshipStatus.accepted:
        return 'accepted';
      case FriendshipStatus.rejected:
        return 'rejected';
      case FriendshipStatus.removed:
        return 'removed';
    }
  }
}
