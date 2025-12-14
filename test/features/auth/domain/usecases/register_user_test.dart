// test/features/auth/domain/usecases/register_user_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late RegisterUser useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUser(mockRepository);
  });

  group('RegisterUser Use Case', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testFullName = 'John Doe';

    final testUser = User(
      id: '123',
      email: testEmail,
      fullName: testFullName,
      createdAt: DateTime(2025),
    );

    group('Successful Registration', () {
      test('registers user when all validations pass', () async {
        // Arrange
        when(() => mockRepository.isValidEmail(testEmail)).thenReturn(true);
        when(() => mockRepository.isValidPassword(testPassword)).thenReturn(true);
        when(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => Right(testUser));

        final params = RegisterUserParams(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, Right(testUser));
        verify(() => mockRepository.isValidEmail(testEmail)).called(1);
        verify(() => mockRepository.isValidPassword(testPassword)).called(1);
        verify(() => mockRepository.registerUser(
              email: testEmail.toLowerCase(),
              password: testPassword,
              fullName: testFullName,
            )).called(1);
      });

      test('trims and lowercases email before registration', () async {
        // Arrange
        const emailWithSpaces = '  Test@Example.COM  ';
        when(() => mockRepository.isValidEmail(emailWithSpaces)).thenReturn(true);
        when(() => mockRepository.isValidPassword(testPassword)).thenReturn(true);
        when(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => Right(testUser));

        final params = RegisterUserParams(
          email: emailWithSpaces,
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        await useCase(params);

        // Assert
        verify(() => mockRepository.registerUser(
              email: 'test@example.com', // Trimmed and lowercased
              password: testPassword,
              fullName: testFullName,
            )).called(1);
      });

      test('trims fullName before registration', () async {
        // Arrange
        const fullNameWithSpaces = '  John Doe  ';
        when(() => mockRepository.isValidEmail(testEmail)).thenReturn(true);
        when(() => mockRepository.isValidPassword(testPassword)).thenReturn(true);
        when(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => Right(testUser));

        final params = RegisterUserParams(
          email: testEmail,
          password: testPassword,
          fullName: fullNameWithSpaces,
        );

        // Act
        await useCase(params);

        // Assert
        verify(() => mockRepository.registerUser(
              email: testEmail.toLowerCase(),
              password: testPassword,
              fullName: 'John Doe', // Trimmed
            )).called(1);
      });
    });

    group('Validation Failures', () {
      test('returns EmptyFieldFailure when email is empty', () async {
        // Arrange
        final params = RegisterUserParams(
          email: '',
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<EmptyFieldFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            ));
      });

      test('returns EmptyFieldFailure when email is only spaces', () async {
        // Arrange
        final params = RegisterUserParams(
          email: '   ',
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) {
            expect(failure, isA<EmptyFieldFailure>());
            expect((failure as EmptyFieldFailure).fieldName, 'Email');
          },
          (_) => fail('Should return failure'),
        );
      });

      test('returns EmptyFieldFailure when password is empty', () async {
        // Arrange
        final params = RegisterUserParams(
          email: testEmail,
          password: '',
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) {
            expect(failure, isA<EmptyFieldFailure>());
            expect((failure as EmptyFieldFailure).fieldName, 'Password');
          },
          (_) => fail('Should return failure'),
        );
      });

      test('returns EmptyFieldFailure when fullName is empty', () async {
        // Arrange
        final params = RegisterUserParams(
          email: testEmail,
          password: testPassword,
          fullName: '',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) {
            expect(failure, isA<EmptyFieldFailure>());
            expect((failure as EmptyFieldFailure).fieldName, 'Full name');
          },
          (_) => fail('Should return failure'),
        );
      });

      test('returns EmptyFieldFailure when fullName is only spaces', () async {
        // Arrange
        final params = RegisterUserParams(
          email: testEmail,
          password: testPassword,
          fullName: '   ',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<EmptyFieldFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('returns InvalidEmailFailure when email format is invalid', () async {
        // Arrange
        when(() => mockRepository.isValidEmail('invalid-email')).thenReturn(false);

        final params = RegisterUserParams(
          email: 'invalid-email',
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<InvalidEmailFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(() => mockRepository.isValidEmail('invalid-email')).called(1);
        verifyNever(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            ));
      });

      test('returns WeakPasswordFailure when password is too short', () async {
        // Arrange
        const weakPassword = '1234567'; // 7 chars
        when(() => mockRepository.isValidEmail(testEmail)).thenReturn(true);
        when(() => mockRepository.isValidPassword(weakPassword)).thenReturn(false);

        final params = RegisterUserParams(
          email: testEmail,
          password: weakPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<WeakPasswordFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(() => mockRepository.isValidPassword(weakPassword)).called(1);
        verifyNever(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            ));
      });
    });

    group('Repository Failures', () {
      test('returns EmailAlreadyExistsFailure when email is taken', () async {
        // Arrange
        when(() => mockRepository.isValidEmail(testEmail)).thenReturn(true);
        when(() => mockRepository.isValidPassword(testPassword)).thenReturn(true);
        when(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => const Left(EmailAlreadyExistsFailure()));

        final params = RegisterUserParams(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<EmailAlreadyExistsFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('propagates StorageFailure from repository', () async {
        // Arrange
        when(() => mockRepository.isValidEmail(testEmail)).thenReturn(true);
        when(() => mockRepository.isValidPassword(testPassword)).thenReturn(true);
        when(() => mockRepository.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => const Left(StorageFailure()));

        final params = RegisterUserParams(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('Validation Order', () {
      test('validates in correct order: empty fields → email format → password strength', () async {
        // Test that we check empty email before format
        final params1 = RegisterUserParams(
          email: '',
          password: testPassword,
          fullName: testFullName,
        );

        final result1 = await useCase(params1);
        result1.fold(
          (failure) => expect(failure, isA<EmptyFieldFailure>()),
          (_) => fail('Should return EmptyFieldFailure'),
        );

        // Verify we didn't call isValidEmail for empty string
        verifyNever(() => mockRepository.isValidEmail(any()));
      });
    });
  });
}
