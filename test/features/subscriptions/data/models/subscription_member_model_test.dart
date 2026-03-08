import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionMemberModel', () {
    test('accepts nullable user_email when deserializing', () {
      final payload = <String, dynamic>{
        'id': 'member-row-1',
        'subscription_id': 'sub-1',
        'user_id': 'contact-local-1',
        'user_name': 'Local Friend',
        'user_email': null,
        'user_avatar': null,
        'amount_to_pay': 7.5,
        'has_paid': false,
        'last_payment_date': null,
        'due_date': '2026-03-31T00:00:00.000Z',
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': null,
      };

      final model = SubscriptionMemberModel.fromJson(payload);

      expect(model.userEmail, isNull);
      expect(model.userName, 'Local Friend');
    });

    test('round-trips nullable user_email safely', () {
      final model = SubscriptionMemberModel(
        id: 'member-row-2',
        subscriptionId: 'sub-2',
        userId: 'contact-local-2',
        userName: 'No Mail',
        userEmail: null,
        amountToPay: 8.0,
        hasPaid: false,
        dueDate: DateTime.utc(2026, 4, 30),
        createdAt: DateTime.utc(2026, 3, 1),
      );

      final json = model.toJson();

      expect(json['user_email'], isNull);
      expect(json['id'], 'member-row-2');
    });
  });
}
