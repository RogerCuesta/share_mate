// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';

/// Abstract repository defining authentication operations
///
/// This interface belongs to the domain layer and defines the contract
/// for authentication operations. The actual implementation lives in the
/// data layer.
///
/// Uses Either<Failure, Success> for functional error handling:
/// - Left: Contains the failure/error
/// - Right: Contains the successful result
abstract class AuthRepository {
  /// Register a new user with email and password
  ///
  /// Validates that:
  /// - Email is not already registered
  /// - Email format is valid
  /// - Password meets security requirements (min 8 chars)
  /// - Full name is not empty
  ///
  /// Returns:
  /// - Right(User): Registration successful
  /// - Left(AuthFailure): Registration failed (email exists, validation error, etc.)
  Future<Either<AuthFailure, User>> registerUser({
    required String email,
    required String password,
    required String fullName,
  });

  /// Login user with email and password
  ///
  /// Validates credentials and creates a new session.
  ///
  /// Returns:
  /// - Right(AuthSession): Login successful, session created
  /// - Left(AuthFailure): Login failed (invalid credentials, user not found, etc.)
  Future<Either<AuthFailure, AuthSession>> loginUser({
    required String email,
    required String password,
  });

  /// Logout current user
  ///
  /// Clears the current session from secure storage.
  ///
  /// Returns:
  /// - Right(Unit): Logout successful
  /// - Left(AuthFailure): Logout failed
  Future<Either<AuthFailure, Unit>> logoutUser();

  /// Get currently authenticated user
  ///
  /// Retrieves user data from local storage.
  ///
  /// Returns:
  /// - Right(User): User found
  /// - Left(AuthFailure): No authenticated user or user not found
  Future<Either<AuthFailure, User>> getCurrentUser();

  /// Check if there's an active authentication session
  ///
  /// Validates that:
  /// - A session exists in secure storage
  /// - The session has not expired
  ///
  /// Returns:
  /// - Right(true): Valid session exists
  /// - Right(false): No valid session
  /// - Left(AuthFailure): Error checking session
  Future<Either<AuthFailure, bool>> checkAuthStatus();

  /// Get current session information
  ///
  /// Returns:
  /// - Right(AuthSession): Session found and valid
  /// - Left(AuthFailure): No session or session invalid
  Future<Either<AuthFailure, AuthSession>> getCurrentSession();

  /// Validate email format (domain logic)
  ///
  /// This is a synchronous validation that can be used in the UI layer.
  bool isValidEmail(String email);

  /// Validate password requirements (domain logic)
  ///
  /// Password must:
  /// - Be at least 8 characters long
  /// - (Future: Add more requirements like uppercase, numbers, etc.)
  bool isValidPassword(String password);
}

/// Base class for authentication failures
///
/// All authentication-related errors extend this class.
abstract class AuthFailure {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// User registration failures
class EmailAlreadyExistsFailure extends AuthFailure {
  const EmailAlreadyExistsFailure() : super('This email is already registered');
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('Invalid email format');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('Password must be at least 8 characters');
}

class EmptyFieldFailure extends AuthFailure {
  EmptyFieldFailure(this.fieldName) : super('$fieldName cannot be empty');
  final String fieldName;
}

/// Login failures
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Invalid email or password');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('User not found');
}

/// Session failures
class NoActiveSessionFailure extends AuthFailure {
  const NoActiveSessionFailure() : super('No active session found');
}

class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure() : super('Session has expired');
}

/// Generic failures
class StorageFailure extends AuthFailure {
  const StorageFailure([String? customMessage])
      : super(customMessage ?? 'Failed to access storage');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([String? customMessage])
      : super(customMessage ?? 'An unknown error occurred');
}
