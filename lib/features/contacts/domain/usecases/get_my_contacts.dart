// lib/features/contacts/domain/usecases/get_my_contacts.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/failures/contact_failure.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';

/// Use case for fetching the current user's contacts
///
/// Retrieves all contacts owned by the specified user.
/// Supports offline-first functionality through repository caching.
class GetMyContacts {

  const GetMyContacts(this._repository);
  final ContactRepository _repository;

  /// Execute the use case
  ///
  /// [userId] - ID of the user whose contacts to fetch
  ///
  /// Returns [Right(List<Contact>)] on success
  /// Returns [Left(ContactFailure)] on error
  Future<Either<ContactFailure, List<Contact>>> call(String userId) async {
    return _repository.getMyContacts(userId);
  }
}
