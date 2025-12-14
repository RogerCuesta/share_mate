// lib/features/auth/domain/entities/auth_session.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

/// Domain entity representing an authentication session
///
/// Contains session information including the user ID, authentication token,
/// and expiration date. This entity is NOT persisted in Hive, only in
/// flutter_secure_storage.
@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String userId,
    required String token,
    required DateTime expiresAt,
    DateTime? createdAt,
  }) = _AuthSession;

  const AuthSession._();

  /// Business logic: Check if session is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Business logic: Check if session is valid (not expired)
  bool get isValid {
    return !isExpired && userId.isNotEmpty && token.isNotEmpty;
  }

  /// Business logic: Check if session is about to expire (within 24 hours)
  bool get isExpiringsSoon {
    final threshold = DateTime.now().add(const Duration(hours: 24));
    return expiresAt.isBefore(threshold) && !isExpired;
  }

  /// Business logic: Get remaining time until expiration
  Duration get timeUntilExpiration {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Business logic: Get days until expiration
  int get daysUntilExpiration {
    return timeUntilExpiration.inDays;
  }
}
