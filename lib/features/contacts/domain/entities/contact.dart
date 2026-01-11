// lib/features/contacts/domain/entities/contact.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';

/// Contact entity representing a saved contact in the user's personal contact list
///
/// Contacts are private to each user (not bidirectional like friend relationships).
/// Users can simply save contact information without sending requests or waiting for acceptance.
@freezed
class Contact with _$Contact {
  const factory Contact({
    /// Unique identifier for the contact
    required String id,

    /// User ID who owns this contact
    required String userId,

    /// Contact's display name
    required String name,

    /// Contact's email address
    required String email,

    /// Timestamp when the contact was created
    required DateTime createdAt, /// Timestamp when the contact was last updated
    required DateTime updatedAt, /// Optional avatar URL for the contact
    String? avatar,

    /// Optional personal notes about the contact (e.g., "Brother", "Work colleague")
    String? notes,
  }) = _Contact;

  const Contact._();

  /// Get the first letter of the name for avatar fallback
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
