// lib/features/contacts/domain/entities/update_contact_input.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_contact_input.freezed.dart';

/// Input data transfer object for updating an existing contact
@freezed
class UpdateContactInput with _$UpdateContactInput {
  const factory UpdateContactInput({
    /// Contact's display name (required, min 2 chars)
    required String name,

    /// Contact's email address (required, must be valid format)
    required String email,

    /// Optional avatar URL
    String? avatar,

    /// Optional personal notes about the contact
    String? notes,
  }) = _UpdateContactInput;

  const UpdateContactInput._();

  /// Validate the input data
  String? validate() {
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Normalize email to lowercase
  String get normalizedEmail => email.trim().toLowerCase();

  /// Trim name
  String get normalizedName => name.trim();
}
