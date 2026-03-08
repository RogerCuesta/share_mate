import 'package:flutter_project_agents/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/add_contact_input.dart';
import 'package:flutter_project_agents/features/contacts/domain/entities/update_contact_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('ContactRemoteDataSource payload contract', () {
    late ContactRemoteDataSource dataSource;

    setUp(() {
      dataSource = ContactRemoteDataSource(MockSupabaseClient());
    });

    test('add payload keeps optional email as null and includes color', () {
      final payload = dataSource.buildAddContactPayload(
        'user-1',
        const AddContactInput(
          name: '  Local Friend  ',
          email: null,
          color: '#6c63ff',
          notes: '  ',
        ),
      );

      expect(payload['user_id'], 'user-1');
      expect(payload['contact_name'], 'Local Friend');
      expect(payload['contact_email'], isNull);
      expect(payload['contact_color'], '#6C63FF');
      expect(payload.containsKey('notes'), isFalse);
    });

    test('update payload clears blank email to null', () {
      final payload = dataSource.buildUpdateContactPayload(
        const UpdateContactInput(
          name: 'Updated Name',
          email: '   ',
        ),
      );

      expect(payload['contact_name'], 'Updated Name');
      expect(payload['contact_email'], isNull);
      expect(payload['updated_at'], isA<String>());
    });
  });
}
