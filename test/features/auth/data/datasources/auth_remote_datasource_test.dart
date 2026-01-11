// test/features/auth/data/datasources/auth_remote_datasource_test.dart

import 'package:flutter_project_agents/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUserResponse extends Mock implements UserResponse {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

// Fake for UserAttributes
class FakeUserAttributes extends Fake implements UserAttributes {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late AuthRemoteDataSourceImpl dataSource;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeUserAttributes());
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    dataSource = AuthRemoteDataSourceImpl(client: mockSupabaseClient);

    // Setup default mock behavior
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
  });

  group('AuthRemoteDataSource - register()', () {
    const email = 'test@example.com';
    const password = 'password123';
    const fullName = 'John Doe';
    const userId = 'supabase-uuid-123';

    test('should return AuthResponse with user and session on successful registration', () async {
      // Arrange
      final mockUser = MockUser();
      final mockSession = MockSession();
      final mockAuthResponse = MockAuthResponse();

      when(() => mockUser.id).thenReturn(userId);
      when(() => mockUser.email).thenReturn(email);
      when(() => mockUser.createdAt).thenReturn('2024-01-01T00:00:00Z');
      when(() => mockUser.userMetadata).thenReturn({'full_name': fullName});

      when(() => mockAuthResponse.user).thenReturn(mockUser);
      when(() => mockAuthResponse.session).thenReturn(mockSession);

      when(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponse);

      final mockUserResponse = MockUserResponse();
      when(() => mockUserResponse.user).thenReturn(mockUser);

      when(() => mockGoTrueClient.updateUser(any())).thenAnswer(
        (_) async => mockUserResponse,
      );

      // Act
      final result = await dataSource.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.user, equals(mockUser));
      expect(result.session, equals(mockSession));

      verify(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).called(1);

      verify(() => mockGoTrueClient.updateUser(any())).called(1);
    });

    test('should throw EmailAlreadyInUseRemoteException when email is already registered', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).thenThrow(
        const AuthException('User already registered'),
      );

      // Act & Assert
      expect(
        () => dataSource.register(
          email: email,
          password: password,
          fullName: fullName,
        ),
        throwsA(isA<EmailAlreadyInUseRemoteException>()),
      );
    });

    test('should throw WeakPasswordRemoteException for weak password', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).thenThrow(
        const AuthException('Password is too weak'),
      );

      // Act & Assert
      expect(
        () => dataSource.register(
          email: email,
          password: password,
          fullName: fullName,
        ),
        throwsA(isA<AuthRemoteException>()),
      );
    });

    test('should throw NetworkException on network error', () async {
      // Arrange
      when(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).thenThrow(
        Exception('Socket exception: Network unreachable'),
      );

      // Act & Assert
      expect(
        () => dataSource.register(
          email: email,
          password: password,
          fullName: fullName,
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw AuthRemoteException when user creation returns null', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      when(() => mockAuthResponse.user).thenReturn(null);

      when(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponse);

      // Act & Assert
      expect(
        () => dataSource.register(
          email: email,
          password: password,
          fullName: fullName,
        ),
        throwsA(
          isA<AuthRemoteException>().having(
            (e) => e.message,
            'message',
            contains('User creation returned null'),
          ),
        ),
      );
    });

    test('should continue registration even if metadata update fails', () async {
      // Arrange
      final mockUser = MockUser();
      final mockSession = MockSession();
      final mockAuthResponse = MockAuthResponse();

      when(() => mockUser.id).thenReturn(userId);
      when(() => mockUser.email).thenReturn(email);
      when(() => mockUser.createdAt).thenReturn('2024-01-01T00:00:00Z');
      when(() => mockUser.userMetadata).thenReturn({});

      when(() => mockAuthResponse.user).thenReturn(mockUser);
      when(() => mockAuthResponse.session).thenReturn(mockSession);

      when(() => mockGoTrueClient.signUp(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockGoTrueClient.updateUser(any())).thenThrow(
        const AuthException('Failed to update metadata'),
      );

      // Act
      final result = await dataSource.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Assert - Should succeed despite metadata update failure
      expect(result, isA<AuthResponse>());
      expect(result.user, equals(mockUser));
    });
  });

  group('AuthRemoteDataSource - login()', () {
    const email = 'test@example.com';
    const password = 'password123';
    const userId = 'supabase-uuid-123';

    test('should return AuthResponse with user and session on successful login', () async {
      // Arrange
      final mockUser = MockUser();
      final mockSession = MockSession();
      final mockAuthResponse = MockAuthResponse();

      when(() => mockUser.id).thenReturn(userId);
      when(() => mockUser.email).thenReturn(email);
      when(() => mockUser.userMetadata).thenReturn({'full_name': 'John Doe'});

      when(() => mockAuthResponse.user).thenReturn(mockUser);
      when(() => mockAuthResponse.session).thenReturn(mockSession);

      when(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponse);

      // Act
      final result = await dataSource.login(
        email: email,
        password: password,
      );

      // Assert
      expect(result, isA<AuthResponse>());
      expect(result.user, equals(mockUser));
      expect(result.session, equals(mockSession));

      verify(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).called(1);
    });

    test('should throw InvalidCredentialsRemoteException for wrong password', () async {
      // Arrange
      when(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).thenThrow(
        const AuthException('Invalid login credentials'),
      );

      // Act & Assert
      expect(
        () => dataSource.login(
          email: email,
          password: password,
        ),
        throwsA(isA<InvalidCredentialsRemoteException>()),
      );
    });

    test('should throw UserNotFoundRemoteException when user does not exist', () async {
      // Arrange
      when(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).thenThrow(
        const AuthException('User not found'),
      );

      // Act & Assert
      expect(
        () => dataSource.login(
          email: email,
          password: password,
        ),
        throwsA(isA<UserNotFoundRemoteException>()),
      );
    });

    test('should throw TooManyRequestsRemoteException on rate limit', () async {
      // Arrange
      when(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).thenThrow(
        const AuthException('Too many requests'),
      );

      // Act & Assert
      expect(
        () => dataSource.login(
          email: email,
          password: password,
        ),
        throwsA(isA<TooManyRequestsRemoteException>()),
      );
    });

    test('should throw NetworkException on network error', () async {
      // Arrange
      when(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).thenThrow(
        Exception('Connection timeout'),
      );

      // Act & Assert
      expect(
        () => dataSource.login(
          email: email,
          password: password,
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw AuthRemoteException when user in response is null', () async {
      // Arrange
      final mockAuthResponse = MockAuthResponse();
      when(() => mockAuthResponse.user).thenReturn(null);

      when(() => mockGoTrueClient.signInWithPassword(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponse);

      // Act & Assert
      expect(
        () => dataSource.login(
          email: email,
          password: password,
        ),
        throwsA(
          isA<AuthRemoteException>().having(
            (e) => e.message,
            'message',
            contains('Login failed'),
          ),
        ),
      );
    });
  });

  group('AuthRemoteDataSource - logout()', () {
    test('should call signOut on successful logout', () async {
      // Arrange
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async => {});

      // Act
      await dataSource.logout();

      // Assert
      verify(() => mockGoTrueClient.signOut()).called(1);
    });

    test('should throw NetworkException on network error during logout', () async {
      // Arrange
      when(() => mockGoTrueClient.signOut()).thenThrow(
        Exception('Network unreachable'),
      );

      // Act & Assert
      expect(
        () => dataSource.logout(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should throw AuthRemoteException on Supabase error during logout', () async {
      // Arrange
      when(() => mockGoTrueClient.signOut()).thenThrow(
        const AuthException('Session expired'),
      );

      // Act & Assert
      expect(
        () => dataSource.logout(),
        throwsA(isA<AuthRemoteException>()),
      );
    });
  });

  group('AuthRemoteDataSource - getCurrentUser()', () {
    const userId = 'supabase-uuid-123';
    const email = 'test@example.com';

    test('should return User when user is authenticated', () async {
      // Arrange
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn(userId);
      when(() => mockUser.email).thenReturn(email);

      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);

      // Act
      final result = await dataSource.getCurrentUser();

      // Assert
      expect(result, equals(mockUser));
      expect(result?.id, equals(userId));
      expect(result?.email, equals(email));
    });

    test('should return null when no user is authenticated', () async {
      // Arrange
      when(() => mockGoTrueClient.currentUser).thenReturn(null);

      // Act
      final result = await dataSource.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('AuthRemoteDataSource - isSessionValid()', () {
    test('should return true when session exists', () async {
      // Arrange
      final mockSession = MockSession();
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);

      // Act
      final result = await dataSource.isSessionValid();

      // Assert
      expect(result, isTrue);
    });

    test('should return false when no session exists', () async {
      // Arrange
      when(() => mockGoTrueClient.currentSession).thenReturn(null);

      // Act
      final result = await dataSource.isSessionValid();

      // Assert
      expect(result, isFalse);
    });

    test('should return false when error occurs getting session', () async {
      // Arrange
      when(() => mockGoTrueClient.currentSession).thenThrow(
        Exception('Session error'),
      );

      // Act
      final result = await dataSource.isSessionValid();

      // Assert
      expect(result, isFalse);
    });
  });
}
