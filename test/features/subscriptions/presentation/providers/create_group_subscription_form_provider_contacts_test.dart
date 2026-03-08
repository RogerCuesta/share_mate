import 'package:flutter_project_agents/features/contacts/domain/entities/contact.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateGroupSubscriptionForm contact orchestration', () {
    test('adds selected contact as member with nullable email support', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );

      notifier.addOrReplaceMemberFromContact(
        _contact(
          id: 'contact-1',
          name: 'Alex',
          email: null,
        ),
      );

      final state = container.read(createGroupSubscriptionFormProvider);
      expect(state.members, hasLength(1));
      expect(state.members.first.id, 'contact-1');
      expect(state.members.first.name, 'Alex');
      expect(state.members.first.email, isNull);
    });

    test('editing selected contact updates existing member in place', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );

      notifier.addOrReplaceMemberFromContact(
        _contact(
          id: 'contact-1',
          name: 'Alex',
          email: 'alex@old.test',
        ),
      );

      notifier.syncMemberFromUpdatedContact(
        _contact(
          id: 'contact-1',
          name: 'Alex Updated',
          email: 'alex@new.test',
        ),
      );

      final state = container.read(createGroupSubscriptionFormProvider);
      expect(state.members, hasLength(1));
      expect(state.members.first.id, 'contact-1');
      expect(state.members.first.name, 'Alex Updated');
      expect(state.members.first.email, 'alex@new.test');
    });

    test('reselecting same contact replaces without duplicating', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );

      notifier.addOrReplaceMemberFromContact(
        _contact(
          id: 'contact-1',
          name: 'Alex',
          email: 'alex@old.test',
        ),
      );

      notifier.addOrReplaceMemberFromContact(
        _contact(
          id: 'contact-1',
          name: 'Alex v2',
          email: 'alex@new.test',
        ),
      );

      final state = container.read(createGroupSubscriptionFormProvider);
      expect(state.members, hasLength(1));
      expect(state.members.first.name, 'Alex v2');
      expect(state.members.first.email, 'alex@new.test');
    });

    test('deleting contact removes selected member safely', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        createGroupSubscriptionFormProvider.notifier,
      );

      notifier.addOrReplaceMemberFromContact(
        _contact(
          id: 'contact-1',
          name: 'Alex',
          email: 'alex@test.dev',
        ),
      );
      notifier.addOrReplaceMemberFromContact(
        _contact(
          id: 'contact-2',
          name: 'Blair',
          email: null,
        ),
      );

      notifier.removeMemberByContactId('contact-1');

      final state = container.read(createGroupSubscriptionFormProvider);
      expect(state.members, hasLength(1));
      expect(state.members.first.id, 'contact-2');
    });
  });
}

Contact _contact({
  required String id,
  required String name,
  required String? email,
}) {
  return Contact(
    id: id,
    userId: 'user-1',
    name: name,
    email: email,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}
