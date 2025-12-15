// test/features/auth/data/repositories/auth_repository_impl_test.dart

import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_model.dart';
import 'package:flutter_project_agents/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';

// Mocks
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUserLocalDataSource extends Mock implements UserLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAuthResponse extends Mock implements supabase.AuthResponse {}

class MockSupabaseUser extends Mock implements supabase.User {}

class MockSession extends Mock implements supabase.Session {}

class MockUuid extends Mock implements Uuid {}

// Fakes
class FakeUserModel extends Fake implements UserModel {}

class FakeAuthSessionModel extends Fake implements AuthSessionModel {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockUserLocalDataSource mockUserDataSource;
  late MockAuthLocalDataSource mockAuthDataSource;
  late MockUuid mockUuid;

  setUpAll(() {
    // Register fallback values
    registerFallbackValue(FakeUserModel());
    registerFallbackValue(FakeAuthSessionModel());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockUserDataSource = MockUserLocalDataSource();
    mockAuthDataSource = MockAuthLocalDataSource();
    mockUuid = MockUuid();

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      userDataSource: mockUserDataSource,
      authDataSource: mockAuthDataSource,
      uuid: mockUuid,
    );
  });

  group('AuthRepositoryImpl - registerUser()', () {
    const email = 'test@example.com';
    const password = 'password123';
    const fullName = 'John Doe';
    const supabaseId = 'supabase-uuid-123';
    const hashedPassword = 'hashed-password';

    test('should register user with Supabase and save locally on success', () async {
      // Arrange
      final mockSupabaseUser = MockSupabaseUser();
      final mockSession = MockSession();
      final mockAuthResponse = MockAuthResponse();

      when(() => mockSupabaseUser.id).thenReturn(supabaseId);
      when(() => mockSupabaseUser.email).thenReturn(email);
      when(() => mockSupabaseUser.createdAt).thenReturn('2024-01-01T00:00:00Z');
      when(() => mockSupabaseUser.userMetadata).thenReturn({'full_name': fullName});

      when(() => mockSession.accessToken).thenReturn('jwt-token-123');
      when(() => mockSession.expiresAt).thenReturn(
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      when(() => mockAuthResponse.user).thenReturn(mockSupabaseUser);
      when(() => mockAuthResponse.session).thenReturn(mockSession);

      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockUserDataSource.hashPassword(password)).thenReturn(hashedPassword);
      when(() => mockUserDataSource.saveUser(any(), any())).thenAnswer((_) async => {});
      when(() => mockAuthDataSource.saveSession(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.registerUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (user) {
          expect(user.id, supabaseId);
          expect(user.supabaseId, supabaseId);
          expect(user.email, email);
          expect(user.fullName, fullName);
          expect(user.isSyncedWithSupabase, true);
        },
      );

      verify(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).called(1);
      verify(() => mockUserDataSource.saveUser(any(), hashedPassword)).called(1);
      verify(() => mockAuthDataSource.saveSession(any())).called(1);
    });

    test('should return EmailAlreadyInUseFailure when email is already registered', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).thenThrow(const EmailAlreadyInUseRemoteException('Email already in use'));

      // Act
      final result = await repository.registerUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<EmailAlreadyInUseFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });

    test('should fallback to local registration on network error', () async {
      // Arrange
      const localId = 'local-uuid-456';

      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).thenThrow(const NetworkException('Network error'));

      when(() => mockUserDataSource.emailExists(email)).thenAnswer((_) async => false);
      when(() => mockUuid.v4()).thenReturn(localId);
      when(() => mockUserDataSource.hashPassword(password)).thenReturn(hashedPassword);
      when(() => mockUserDataSource.saveUser(any(), any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.registerUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (user) {
          expect(user.id, localId);
          expect(user.supabaseId, isNull);
          expect(user.email, email);
          expect(user.fullName, fullName);
          expect(user.isLocalOnly, true);
        },
      );

      verify(() => mockUserDataSource.emailExists(email)).called(1);
      verify(() => mockUuid.v4()).called(1);
      verify(() => mockUserDataSource.saveUser(any(), hashedPassword)).called(1);
    });

    test('should return EmailAlreadyExistsFailure when email exists locally during offline registration', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).thenThrow(const NetworkException('Network error'));

      when(() => mockUserDataSource.emailExists(email)).thenAnswer((_) async => true);

      // Act
      final result = await repository.registerUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<EmailAlreadyExistsFailure>()),
        (_) => fail('Expected Left, got Right'),
      );

      verify(() => mockUserDataSource.emailExists(email)).called(1);
      verifyNever(() => mockUserDataSource.saveUser(any(), any()));
    });

    test('should return WeakPasswordFailure for weak password', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).thenThrow(const WeakPasswordRemoteException('Password is too weak'));

      // Act
      final result = await repository.registerUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<WeakPasswordFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });

    test('should return SupabaseAuthFailure on other Supabase errors', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
            fullName: fullName,
          )).thenThrow(const AuthRemoteException('Supabase error', code: 'error'));

      // Act
      final result = await repository.registerUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<SupabaseAuthFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });
  });

  group('AuthRepositoryImpl - loginUser()', () {
    const email = 'test@example.com';
    const password = 'password123';
    const supabaseId = 'supabase-uuid-123';
    const hashedPassword = 'hashed-password';

    test('should login with Supabase and save session locally on success', () async {
      // Arrange
      final mockSupabaseUser = MockSupabaseUser();
      final mockSession = MockSession();
      final mockAuthResponse = MockAuthResponse();
      final expiresAt = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;

      when(() => mockSupabaseUser.id).thenReturn(supabaseId);
      when(() => mockSupabaseUser.email).thenReturn(email);
      when(() => mockSupabaseUser.createdAt).thenReturn('2024-01-01T00:00:00Z');
      when(() => mockSupabaseUser.userMetadata).thenReturn({'full_name': 'John Doe'});

      when(() => mockSession.accessToken).thenReturn('jwt-token-123');
      when(() => mockSession.expiresAt).thenReturn(expiresAt);

      when(() => mockAuthResponse.user).thenReturn(mockSupabaseUser);
      when(() => mockAuthResponse.session).thenReturn(mockSession);

      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockUserDataSource.hashPassword(password)).thenReturn(hashedPassword);
      when(() => mockUserDataSource.saveUser(any(), any())).thenAnswer((_) async => {});
      when(() => mockAuthDataSource.saveSession(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.loginUser(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (session) {
          expect(session.userId, supabaseId);
          expect(session.token, 'jwt-token-123');
        },
      );

      verify(() => mockRemoteDataSource.login(email: email, password: password)).called(1);
      verify(() => mockUserDataSource.saveUser(any(), hashedPassword)).called(1);
      verify(() => mockAuthDataSource.saveSession(any())).called(1);
    });

    test('should return InvalidCredentialsFailure for wrong credentials', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenThrow(const InvalidCredentialsRemoteException('Invalid credentials'));

      // Act
      final result = await repository.loginUser(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });

    test('should fallback to local login on network error', () async {
      // Arrange
      const userId = 'local-user-123';
      final mockUserModel = UserModel(
        id: userId,
        email: email,
        fullName: 'John Doe',
        createdAt: DateTime.now(),
      );

      final mockSessionModel = AuthSessionModel(
        userId: userId,
        token: 'local-token-123',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenThrow(const NetworkException('Network error'));

      when(() => mockUserDataSource.verifyCredentials(email, password))
          .thenAnswer((_) async => mockUserModel);

      when(() => mockAuthDataSource.createSession(userId)).thenReturn(mockSessionModel);
      when(() => mockAuthDataSource.saveSession(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.loginUser(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (session) {
          expect(session.userId, userId);
          expect(session.token, 'local-token-123');
        },
      );

      verify(() => mockUserDataSource.verifyCredentials(email, password)).called(1);
      verify(() => mockAuthDataSource.createSession(userId)).called(1);
      verify(() => mockAuthDataSource.saveSession(any())).called(1);
    });

    test('should return InvalidCredentialsFailure when local login fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenThrow(const NetworkException('Network error'));

      when(() => mockUserDataSource.verifyCredentials(email, password))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.loginUser(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });

    test('should return UserNotFoundFailure when user does not exist', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenThrow(const UserNotFoundRemoteException('User not found'));

      // Act
      final result = await repository.loginUser(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UserNotFoundFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });

    test('should return TooManyRequestsFailure on rate limit', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenThrow(const TooManyRequestsRemoteException('Too many requests'));

      // Act
      final result = await repository.loginUser(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<TooManyRequestsFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });
  });

  group('AuthRepositoryImpl - logoutUser()', () {
    test('should logout from Supabase and clear local session on success', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => {});
      when(() => mockAuthDataSource.deleteSession()).thenAnswer((_) async => {});

      // Act
      final result = await repository.logoutUser();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (unit) => expect(unit, equals(unit)),
      );

      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockAuthDataSource.deleteSession()).called(1);
    });

    test('should still logout locally even if Supabase logout fails due to network', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenThrow(const NetworkException('Network error'));
      when(() => mockAuthDataSource.deleteSession()).thenAnswer((_) async => {});

      // Act
      final result = await repository.logoutUser();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockAuthDataSource.deleteSession()).called(1);
    });

    test('should still logout locally even if Supabase logout fails with other errors', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenThrow(
        const AuthRemoteException('Supabase error', code: 'error'),
      );
      when(() => mockAuthDataSource.deleteSession()).thenAnswer((_) async => {});

      // Act
      final result = await repository.logoutUser();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockAuthDataSource.deleteSession()).called(1);
    });

    test('should return StorageFailure if local session deletion fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => {});
      when(() => mockAuthDataSource.deleteSession()).thenThrow(
        Exception('Storage error'),
      );

      // Act
      final result = await repository.logoutUser();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });
  });

  group('AuthRepositoryImpl - getCurrentUser()', () {
    const email = 'test@example.com';

    test('should return user from local storage', () async {
      // Arrange
      final mockUserModel = UserModel(
        id: 'user-123',
        email: email,
        fullName: 'John Doe',
        createdAt: DateTime.now(),
      );

      when(() => mockUserDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserModel);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (user) {
          expect(user.id, 'user-123');
          expect(user.email, email);
        },
      );

      verify(() => mockUserDataSource.getCurrentUser()).called(1);
    });

    test('should return UserNotFoundFailure when no user exists', () async {
      // Arrange
      when(() => mockUserDataSource.getCurrentUser()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UserNotFoundFailure>()),
        (_) => fail('Expected Left, got Right'),
      );

      verify(() => mockUserDataSource.getCurrentUser()).called(1);
    });

    test('should return StorageFailure on error', () async {
      // Arrange
      when(() => mockUserDataSource.getCurrentUser()).thenThrow(
        Exception('Storage error'),
      );

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });
  });

  group('AuthRepositoryImpl - checkAuthStatus()', () {
    test('should return true when valid session and user exist', () async {
      // Arrange
      final mockUserModel = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        fullName: 'John Doe',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthDataSource.hasValidSession()).thenAnswer((_) async => true);
      when(() => mockUserDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserModel);

      // Act
      final result = await repository.checkAuthStatus();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (isAuthenticated) => expect(isAuthenticated, true),
      );

      verify(() => mockAuthDataSource.hasValidSession()).called(1);
      verify(() => mockUserDataSource.getCurrentUser()).called(1);
    });

    test('should return false when no valid session exists', () async {
      // Arrange
      when(() => mockAuthDataSource.hasValidSession()).thenAnswer((_) async => false);

      // Act
      final result = await repository.checkAuthStatus();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (isAuthenticated) => expect(isAuthenticated, false),
      );

      verify(() => mockAuthDataSource.hasValidSession()).called(1);
      verifyNever(() => mockUserDataSource.getCurrentUser());
    });

    test('should return false and delete session when user is not found', () async {
      // Arrange
      when(() => mockAuthDataSource.hasValidSession()).thenAnswer((_) async => true);
      when(() => mockUserDataSource.getCurrentUser()).thenAnswer((_) async => null);
      when(() => mockAuthDataSource.deleteSession()).thenAnswer((_) async => {});

      // Act
      final result = await repository.checkAuthStatus();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right, got Left: $failure'),
        (isAuthenticated) => expect(isAuthenticated, false),
      );

      verify(() => mockAuthDataSource.deleteSession()).called(1);
    });

    test('should return StorageFailure on error', () async {
      // Arrange
      when(() => mockAuthDataSource.hasValidSession()).thenThrow(
        Exception('Storage error'),
      );

      // Act
      final result = await repository.checkAuthStatus();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<StorageFailure>()),
        (_) => fail('Expected Left, got Right'),
      );
    });
  });
}
