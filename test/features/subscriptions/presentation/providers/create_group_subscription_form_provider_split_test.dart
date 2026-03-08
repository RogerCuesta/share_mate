import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateGroupSubscriptionForm split parity', () {
    test('uses shared split output for preview including owner remainder', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(createGroupSubscriptionFormProvider.notifier);

      notifier.updateTotalPrice('10.00');
      notifier.addMember(_member(id: 'm1', name: 'Alex'));
      notifier.addMember(_member(id: 'm2', name: 'Blair'));

      final state = container.read(createGroupSubscriptionFormProvider);
      expect(state.memberFloorSplitAmount, 3.33);
      expect(state.breakdown, hasLength(3));
      expect(state.breakdown[0].name, 'Alex');
      expect(state.breakdown[0].amount, 3.33);
      expect(state.breakdown[1].name, 'Blair');
      expect(state.breakdown[1].amount, 3.33);
      expect(state.breakdown[2].name, 'You');
      expect(state.breakdown[2].amount, 3.34);
    });

    test('recalculates persisted member amount when total price changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(createGroupSubscriptionFormProvider.notifier);

      notifier.addMember(_member(id: 'm1', name: 'Alex'));
      notifier.addMember(_member(id: 'm2', name: 'Blair'));
      notifier.updateTotalPrice('11.00');
      final beforeChange = container.read(createGroupSubscriptionFormProvider);
      expect(beforeChange.memberFloorSplitAmount, 3.66);

      notifier.updateTotalPrice('12.00');
      final afterChange = container.read(createGroupSubscriptionFormProvider);
      expect(afterChange.memberFloorSplitAmount, 4.0);
      expect(afterChange.breakdown.last.amount, 4.0);
    });

    test('recalculates persisted member amount when member set changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(createGroupSubscriptionFormProvider.notifier);

      notifier.updateTotalPrice('10.00');
      notifier.addMember(_member(id: 'm1', name: 'Alex'));
      final oneMember = container.read(createGroupSubscriptionFormProvider);
      expect(oneMember.memberFloorSplitAmount, 5.0);

      notifier.addMember(_member(id: 'm2', name: 'Blair'));
      final twoMembers = container.read(createGroupSubscriptionFormProvider);
      expect(twoMembers.memberFloorSplitAmount, 3.33);

      notifier.removeMember('m2');
      final reverted = container.read(createGroupSubscriptionFormProvider);
      expect(reverted.memberFloorSplitAmount, 5.0);
    });
  });
}

SubscriptionMemberInput _member({
  required String id,
  required String name,
}) {
  return SubscriptionMemberInput(
    id: id,
    name: name,
    email: '$id@test.dev',
    avatar: null,
  );
}
