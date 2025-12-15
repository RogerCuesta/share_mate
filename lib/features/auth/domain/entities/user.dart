// lib/features/auth/domain/entities/user.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// Domain entity representing a user in the system
///
/// This is the core domain model for user data.
/// It contains only business logic and no implementation details.
///
/// ID Strategy:
/// - `id`: Local identifier used for Hive storage (can be same as supabaseId or generated)
/// - `supabaseId`: Supabase Auth UUID (null for local-only users, set when synced with Supabase)
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String fullName,
    required DateTime createdAt,

    /// Supabase Auth user ID (UUID)
    ///
    /// null: User exists only locally (offline registration, not synced yet)
    /// non-null: User is synced with Supabase backend
    String? supabaseId,
  }) = _User;

  const User._();

  /// Check if user is synced with Supabase backend
  ///
  /// Returns true if user has a Supabase ID (registered/synced with backend)
  /// Returns false if user exists only locally (offline registration)
  bool get isSyncedWithSupabase => supabaseId != null;

  /// Check if user is local-only (not synced with Supabase)
  ///
  /// Returns true if user was created offline and hasn't been synced yet
  bool get isLocalOnly => supabaseId == null;

  /// Business logic: Check if user email is verified
  /// (placeholder for future implementation)
  bool get isEmailVerified => true; // TODO: Add email verification

  /// Business logic: Get user initials for avatar
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '';

    final names = trimmed.split(' ').where((name) => name.isNotEmpty).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0].substring(0, 1)}${names[names.length - 1].substring(0, 1)}'.toUpperCase();
  }

  /// Business logic: Validate user data
  bool get isValid {
    return id.isNotEmpty &&
           email.isNotEmpty &&
           fullName.isNotEmpty &&
           _isValidEmail(email);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
