// lib/features/auth/data/models/user_model.dart

import 'package:flutter_project_agents/core/storage/hive_type_ids.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:hive_ce/hive.dart';

part 'user_model.g.dart';

/// Data model for User with Hive persistence
///
/// This model extends the domain User entity with serialization capabilities.
/// It uses Hive TypeAdapter for local storage.
///
/// TypeId: 10 (defined in HiveTypeIds.user)
@HiveType(typeId: HiveTypeIds.user)
class UserModel extends HiveObject {

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.supabaseId,
  });

  /// Convert domain entity to data model
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      createdAt: user.createdAt,
      supabaseId: user.supabaseId,
    );
  }

  /// Create from JSON (for future API integration)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      supabaseId: json['supabase_id'] as String?,
    );
  }
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? supabaseId;

  /// Convert data model to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      createdAt: createdAt,
      supabaseId: supabaseId,
    );
  }

  /// Convert to JSON (for future API integration)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'supabase_id': supabaseId,
    };
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? createdAt,
    String? supabaseId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.fullName == fullName &&
        other.createdAt == createdAt &&
        other.supabaseId == supabaseId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        fullName.hashCode ^
        createdAt.hashCode ^
        supabaseId.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, createdAt: $createdAt, supabaseId: $supabaseId)';
  }
}
