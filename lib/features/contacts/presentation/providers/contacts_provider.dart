// lib/features/contacts/presentation/providers/contacts_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/update_contact_input.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contacts_provider.g.dart';

/// Provider for fetching contacts list
///
/// Automatically refreshes when user changes or on manual invalidation
@riverpod
Future<List<Contact>> contactsList(ContactsListRef ref) async {
  // Watch auth state to auto-refresh on user change
  final authState = ref.watch(authProvider);

  // Get contacts based on auth state
  return await authState.maybeWhen(
    authenticated: (user) async {
      final getMyContacts = ref.watch(getMyContactsProvider);
      final result = await getMyContacts(user.id);

      return result.fold(
        (failure) {
          // Log error but return empty list (don't throw)
          debugPrint('Failed to load contacts: $failure');
          return <Contact>[];
        },
        (contacts) => contacts,
      );
    },
    orElse: () async => <Contact>[],
  );
}

/// Notifier for adding a new contact
@riverpod
class AddContactNotifier extends _$AddContactNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Add a new contact
  Future<void> add(AddContactInput input) async {
    state = const AsyncValue.loading();

    final authState = ref.read(authProvider);
    final user = authState.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (user == null) {
      state = AsyncValue.error(
        Exception('User not authenticated'),
        StackTrace.current,
      );
      return;
    }

    final addContact = ref.read(addContactProvider);
    final result = await addContact(user.id, input);

    state = await AsyncValue.guard(() async {
      result.fold(
        (failure) => throw Exception(failure.toString()),
        (contact) {
          // Invalidate contacts list to trigger refresh
          ref.invalidate(contactsListProvider);
        },
      );
    });
  }
}

/// Notifier for updating a contact
@riverpod
class UpdateContactNotifier extends _$UpdateContactNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Update an existing contact
  Future<void> updateContact(String contactId, UpdateContactInput input) async {
    state = const AsyncValue.loading();

    final updateContact = ref.read(updateContactProvider);
    final result = await updateContact(contactId, input);

    state = await AsyncValue.guard(() async {
      result.fold(
        (failure) => throw Exception(failure.toString()),
        (contact) {
          // Invalidate contacts list to trigger refresh
          ref.invalidate(contactsListProvider);
        },
      );
    });
  }
}

/// Notifier for deleting a contact
@riverpod
class DeleteContactNotifier extends _$DeleteContactNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Delete a contact
  Future<void> delete(String contactId) async {
    state = const AsyncValue.loading();

    final deleteContact = ref.read(deleteContactProvider);
    final result = await deleteContact(contactId);

    state = await AsyncValue.guard(() async {
      result.fold(
        (failure) => throw Exception(failure.toString()),
        (_) {
          // Invalidate contacts list to trigger refresh
          ref.invalidate(contactsListProvider);
        },
      );
    });
  }
}
