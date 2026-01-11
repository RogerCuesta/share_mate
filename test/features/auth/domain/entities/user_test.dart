// test/features/auth/domain/entities/user_test.dart

import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Entity', () {
    final testUser = User(
      id: '123',
      email: 'test@example.com',
      fullName: 'John Doe',
      createdAt: DateTime(2025),
    );

    group('Creation', () {
      test('creates user with required fields', () {
        expect(testUser.id, '123');
        expect(testUser.email, 'test@example.com');
        expect(testUser.fullName, 'John Doe');
        expect(testUser.createdAt, DateTime(2025));
      });

      test('is immutable (Freezed ensures this)', () {
        // User is created with const factory, ensuring immutability
        // Freezed generates immutable classes by default
        final user1 = User(
          id: '1',
          email: 'test@test.com',
          fullName: 'Test User',
          createdAt: DateTime(2025),
        );

        final user2 = User(
          id: '1',
          email: 'test@test.com',
          fullName: 'Test User',
          createdAt: DateTime(2025),
        );

        // Freezed provides value equality
        expect(user1, equals(user2));
        expect(user1, isNotNull);
      });
    });

    group('Business Logic - initials', () {
      test('returns correct initials for full name with two words', () {
        final user = User(
          id: '1',
          email: 'john@example.com',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
        );
        expect(user.initials, 'JD');
      });

      test('returns correct initials for single name', () {
        final user = User(
          id: '1',
          email: 'john@example.com',
          fullName: 'John',
          createdAt: DateTime.now(),
        );
        expect(user.initials, 'J');
      });

      test('returns correct initials for three words name', () {
        final user = User(
          id: '1',
          email: 'john@example.com',
          fullName: 'John Michael Doe',
          createdAt: DateTime.now(),
        );
        expect(user.initials, 'JD'); // First and last
      });

      test('returns empty string for empty name', () {
        final user = User(
          id: '1',
          email: 'john@example.com',
          fullName: '',
          createdAt: DateTime.now(),
        );
        expect(user.initials, '');
      });

      test('handles names with extra spaces', () {
        final user = User(
          id: '1',
          email: 'john@example.com',
          fullName: '  John   Doe  ',
          createdAt: DateTime.now(),
        );
        expect(user.initials, 'JD');
      });
    });

    group('Business Logic - isValid', () {
      test('returns true for valid user', () {
        expect(testUser.isValid, true);
      });

      test('returns false for empty id', () {
        final user = User(
          id: '',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
        );
        expect(user.isValid, false);
      });

      test('returns false for empty email', () {
        final user = User(
          id: '123',
          email: '',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
        );
        expect(user.isValid, false);
      });

      test('returns false for empty fullName', () {
        final user = User(
          id: '123',
          email: 'test@example.com',
          fullName: '',
          createdAt: DateTime.now(),
        );
        expect(user.isValid, false);
      });

      test('returns false for invalid email format', () {
        final user = User(
          id: '123',
          email: 'invalid-email',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
        );
        expect(user.isValid, false);
      });

      test('validates email format correctly - valid emails', () {
        final validEmails = [
          'user@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
          'user123@test-domain.com',
        ];

        for (final email in validEmails) {
          final user = User(
            id: '123',
            email: email,
            fullName: 'John Doe',
            createdAt: DateTime.now(),
          );
          expect(user.isValid, true, reason: 'Email $email should be valid');
        }
      });

      test('validates email format correctly - invalid emails', () {
        final invalidEmails = [
          'invalid',
          '@example.com',
          'user@',
          'user @example.com',
          'user@example',
        ];

        for (final email in invalidEmails) {
          final user = User(
            id: '123',
            email: email,
            fullName: 'John Doe',
            createdAt: DateTime.now(),
          );
          expect(user.isValid, false, reason: 'Email $email should be invalid');
        }
      });
    });

    group('Business Logic - isEmailVerified', () {
      test('returns true by default (placeholder)', () {
        expect(testUser.isEmailVerified, true);
      });
    });

    group('Business Logic - Supabase Sync Status', () {
      test('isSyncedWithSupabase returns true when supabaseId is set', () {
        final user = User(
          id: '123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
          supabaseId: 'supabase-uuid-123',
        );
        expect(user.isSyncedWithSupabase, true);
        expect(user.isLocalOnly, false);
      });

      test('isSyncedWithSupabase returns false when supabaseId is null', () {
        final user = User(
          id: '123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
        );
        expect(user.isSyncedWithSupabase, false);
        expect(user.isLocalOnly, true);
      });

      test('isLocalOnly returns true when user has no supabaseId', () {
        final user = User(
          id: 'local-123',
          email: 'offline@example.com',
          fullName: 'Offline User',
          createdAt: DateTime.now(),
          // supabaseId not set (null)
        );
        expect(user.isLocalOnly, true);
        expect(user.isSyncedWithSupabase, false);
      });
    });

    group('Equality', () {
      test('two users with same data are equal', () {
        final user1 = User(
          id: '123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime(2025),
        );

        final user2 = User(
          id: '123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime(2025),
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('two users with different data are not equal', () {
        final user1 = User(
          id: '123',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime(2025),
        );

        final user2 = User(
          id: '456',
          email: 'test@example.com',
          fullName: 'John Doe',
          createdAt: DateTime(2025),
        );

        expect(user1, isNot(equals(user2)));
      });
    });

    group('CopyWith', () {
      test('creates copy with updated email', () {
        final updated = testUser.copyWith(email: 'new@example.com');

        expect(updated.id, testUser.id);
        expect(updated.email, 'new@example.com');
        expect(updated.fullName, testUser.fullName);
        expect(updated.createdAt, testUser.createdAt);
      });

      test('creates copy with updated fullName', () {
        final updated = testUser.copyWith(fullName: 'Jane Doe');

        expect(updated.id, testUser.id);
        expect(updated.email, testUser.email);
        expect(updated.fullName, 'Jane Doe');
        expect(updated.createdAt, testUser.createdAt);
      });

      test('creates copy without changes when no params', () {
        final updated = testUser.copyWith();

        expect(updated, equals(testUser));
      });
    });

    group('toString', () {
      test('returns string representation', () {
        final str = testUser.toString();

        expect(str, contains('User'));
        expect(str, contains('123'));
        expect(str, contains('test@example.com'));
        expect(str, contains('John Doe'));
      });
    });
  });
}
