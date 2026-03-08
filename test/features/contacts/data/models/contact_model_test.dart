import 'package:flutter_project_agents/features/contacts/data/models/contact_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactModel', () {
    test('deserializes nullable contact_email and preserves color metadata', () {
      final payload = <String, dynamic>{
        'id': 'contact-1',
        'user_id': 'owner-1',
        'contact_name': 'Alex',
        'contact_email': null,
        'contact_avatar': 'avatar://alex',
        'contact_color': '#22C55E',
        'notes': null,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-02T00:00:00.000Z',
      };

      final model = ContactModel.fromJson(payload);

      expect(model.email, isNull);
      expect(model.color, '#22C55E');
      expect(model.avatar, 'avatar://alex');
    });

    test('serializes nullable contact_email for local-only contact', () {
      final model = ContactModel(
        id: 'contact-2',
        userId: 'owner-1',
        name: 'Sam',
        createdAt: DateTime.utc(2026, 3, 3),
        updatedAt: DateTime.utc(2026, 3, 3),
        email: null,
        color: '#3B82F6',
      );

      final json = model.toJson();

      expect(json['contact_email'], isNull);
      expect(json['contact_color'], '#3B82F6');
      expect(json['contact_name'], 'Sam');
    });
  });
}
