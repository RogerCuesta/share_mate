// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for authentication using Supabase Auth
///
/// This data source handles all authentication operations with Supabase backend.
/// It should be used in conjunction with the local data source for offline support.
///
/// Authentication Flow:
/// - Registration: Creates user in Supabase Auth + stores metadata
/// - Login: Authenticates with Supabase and creates JWT session
/// - Logout: Signs out from Supabase and clears session
/// - Session: Managed automatically by Supabase with JWT tokens
abstract class AuthRemoteDataSource {
  /// Register a new user with Supabase Auth
  ///
  /// Creates a new user account and stores the full name in user metadata.
  /// Returns AuthResponse containing both user and session.
  ///
  /// Throws:
  /// - [AuthRemoteException] if registration fails
  /// - [NetworkException] if network is unavailable
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  });

  /// Login user with email and password
  ///
  /// Authenticates the user and creates a Supabase session with JWT.
  /// Returns AuthResponse containing both user and session.
  ///
  /// Throws:
  /// - [AuthRemoteException] if login fails
  /// - [NetworkException] if network is unavailable
  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  /// Logout current user
  ///
  /// Signs out from Supabase and clears the session.
  ///
  /// Throws:
  /// - [AuthRemoteException] if logout fails
  Future<void> logout();

  /// Get currently authenticated user from Supabase
  ///
  /// Returns null if no user is authenticated.
  Future<User?> getCurrentUser();

  /// Check if current session is valid
  ///
  /// Returns true if there's an active Supabase session.
  Future<bool> isSessionValid();
}

/// Implementation of AuthRemoteDataSource using Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  const AuthRemoteDataSourceImpl({required SupabaseClient client}) : _client = client;

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // Check if user was created
      final user = response.user;
      if (user == null) {
        throw const AuthRemoteException(
          'Registration failed: User creation returned null',
          code: 'user_creation_failed',
        );
      }

      // Update user metadata with full name
      // This will be available in user.userMetadata['full_name']
      try {
        await _client.auth.updateUser(
          UserAttributes(
            data: {'full_name': fullName},
          ),
        );
      } catch (e) {
        // Log metadata update failure but don't fail registration
        // The user is already created, metadata can be updated later
        // In production, you might want to log this to a monitoring service
      }

      return response;
    } on AuthException catch (e) {
      // Map Supabase AuthException to our custom exception
      throw _mapAuthException(e);
    } catch (e) {
      // Handle network errors and other unexpected errors
      if (_isNetworkError(e)) {
        throw const NetworkException(
          'Network error during registration. Please check your connection.',
        );
      }
      throw AuthRemoteException(
        'Unexpected error during registration: ${e.toString()}',
        code: 'unknown_error',
      );
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthRemoteException(
          'Login failed: Authentication returned null user',
          code: 'login_failed',
        );
      }

      return response;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const NetworkException(
          'Network error during login. Please check your connection.',
        );
      }
      throw AuthRemoteException(
        'Unexpected error during login: ${e.toString()}',
        code: 'unknown_error',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (_isNetworkError(e)) {
        throw const NetworkException(
          'Network error during logout. Please check your connection.',
        );
      }
      throw AuthRemoteException(
        'Unexpected error during logout: ${e.toString()}',
        code: 'unknown_error',
      );
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return _client.auth.currentUser;
    } catch (e) {
      // Getting current user should not throw, but handle gracefully
      return null;
    }
  }

  @override
  Future<bool> isSessionValid() async {
    try {
      final session = _client.auth.currentSession;
      return session != null;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR MAPPING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Map Supabase AuthException to our custom exceptions
  AuthRemoteException _mapAuthException(AuthException e) {
    // Common Supabase error codes
    // See: https://supabase.com/docs/reference/javascript/auth-error-codes

    // Check error messages for specific cases (Supabase uses text messages, not always status codes)
    final message = e.message.toLowerCase();

    if (message.contains('email already') || message.contains('already registered')) {
      return EmailAlreadyInUseRemoteException(
        e.message,
        originalError: e,
      );
    }

    if (message.contains('invalid login') || message.contains('invalid credentials')) {
      return InvalidCredentialsRemoteException(
        e.message,
        originalError: e,
      );
    }

    if (message.contains('user not found')) {
      return UserNotFoundRemoteException(
        e.message,
        originalError: e,
      );
    }

    if (message.contains('password')) {
      return WeakPasswordRemoteException(
        e.message,
        originalError: e,
      );
    }

    if (message.contains('email')) {
      return InvalidEmailRemoteException(
        e.message,
        originalError: e,
      );
    }

    if (message.contains('rate limit') || message.contains('too many')) {
      return TooManyRequestsRemoteException(
        e.message,
        originalError: e,
      );
    }

    // Generic auth error
    return AuthRemoteException(
      e.message,
      code: e.statusCode ?? 'unknown',
      originalError: e,
    );
  }

  /// Check if error is network-related
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Base exception for remote authentication errors
class AuthRemoteException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  const AuthRemoteException(
    this.message, {
    this.code = 'auth_error',
    this.originalError,
  });

  @override
  String toString() => 'AuthRemoteException($code): $message';
}

/// Network connectivity exception
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Specific remote exceptions that map to domain failures

class EmailAlreadyInUseRemoteException extends AuthRemoteException {
  const EmailAlreadyInUseRemoteException(
    super.message, {
    super.originalError,
  }) : super(code: 'email_already_in_use');
}

class InvalidCredentialsRemoteException extends AuthRemoteException {
  const InvalidCredentialsRemoteException(
    super.message, {
    super.originalError,
  }) : super(code: 'invalid_credentials');
}

class UserNotFoundRemoteException extends AuthRemoteException {
  const UserNotFoundRemoteException(
    super.message, {
    super.originalError,
  }) : super(code: 'user_not_found');
}

class WeakPasswordRemoteException extends AuthRemoteException {
  const WeakPasswordRemoteException(
    super.message, {
    super.originalError,
  }) : super(code: 'weak_password');
}

class InvalidEmailRemoteException extends AuthRemoteException {
  const InvalidEmailRemoteException(
    super.message, {
    super.originalError,
  }) : super(code: 'invalid_email');
}

class TooManyRequestsRemoteException extends AuthRemoteException {
  const TooManyRequestsRemoteException(
    super.message, {
    super.originalError,
  }) : super(code: 'too_many_requests');
}
