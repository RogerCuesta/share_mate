// lib/features/contacts/data/datasources/contact_remote_datasource.dart

import 'package:flutter_project_agents/features/contacts/data/models/contact_model.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/update_contact_input.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote datasource for contact operations using Supabase
///
/// Performs direct CRUD operations on the contacts table (no RPC functions needed)
class ContactRemoteDataSource {

  const ContactRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  /// Get all contacts for a user
  ///
  /// Throws [PostgrestException] on database errors
  /// Throws [Exception] on unexpected errors
  Future<List<ContactModel>> getMyContacts(String userId) async {
    try {
      final response = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .order('contact_name', ascending: true);

      return (response as List)
          .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  /// Add a new contact
  ///
  /// Throws [PostgrestException] on database errors (including duplicate email)
  /// Throws [Exception] on unexpected errors
  Future<ContactModel> addContact(
    String userId,
    AddContactInput input,
  ) async {
    try {
      final data = {
        'user_id': userId,
        'contact_name': input.normalizedName,
        'contact_email': input.normalizedEmail,
        if (input.avatar != null) 'contact_avatar': input.avatar,
        if (input.notes != null) 'notes': input.notes,
      };

      final response = await _supabase
          .from('contacts')
          .insert(data)
          .select()
          .single();

      return ContactModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for unique constraint violation (duplicate email)
      if (e.code == '23505') {
        throw Exception('Contact with this email already exists');
      }
      throw Exception('Failed to add contact: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  /// Update an existing contact
  ///
  /// Throws [PostgrestException] on database errors
  /// Throws [Exception] if contact not found or on unexpected errors
  Future<ContactModel> updateContact(
    String contactId,
    UpdateContactInput input,
  ) async {
    try {
      final data = {
        'contact_name': input.normalizedName,
        'contact_email': input.normalizedEmail,
        if (input.avatar != null) 'contact_avatar': input.avatar,
        if (input.notes != null) 'notes': input.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('contacts')
          .update(data)
          .eq('id', contactId)
          .select()
          .single();

      return ContactModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for unique constraint violation (duplicate email)
      if (e.code == '23505') {
        throw Exception('Contact with this email already exists');
      }
      // Check for not found (no rows returned)
      if (e.code == 'PGRST116') {
        throw Exception('Contact not found');
      }
      throw Exception('Failed to update contact: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  /// Delete a contact
  ///
  /// Throws [PostgrestException] on database errors
  /// Throws [Exception] if contact not found or on unexpected errors
  Future<void> deleteContact(String contactId) async {
    try {
      await _supabase
          .from('contacts')
          .delete()
          .eq('id', contactId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete contact: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }
}
