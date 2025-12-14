// lib/features/auth/domain/usecases/register_user.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';

/// Use case for registering a new user
///
/// This use case encapsulates the business logic for user registration.
/// It validates input and delegates the actual registration to the repository.
///
/// Usage:
/// ```dart
/// final result = await registerUser(params);
/// result.fold(
///   (failure) => print('Registration failed: $failure'),
///   (user) => print('User registered: ${user.email}'),
/// );
/// ```
class RegisterUser {

  RegisterUser(this.repository);
  final AuthRepository repository;

  /// Execute the registration use case
  ///
  /// Performs domain-level validation before calling the repository:
  /// 1. Validates email format
  /// 2. Validates password strength
  /// 3. Validates that required fields are not empty
  ///
  /// Then delegates to repository which handles:
  /// - Checking if email already exists
  /// - Hashing the password
  /// - Storing user data
  Future<Either<AuthFailure, User>> call(RegisterUserParams params) async {
    // Domain validation: Empty fields
    if (params.email.trim().isEmpty) {
      return Left(EmptyFieldFailure('Email'));
    }
    if (params.password.isEmpty) {
      return Left(EmptyFieldFailure('Password'));
    }
    if (params.fullName.trim().isEmpty) {
      return Left(EmptyFieldFailure('Full name'));
    }

    // Domain validation: Email format
    if (!repository.isValidEmail(params.email)) {
      return const Left(InvalidEmailFailure());
    }

    // Domain validation: Password strength
    if (!repository.isValidPassword(params.password)) {
      return const Left(WeakPasswordFailure());
    }

    // Delegate to repository for actual registration
    return repository.registerUser(
      email: params.email.trim().toLowerCase(),
      password: params.password,
      fullName: params.fullName.trim(),
    );
  }
}

/// Parameters for RegisterUser use case
class RegisterUserParams {

  RegisterUserParams({
    required this.email,
    required this.password,
    required this.fullName,
  });
  final String email;
  final String password;
  final String fullName;
}
