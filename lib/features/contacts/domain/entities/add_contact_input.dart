// lib/features/contacts/domain/entities/add_contact_input.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_contact_input.freezed.dart';

/// Input data transfer object for adding a new contact
@freezed
class AddContactInput with _$AddContactInput {
  const factory AddContactInput({
    /// Contact's display name (required, min 2 chars)
    required String name,

    /// Contact's email address (optional, must be valid format when provided)
    String? email,

    /// Optional avatar URL
    String? avatar,

    /// Optional color metadata for avatar placeholders
    String? color,

    /// Optional personal notes about the contact
    String? notes,
  }) = _AddContactInput;

  const AddContactInput._();

  /// Validate the input data
  String? validate() {
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    final normalizedEmailValue = normalizedEmail;
    if (normalizedEmailValue != null) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(normalizedEmailValue)) {
        return 'Please enter a valid email address';
      }
    }

    final normalizedColorValue = normalizedColor;
    if (normalizedColorValue != null) {
      final colorRegex = RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$');
      if (!colorRegex.hasMatch(normalizedColorValue)) {
        return 'Please enter a valid hex color';
      }
    }

    return null; // Valid
  }

  /// Normalize email to lowercase
  String? get normalizedEmail {
    final value = email?.trim();
    if (value == null || value.isEmpty) return null;
    return value.toLowerCase();
  }

  /// Normalize color to uppercase
  String? get normalizedColor {
    final value = color?.trim();
    if (value == null || value.isEmpty) return null;
    return value.toUpperCase();
  }

  /// Trim name
  String get normalizedName => name.trim();
}
