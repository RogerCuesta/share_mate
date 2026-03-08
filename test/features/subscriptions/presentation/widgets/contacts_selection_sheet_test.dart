import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/contacts_selection_sheet.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/quick_contact_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactsSelectionSheet', () {
    testWidgets('renders select and quick create tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactsSelectionSheet(
              contacts: [
                _contact(id: '1', name: 'Ana'),
                _contact(id: '2', name: 'Bob'),
              ],
              selectedContactIds: const {},
              onSelectionChanged: (_, __) {},
              onQuickCreate: (_) async {},
              onEditContact: (_) async {},
              onDeleteContact: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Members'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Quick Create'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('contacts-sheet-search-field')),
        'bob',
      );
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
    });

    testWidgets('calls selection callback when contact is tapped', (
      tester,
    ) async {
      Contact? selectedContact;
      bool? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactsSelectionSheet(
              contacts: [_contact(id: '1', name: 'Ana')],
              selectedContactIds: const {},
              onSelectionChanged: (contact, selected) {
                selectedContact = contact;
                selectedValue = selected;
              },
              onQuickCreate: (_) async {},
              onEditContact: (_) async {},
              onDeleteContact: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('contacts-sheet-item-1')));
      await tester.pumpAndSettle();

      expect(selectedContact?.id, '1');
      expect(selectedValue, isTrue);
    });

    testWidgets('duplicate name can reuse existing contact', (tester) async {
      Contact? selectedContact;
      bool? selectedValue;
      var createCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactsSelectionSheet(
              contacts: [_contact(id: '1', name: 'Alex')],
              selectedContactIds: const {},
              onSelectionChanged: (contact, selected) {
                selectedContact = contact;
                selectedValue = selected;
              },
              onQuickCreate: (_) async {
                createCalls += 1;
              },
              onEditContact: (_) async {},
              onDeleteContact: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('contacts-sheet-quick-tab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('quick-contact-name-field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('quick-contact-submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Contact name already exists'), findsOneWidget);

      await tester.tap(find.byKey(const Key('duplicate-reuse-button')));
      await tester.pumpAndSettle();

      expect(selectedContact?.id, '1');
      expect(selectedValue, isTrue);
      expect(createCalls, 0);
    });

    testWidgets('duplicate name can still create with explicit confirmation', (
      tester,
    ) async {
      QuickContactDraft? createdDraft;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactsSelectionSheet(
              contacts: [_contact(id: '1', name: 'Alex')],
              selectedContactIds: const {},
              onSelectionChanged: (_, __) {},
              onQuickCreate: (draft) async {
                createdDraft = draft;
              },
              onEditContact: (_) async {},
              onDeleteContact: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('contacts-sheet-quick-tab')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('quick-contact-name-field')),
        'Alex',
      );
      await tester.tap(find.byKey(const Key('quick-contact-submit-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('duplicate-create-anyway-button')));
      await tester.pumpAndSettle();

      expect(createdDraft, isNotNull);
      expect(createdDraft?.name, 'Alex');
    });
  });
}

Contact _contact({
  required String id,
  required String name,
}) {
  return Contact(
    id: id,
    userId: 'user-1',
    name: name,
    email: '$id@example.com',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}
