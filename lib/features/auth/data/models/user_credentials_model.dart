// lib/features/auth/data/models/user_credentials_model.dart

import 'package:flutter_project_agents/core/storage/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'user_credentials_model.g.dart';

/// Data model for storing user credentials securely
///
/// This model stores the hashed password and associated user ID.
/// The password is NEVER stored in plain text.
///
/// TypeId: 12 (defined in HiveTypeIds.authToken)
/// Note: Using authToken typeId since this is auth-related credentials storage
@HiveType(typeId: HiveTypeIds.authToken)
class UserCredentialsModel extends HiveObject {

  UserCredentialsModel({
    required this.userId,
    required this.email,
    required this.hashedPassword,
    required this.createdAt,
  });

  /// Create from JSON
  factory UserCredentialsModel.fromJson(Map<String, dynamic> json) {
    return UserCredentialsModel(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      hashedPassword: json['hashed_password'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String hashedPassword;

  @HiveField(3)
  final DateTime createdAt;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'hashed_password': hashedPassword,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with method
  UserCredentialsModel copyWith({
    String? userId,
    String? email,
    String? hashedPassword,
    DateTime? createdAt,
  }) {
    return UserCredentialsModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCredentialsModel &&
        other.userId == userId &&
        other.email == email &&
        other.hashedPassword == hashedPassword &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        email.hashCode ^
        hashedPassword.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'UserCredentialsModel(userId: $userId, email: $email, hashedPassword: *****, createdAt: $createdAt)';
  }
}
