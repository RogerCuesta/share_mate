// lib/features/contacts/domain/usecases/delete_contact.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/contacts/domain/failures/contact_failure.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';

/// Use case for deleting a contact
///
/// Permanently removes a contact from the user's contact list.
class DeleteContact {

  const DeleteContact(this._repository);
  final ContactRepository _repository;

  /// Execute the use case
  ///
  /// [contactId] - ID of the contact to delete
  ///
  /// Returns [Right(Unit)] on success
  /// Returns [Left(ContactFailure.contactNotFound)] if contact doesn't exist
  /// Returns [Left(ContactFailure)] on other errors
  Future<Either<ContactFailure, Unit>> call(String contactId) {
    return _repository.deleteContact(contactId);
  }
}
