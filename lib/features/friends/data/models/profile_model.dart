// lib/features/friends/data/models/profile_model.dart

import 'package:hive/hive.dart';

import '../../../../core/storage/hive_type_ids.dart';
import '../../domain/entities/profile.dart';

part 'profile_model.g.dart';

/// Data model for Profile with Hive persistence
@HiveType(typeId: HiveTypeIds.profile)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final bool isDiscoverable;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  ProfileModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.isDiscoverable,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to domain entity
  Profile toEntity() {
    return Profile(
      userId: userId,
      fullName: fullName,
      email: email,
      avatarUrl: avatarUrl,
      isDiscoverable: isDiscoverable,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory ProfileModel.fromEntity(Profile entity) {
    return ProfileModel(
      userId: entity.userId,
      fullName: entity.fullName,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
      isDiscoverable: entity.isDiscoverable,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create from Supabase JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isDiscoverable: json['is_discoverable'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'is_discoverable': isDiscoverable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
