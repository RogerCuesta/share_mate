// lib/features/contacts/domain/usecases/update_contact.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/update_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/failures/contact_failure.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';

/// Use case for updating an existing contact
///
/// Updates the information of an existing contact.
class UpdateContact {

  const UpdateContact(this._repository);
  final ContactRepository _repository;

  /// Execute the use case
  ///
  /// [contactId] - ID of the contact to update
  /// [input] - Updated contact information (name, email, avatar, notes)
  ///
  /// Returns [Right(Contact)] with the updated contact on success
  /// Returns [Left(ContactFailure.contactNotFound)] if contact doesn't exist
  /// Returns [Left(ContactFailure)] on other errors
  Future<Either<ContactFailure, Contact>> call(
    String contactId,
    UpdateContactInput input,
  ) {
    return _repository.updateContact(contactId, input);
  }
}
