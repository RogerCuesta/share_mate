// lib/features/contacts/domain/usecases/add_contact.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/failures/contact_failure.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';

/// Use case for adding a new contact
///
/// Creates a new contact for the current user with the provided information.
class AddContact {

  const AddContact(this._repository);
  final ContactRepository _repository;

  /// Execute the use case
  ///
  /// [userId] - ID of the user who owns the contact
  /// [input] - Contact information (name, email, avatar, notes)
  ///
  /// Returns [Right(Contact)] with the created contact on success
  /// Returns [Left(ContactFailure.duplicateContact)] if email already exists
  /// Returns [Left(ContactFailure)] on other errors
  Future<Either<ContactFailure, Contact>> call(
    String userId,
    AddContactInput input,
  ) {
    return _repository.addContact(userId, input);
  }
}
