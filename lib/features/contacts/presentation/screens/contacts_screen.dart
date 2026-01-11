// lib/features/contacts/presentation/screens/contacts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/presentation/providers/contacts_provider.dart';
import 'package:flutter_project_agents/features/contacts/presentation/widgets/add_contact_dialog.dart';
import 'package:flutter_project_agents/features/contacts/presentation/widgets/contact_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main Contacts screen with search and FAB
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: const Color(0xFF1E1E2D),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFF2A2A3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Contacts list
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts_outlined,
                            size: 80, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No contacts yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first contact!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter contacts by search query
                final filteredContacts = contacts.where((contact) {
                  final query = _searchQuery.toLowerCase();
                  return contact.name.toLowerCase().contains(query) ||
                      contact.email.toLowerCase().contains(query) ||
                      (contact.notes?.toLowerCase().contains(query) ?? false);
                }).toList();

                if (filteredContacts.isEmpty) {
                  return Center(
                    child: Text(
                      'No contacts match your search',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return ContactListItem(contact: contact);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading contacts',
                  style: TextStyle(color: Colors.red[400]),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(),
        backgroundColor: const Color(0xFF6B4FBB),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final result = await showDialog<AddContactInput>(
      context: context,
      builder: (context) => const AddContactDialog(),
    );

    if (result != null && mounted) {
      await ref.read(addContactNotifierProvider.notifier).add(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
