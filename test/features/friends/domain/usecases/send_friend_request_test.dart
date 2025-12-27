// test/features/friends/domain/usecases/send_friend_request_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/friends/domain/failures/friendship_failure.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/send_friend_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late SendFriendRequest useCase;
  late MockFriendshipRepository mockRepository;

  setUp(() {
    mockRepository = MockFriendshipRepository();
    useCase = SendFriendRequest(mockRepository);
  });

  group('SendFriendRequest Use Case', () {
    const testEmail = 'friend@example.com';
    const testFriendshipId = 'friendship-123';

    group('Successful friend request', () {
      test('sends friend request when email is valid', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Right(testFriendshipId));

        // Act
        final result = await useCase(friendEmail: testEmail);

        // Assert
        expect(result, const Right(testFriendshipId));
        verify(() => mockRepository.sendFriendRequest(
              friendEmail: testEmail.toLowerCase().trim(),
            )).called(1);
      });

      test('trims and lowercases email before sending request', () async {
        // Arrange
        const emailWithSpaces = '  Friend@Example.COM  ';
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Right(testFriendshipId));

        // Act
        await useCase(friendEmail: emailWithSpaces);

        // Assert
        verify(() => mockRepository.sendFriendRequest(
              friendEmail: 'friend@example.com', // Trimmed and lowercased
            )).called(1);
      });
    });

    group('Validation Failures', () {
      test('returns userNotFound failure when email is empty', () async {
        // Act
        final result = await useCase(friendEmail: '');

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.sendFriendRequest(
              friendEmail: any(named: 'friendEmail'),
            ));
      });

      test('returns userNotFound failure when email is only spaces', () async {
        // Act
        final result = await useCase(friendEmail: '   ');

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('returns userNotFound failure when email format is invalid', () async {
        // Arrange
        const invalidEmail = 'invalid-email';

        // Act
        final result = await useCase(friendEmail: invalidEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.sendFriendRequest(
              friendEmail: any(named: 'friendEmail'),
            ));
      });

      test('returns userNotFound failure when email has no @ symbol', () async {
        // Arrange
        const invalidEmail = 'friend.example.com';

        // Act
        final result = await useCase(friendEmail: invalidEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('returns userNotFound failure when email has no domain', () async {
        // Arrange
        const invalidEmail = 'friend@';

        // Act
        final result = await useCase(friendEmail: invalidEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('accepts valid email formats', () async {
        // Arrange
        final validEmails = [
          'test@example.com',
          'user.name@example.com',
          'user_123@test-domain.com',
        ];

        for (final email in validEmails) {
          when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
              .thenAnswer((_) async => const Right(testFriendshipId));

          // Act
          final result = await useCase(friendEmail: email);

          // Assert
          expect(result, isA<Right>(), reason: 'Email $email should be valid');
        }
      });
    });

    group('Repository Failures', () {
      test('propagates userNotFound from repository', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Left(FriendshipFailure.userNotFound()));

        // Act
        final result = await useCase(friendEmail: testEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('propagates alreadyFriends from repository', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Left(FriendshipFailure.alreadyFriends()));

        // Act
        final result = await useCase(friendEmail: testEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                alreadyFriends: (_) => {}, // Expected
                orElse: () => fail('Expected alreadyFriends'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('propagates cannotAddSelf from repository', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Left(FriendshipFailure.cannotAddSelf()));

        // Act
        final result = await useCase(friendEmail: testEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                cannotAddSelf: (_) => {}, // Expected
                orElse: () => fail('Expected cannotAddSelf'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('propagates networkError from repository', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Left(FriendshipFailure.networkError()));

        // Act
        final result = await useCase(friendEmail: testEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                networkError: (_) => {}, // Expected
                orElse: () => fail('Expected networkError'),
              ),
          (_) => fail('Should return failure'),
        );
      });

      test('propagates serverError from repository', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Left(FriendshipFailure.serverError()));

        // Act
        final result = await useCase(friendEmail: testEmail);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => failure.maybeWhen(
                serverError: (_) => {}, // Expected
                orElse: () => fail('Expected serverError'),
              ),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('Validation Order', () {
      test('validates in correct order: empty → format', () async {
        // Test that we check empty email before calling repository
        final result = await useCase(friendEmail: '');

        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return userNotFound failure'),
        );

        // Verify we didn't call repository for empty string
        verifyNever(() => mockRepository.sendFriendRequest(
              friendEmail: any(named: 'friendEmail'),
            ));
      });

      test('validates format before calling repository', () async {
        // Test that invalid format doesn't reach repository
        final result = await useCase(friendEmail: 'invalid-email');

        result.fold(
          (failure) => failure.maybeWhen(
                userNotFound: (_) => {}, // Expected
                orElse: () => fail('Expected userNotFound'),
              ),
          (_) => fail('Should return userNotFound failure'),
        );

        // Verify repository was not called
        verifyNever(() => mockRepository.sendFriendRequest(
              friendEmail: any(named: 'friendEmail'),
            ));
      });
    });

    group('Email Normalization', () {
      test('normalizes email with mixed case and spaces', () async {
        // Arrange
        when(() => mockRepository.sendFriendRequest(friendEmail: any(named: 'friendEmail')))
            .thenAnswer((_) async => const Right(testFriendshipId));

        final testCases = {
          '  TEST@EXAMPLE.COM  ': 'test@example.com',
          'Friend@Example.COM': 'friend@example.com',
          '  user@domain.com': 'user@domain.com',
          'USER@DOMAIN.COM  ': 'user@domain.com',
        };

        for (final entry in testCases.entries) {
          // Act
          await useCase(friendEmail: entry.key);

          // Assert
          verify(() => mockRepository.sendFriendRequest(
                friendEmail: entry.value,
              )).called(1);
        }
      });
    });
  });
}
