// lib/features/contacts/domain/repositories/contact_repository.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/update_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/failures/contact_failure.dart';

/// Repository contract for contact operations
///
/// Defines the interface for managing user contacts with offline-first support.
/// Implementations should handle both remote (Supabase) and local (Hive) data sources.
abstract class ContactRepository {
  /// Get all contacts for the current user
  ///
  /// Returns [Right(List<Contact>)] on success
  /// Returns [Left(ContactFailure)] on error
  ///
  /// Offline-first: Tries remote first, falls back to cache on network error
  Future<Either<ContactFailure, List<Contact>>> getMyContacts(String userId);

  /// Add a new contact
  ///
  /// Returns [Right(Contact)] with the created contact on success
  /// Returns [Left(ContactFailure.duplicateContact)] if email already exists
  /// Returns [Left(ContactFailure)] on other errors
  ///
  /// Invalidates cache on success
  Future<Either<ContactFailure, Contact>> addContact(
    String userId,
    AddContactInput input,
  );

  /// Update an existing contact
  ///
  /// Returns [Right(Contact)] with the updated contact on success
  /// Returns [Left(ContactFailure.contactNotFound)] if contact doesn't exist
  /// Returns [Left(ContactFailure)] on other errors
  ///
  /// Invalidates cache on success
  Future<Either<ContactFailure, Contact>> updateContact(
    String contactId,
    UpdateContactInput input,
  );

  /// Delete a contact
  ///
  /// Returns [Right(Unit)] on success
  /// Returns [Left(ContactFailure.contactNotFound)] if contact doesn't exist
  /// Returns [Left(ContactFailure)] on other errors
  ///
  /// Invalidates cache on success
  Future<Either<ContactFailure, Unit>> deleteContact(String contactId);
}
