// lib/features/settings/data/models/user_profile_model.dart

import 'package:hive/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/user_profile.dart';

part 'user_profile_model.g.dart';

/// User Profile Model for Hive persistence
///
/// Maps between UserProfile entity and Hive storage.
@HiveType(typeId: HiveTypeIds.userProfile) // typeId: 11
class UserProfileModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final String? bio;

  @HiveField(5)
  final bool isDiscoverable;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  UserProfileModel({
    required this.userId,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.isDiscoverable = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create model from domain entity
  factory UserProfileModel.fromEntity(UserProfile entity) => UserProfileModel(
        userId: entity.userId,
        email: entity.email,
        fullName: entity.fullName,
        avatarUrl: entity.avatarUrl,
        bio: entity.bio,
        isDiscoverable: entity.isDiscoverable,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  /// Convert model to domain entity
  UserProfile toEntity() => UserProfile(
        userId: userId,
        email: email,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
        isDiscoverable: isDiscoverable,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create model from JSON (Supabase response)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        userId: json['user_id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        isDiscoverable: json['is_discoverable'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  /// Convert model to JSON (for Supabase update)
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'is_discoverable': isDiscoverable,
      };
}
