// lib/features/friends/data/models/friend_model.dart

import 'package:hive/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/friend.dart';

part 'friend_model.g.dart';

/// Data model for Friend with Hive persistence
///
/// Denormalized model combining friendship + profile data for display.
@HiveType(typeId: HiveTypeIds.friend)
class FriendModel extends HiveObject {
  @HiveField(0)
  final String friendshipId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String? avatarUrl;

  @HiveField(5)
  final DateTime friendsSince;

  FriendModel({
    required this.friendshipId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.friendsSince,
  });

  /// Convert to domain entity
  Friend toEntity() {
    return Friend(
      friendshipId: friendshipId,
      userId: userId,
      fullName: fullName,
      email: email,
      avatarUrl: avatarUrl,
      friendsSince: friendsSince,
    );
  }

  /// Create from domain entity
  factory FriendModel.fromEntity(Friend entity) {
    return FriendModel(
      friendshipId: entity.friendshipId,
      userId: entity.userId,
      fullName: entity.fullName,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
      friendsSince: entity.friendsSince,
    );
  }

  /// Create from RPC function result (denormalized)
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      friendshipId: json['friendship_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      friendsSince: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'friendship_id': friendshipId,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'created_at': friendsSince.toIso8601String(),
    };
  }
}
