import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sortMembersForDetail', () {
    test('orders unpaid members first by due date urgency', () {
      final members = [
        _member(
          id: 'paid-late',
          userName: 'Zoe',
          hasPaid: true,
          dueDate: DateTime(2026, 3, 20),
        ),
        _member(
          id: 'pending-mid',
          userName: 'Bruno',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 18),
        ),
        _member(
          id: 'pending-early',
          userName: 'Ana',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 12),
        ),
      ];

      final sorted = sortMembersForDetail(members);
      expect(sorted.map((member) => member.id).toList(), [
        'pending-early',
        'pending-mid',
        'paid-late',
      ]);
    });

    test('uses deterministic user-name and id tie-breakers', () {
      final members = [
        _member(
          id: 'id-c',
          userName: 'alice',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 10),
        ),
        _member(
          id: 'id-a',
          userName: 'Alice',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 10),
        ),
        _member(
          id: 'id-b',
          userName: 'Bob',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 10),
        ),
      ];

      final sorted = sortMembersForDetail(members);
      expect(sorted.map((member) => member.id).toList(), [
        'id-a',
        'id-c',
        'id-b',
      ]);
    });

    test('does not mutate source list instance ordering', () {
      final source = [
        _member(
          id: 'two',
          userName: 'B',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 20),
        ),
        _member(
          id: 'one',
          userName: 'A',
          hasPaid: false,
          dueDate: DateTime(2026, 3, 10),
        ),
      ];
      final originalOrder = source.map((member) => member.id).toList();

      final sorted = sortMembersForDetail(source);
      expect(source.map((member) => member.id).toList(), originalOrder);
      expect(sorted.map((member) => member.id).toList(), ['one', 'two']);
    });
  });
}

SubscriptionMember _member({
  required String id,
  required String userName,
  required bool hasPaid,
  required DateTime dueDate,
}) {
  return SubscriptionMember(
    id: id,
    subscriptionId: 'sub-1',
    userId: 'user-$id',
    userName: userName,
    amountToPay: 10,
    dueDate: dueDate,
    createdAt: DateTime(2026, 1, 1),
    hasPaid: hasPaid,
  );
}
