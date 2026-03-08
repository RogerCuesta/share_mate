import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/quick_contact_form.dart';

typedef ContactSelectionChanged = void Function(
  Contact contact, {
  required bool selected,
});
typedef ContactActionCallback = Future<void> Function(Contact contact);
typedef QuickContactCreateCallback = Future<void> Function(
  QuickContactDraft draft,
);

enum _DuplicateNameDecision { reuseExisting, createAnyway }

class ContactsSelectionSheet extends StatefulWidget {
  const ContactsSelectionSheet({
    required this.contacts,
    required this.selectedContactIds,
    required this.onSelectionChanged,
    required this.onQuickCreate,
    required this.onEditContact,
    required this.onDeleteContact,
    super.key,
  });

  final List<Contact> contacts;
  final Set<String> selectedContactIds;
  final ContactSelectionChanged onSelectionChanged;
  final QuickContactCreateCallback onQuickCreate;
  final ContactActionCallback onEditContact;
  final ContactActionCallback onDeleteContact;

  @override
  State<ContactsSelectionSheet> createState() => _ContactsSelectionSheetState();
}

class _ContactsSelectionSheetState extends State<ContactsSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCreatingQuickContact = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.contacts;
    }

    return widget.contacts.where((contact) {
      final email = contact.email?.toLowerCase() ?? '';
      final notes = contact.notes?.toLowerCase() ?? '';
      return contact.name.toLowerCase().contains(query) ||
          email.contains(query) ||
          notes.contains(query);
    }).toList();
  }

  Contact? _findDuplicateByName(String name) {
    final normalizedName = name.trim().toLowerCase();
    for (final contact in widget.contacts) {
      if (contact.name.trim().toLowerCase() == normalizedName) {
        return contact;
      }
    }
    return null;
  }

  Future<void> _handleQuickCreate(QuickContactDraft draft) async {
    final duplicate = _findDuplicateByName(draft.name);
    if (duplicate != null) {
      final decision = await showDialog<_DuplicateNameDecision>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contact name already exists'),
          content: Text(
            '"${duplicate.name}" is already in your contacts. '
            'You can reuse it or create a new one anyway.',
          ),
          actions: [
            TextButton(
              key: const Key('duplicate-create-anyway-button'),
              onPressed: () => Navigator.of(context)
                  .pop(_DuplicateNameDecision.createAnyway),
              child: const Text('Create Anyway'),
            ),
            FilledButton(
              key: const Key('duplicate-reuse-button'),
              onPressed: () => Navigator.of(
                context,
              ).pop(_DuplicateNameDecision.reuseExisting),
              child: const Text('Use Existing'),
            ),
          ],
        ),
      );

      if (decision == _DuplicateNameDecision.reuseExisting) {
        widget.onSelectionChanged(duplicate, selected: true);
        return;
      }
      if (decision != _DuplicateNameDecision.createAnyway) {
        return;
      }
    }

    setState(() => _isCreatingQuickContact = true);
    try {
      await widget.onQuickCreate(draft);
    } finally {
      if (mounted) {
        setState(() => _isCreatingQuickContact = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.86;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 4),
              const Text(
                'Manage Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const TabBar(
                tabs: [
                  Tab(key: Key('contacts-sheet-select-tab'), text: 'Select'),
                  Tab(
                      key: Key('contacts-sheet-quick-tab'),
                      text: 'Quick Create'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildSelectTab(),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: QuickContactForm(
                        isSubmitting: _isCreatingQuickContact,
                        onSubmit: _handleQuickCreate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectTab() {
    final filteredContacts = _filteredContacts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const Key('contacts-sheet-search-field'),
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search contacts',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: filteredContacts.isEmpty
              ? const Center(
                  child: Text(
                    'No contacts found',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredContacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final selected = widget.selectedContactIds.contains(
                      contact.id,
                    );

                    return ListTile(
                      key: Key('contacts-sheet-item-${contact.id}'),
                      leading: CircleAvatar(
                        backgroundColor: _resolveColor(contact.color),
                        child: Text(contact.initial),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.email ?? 'No email'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: Key('contacts-sheet-edit-${contact.id}'),
                            tooltip: 'Edit',
                            onPressed: () => widget.onEditContact(contact),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            key: Key('contacts-sheet-delete-${contact.id}'),
                            tooltip: 'Delete',
                            onPressed: () => widget.onDeleteContact(contact),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          Checkbox(
                            value: selected,
                            onChanged: (value) {
                              widget.onSelectionChanged(
                                contact,
                                selected: value ?? false,
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () => widget.onSelectionChanged(contact,
                          selected: !selected),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _resolveColor(String? hexColor) {
    final normalized = hexColor?.replaceAll('#', '');
    if (normalized == null || normalized.isEmpty) {
      return const Color(0xFF6C63FF);
    }

    final value = int.tryParse('FF$normalized', radix: 16);
    if (value == null) {
      return const Color(0xFF6C63FF);
    }
    return Color(value);
  }
}
