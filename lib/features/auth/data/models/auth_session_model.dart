// lib/features/auth/data/models/auth_session_model.dart

import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';

/// Data model for AuthSession
///
/// This model is NOT persisted in Hive. It's stored in flutter_secure_storage
/// as JSON and exists only in memory during runtime.
///
/// The session token is stored securely and never exposed to logs or Hive.
class AuthSessionModel {

  AuthSessionModel({
    required this.userId,
    required this.token,
    required this.expiresAt,
    this.createdAt,
  });

  /// Convert domain entity to data model
  factory AuthSessionModel.fromEntity(AuthSession session) {
    return AuthSessionModel(
      userId: session.userId,
      token: session.token,
      expiresAt: session.expiresAt,
      createdAt: session.createdAt,
    );
  }

  /// Create from JSON (for secure storage)
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      userId: json['user_id'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
  final String userId;
  final String token;
  final DateTime expiresAt;
  final DateTime? createdAt;

  /// Convert data model to domain entity
  AuthSession toEntity() {
    return AuthSession(
      userId: userId,
      token: token,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }

  /// Convert to JSON (for secure storage)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Copy with method
  AuthSessionModel copyWith({
    String? userId,
    String? token,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return AuthSessionModel(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSessionModel &&
        other.userId == userId &&
        other.token == token &&
        other.expiresAt == expiresAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        token.hashCode ^
        expiresAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    // NEVER log the actual token in production
    return 'AuthSessionModel(userId: $userId, token: *****, expiresAt: $expiresAt, createdAt: $createdAt)';
  }
}
