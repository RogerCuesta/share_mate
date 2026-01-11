// lib/features/contacts/data/datasources/contact_local_datasource.dart

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/features/contacts/data/models/contact_model.dart';

/// Local datasource for contact operations using Hive
///
/// Provides offline-first caching with encrypted storage
class ContactLocalDataSource {

  const ContactLocalDataSource();
  // Box names
  static const String _contactsBoxName = 'contacts';
  static const String _myContactsCacheBoxName = 'my_contacts_cache';

  /// Get cached contacts list for a user
  ///
  /// Returns empty list if cache is empty or error occurs
  Future<List<ContactModel>> getCachedContacts(String userId) async {
    try {
      final box = await HiveService.openBox<List>(
        _myContactsCacheBoxName,
        encrypted: true,
      );

      final cachedContacts = box.get(userId);
      if (cachedContacts == null) {
        return [];
      }

      return cachedContacts
          .map((item) => item as ContactModel)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Cache contacts list for a user
  ///
  /// Overwrites existing cache
  Future<void> cacheContacts(String userId, List<ContactModel> contacts) async {
    try {
      final box = await HiveService.openBox<List>(
        _myContactsCacheBoxName,
        encrypted: true,
      );

      await box.put(userId, contacts);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Get a single contact from cache
  Future<ContactModel?> getContact(String contactId) async {
    try {
      final box = await HiveService.openBox<ContactModel>(
        _contactsBoxName,
        encrypted: true,
      );

      return box.get(contactId);
    } catch (e) {
      return null;
    }
  }

  /// Cache a single contact
  Future<void> cacheContact(ContactModel contact) async {
    try {
      final box = await HiveService.openBox<ContactModel>(
        _contactsBoxName,
        encrypted: true,
      );

      await box.put(contact.id, contact);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Remove a contact from cache
  Future<void> removeContact(String contactId) async {
    try {
      final box = await HiveService.openBox<ContactModel>(
        _contactsBoxName,
        encrypted: true,
      );

      await box.delete(contactId);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Clear all cached contacts for a user
  Future<void> clearContactsCache(String userId) async {
    try {
      final box = await HiveService.openBox<List>(
        _myContactsCacheBoxName,
        encrypted: true,
      );

      await box.delete(userId);
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Clear all contact caches (for logout/cleanup)
  Future<void> clearAllCaches() async {
    try {
      final contactsBox = await HiveService.openBox<ContactModel>(
        _contactsBoxName,
        encrypted: true,
      );
      final cacheBox = await HiveService.openBox<List>(
        _myContactsCacheBoxName,
        encrypted: true,
      );

      await contactsBox.clear();
      await cacheBox.clear();
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }
}
