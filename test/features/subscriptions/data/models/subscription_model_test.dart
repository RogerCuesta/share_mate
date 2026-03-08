import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionModel', () {
    test('deserializes legacy payload without billing_anchor_day', () {
      final legacyPayload = <String, dynamic>{
        'id': 'sub-1',
        'name': 'Netflix',
        'icon_url': null,
        'color': '#E50914',
        'total_cost': 19.99,
        'billing_cycle': 'monthly',
        'due_date': '2026-02-28T00:00:00.000Z',
        'owner_id': 'owner-1',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final model = SubscriptionModel.fromJson(legacyPayload);

      expect(model.billingAnchorDay, 28);
      expect(model.sharedWith, isEmpty);
    });

    test('serializes billing_anchor_day in new payloads', () {
      final model = SubscriptionModel(
        id: 'sub-2',
        name: 'Spotify',
        color: '#1DB954',
        totalCost: 12.50,
        billingCycle: 'monthly',
        dueDate: DateTime.utc(2026, 3, 31),
        billingAnchorDay: 31,
        ownerId: 'owner-1',
        sharedWith: const ['member-1'],
        status: 'active',
        createdAt: DateTime.utc(2026, 3, 1),
      );

      final json = model.toJson();

      expect(json['billing_anchor_day'], 31);
      expect(json['due_date'], '2026-03-31T00:00:00.000Z');
    });
  });
}
