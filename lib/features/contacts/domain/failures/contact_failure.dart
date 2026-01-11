// lib/features/contacts/domain/failures/contact_failure.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_failure.freezed.dart';

/// Represents failures that can occur in contact operations
@freezed
class ContactFailure with _$ContactFailure {
  /// Server error (500 errors, database failures)
  const factory ContactFailure.serverError([String? message]) = _ServerError;

  /// Network error (no internet, timeout)
  const factory ContactFailure.networkError() = _NetworkError;

  /// Contact not found (invalid ID or deleted)
  const factory ContactFailure.contactNotFound() = _ContactNotFound;

  /// Duplicate contact (same email already exists for this user)
  const factory ContactFailure.duplicateContact() = _DuplicateContact;

  /// Cache error (local Hive cache failure)
  const factory ContactFailure.cacheError([String? message]) = _CacheError;

  /// Unauthorized (user not authenticated or not authorized for action)
  const factory ContactFailure.unauthorized() = _Unauthorized;

  /// Unexpected error (unknown errors)
  const factory ContactFailure.unexpected([String? message]) = _Unexpected;
}
