// lib/features/contacts/data/repositories/contact_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:flutter_project_agents/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/update_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/failures/contact_failure.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementation of ContactRepository with offline-first support
///
/// Strategy: Try remote first, fallback to cache on network errors
class ContactRepositoryImpl implements ContactRepository {

  const ContactRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );
  final ContactRemoteDataSource _remoteDataSource;
  final ContactLocalDataSource _localDataSource;

  @override
  Future<Either<ContactFailure, List<Contact>>> getMyContacts(
    String userId,
  ) async {
    try {
      // Try remote first
      final contactModels = await _remoteDataSource.getMyContacts(userId);
      final contacts = contactModels.map((model) => model.toEntity()).toList();

      // Cache the result
      await _localDataSource.cacheContacts(userId, contactModels);

      return Right(contacts);
    } on PostgrestException catch (e) {
      // Database error - try cache
      if (e.code == 'PGRST301' || e.code == '401') {
        return const Left(ContactFailure.unauthorized());
      }

      // Try loading from cache
      final cachedModels = await _localDataSource.getCachedContacts(userId);
      if (cachedModels.isNotEmpty) {
        return Right(cachedModels.map((m) => m.toEntity()).toList());
      }

      return Left(ContactFailure.serverError(e.message));
    } catch (e) {
      // Network error or other error - try cache
      final cachedModels = await _localDataSource.getCachedContacts(userId);
      if (cachedModels.isNotEmpty) {
        return Right(cachedModels.map((m) => m.toEntity()).toList());
      }

      if (e.toString().contains('Network')) {
        return const Left(ContactFailure.networkError());
      }

      return Left(ContactFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<ContactFailure, Contact>> addContact(
    String userId,
    AddContactInput input,
  ) async {
    try {
      final contactModel = await _remoteDataSource.addContact(userId, input);
      final contact = contactModel.toEntity();

      // Cache the new contact
      await _localDataSource.cacheContact(contactModel);

      // Invalidate contacts list cache
      await _localDataSource.clearContactsCache(userId);

      return Right(contact);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Left(ContactFailure.duplicateContact());
      }
      if (e.code == 'PGRST301' || e.code == '401') {
        return const Left(ContactFailure.unauthorized());
      }
      return Left(ContactFailure.serverError(e.message));
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        return const Left(ContactFailure.duplicateContact());
      }
      if (e.toString().contains('Network')) {
        return const Left(ContactFailure.networkError());
      }
      return Left(ContactFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<ContactFailure, Contact>> updateContact(
    String contactId,
    UpdateContactInput input,
  ) async {
    try {
      final contactModel = await _remoteDataSource.updateContact(
        contactId,
        input,
      );
      final contact = contactModel.toEntity();

      // Update cached contact
      await _localDataSource.cacheContact(contactModel);

      // Invalidate contacts list cache
      await _localDataSource.clearContactsCache(contact.userId);

      return Right(contact);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Left(ContactFailure.duplicateContact());
      }
      if (e.code == 'PGRST116') {
        return const Left(ContactFailure.contactNotFound());
      }
      if (e.code == 'PGRST301' || e.code == '401') {
        return const Left(ContactFailure.unauthorized());
      }
      return Left(ContactFailure.serverError(e.message));
    } catch (e) {
      if (e.toString().contains('not found')) {
        return const Left(ContactFailure.contactNotFound());
      }
      if (e.toString().contains('duplicate')) {
        return const Left(ContactFailure.duplicateContact());
      }
      if (e.toString().contains('Network')) {
        return const Left(ContactFailure.networkError());
      }
      return Left(ContactFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<ContactFailure, Unit>> deleteContact(String contactId) async {
    try {
      // Get contact first to know the userId for cache invalidation
      final cachedContact = await _localDataSource.getContact(contactId);

      await _remoteDataSource.deleteContact(contactId);

      // Remove from cache
      await _localDataSource.removeContact(contactId);

      // Invalidate contacts list cache
      if (cachedContact != null) {
        await _localDataSource.clearContactsCache(cachedContact.userId);
      }

      return const Right(unit);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const Left(ContactFailure.contactNotFound());
      }
      if (e.code == 'PGRST301' || e.code == '401') {
        return const Left(ContactFailure.unauthorized());
      }
      return Left(ContactFailure.serverError(e.message));
    } catch (e) {
      if (e.toString().contains('not found')) {
        return const Left(ContactFailure.contactNotFound());
      }
      if (e.toString().contains('Network')) {
        return const Left(ContactFailure.networkError());
      }
      return Left(ContactFailure.unexpected(e.toString()));
    }
  }
}
