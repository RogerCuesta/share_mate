// lib/features/auth/domain/usecases/login_user.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';

/// Use case for logging in a user
///
/// This use case encapsulates the business logic for user login.
/// It validates input and delegates authentication to the repository.
///
/// Usage:
/// ```dart
/// final result = await loginUser(params);
/// result.fold(
///   (failure) => print('Login failed: $failure'),
///   (session) => print('Logged in, token: ${session.token}'),
/// );
/// ```
class LoginUser {

  LoginUser(this.repository);
  final AuthRepository repository;

  /// Execute the login use case
  ///
  /// Performs domain-level validation before calling the repository:
  /// 1. Validates email and password are not empty
  /// 2. Validates email format
  ///
  /// Then delegates to repository which handles:
  /// - Verifying credentials
  /// - Creating authentication session
  /// - Storing session in secure storage
  Future<Either<AuthFailure, AuthSession>> call(LoginUserParams params) async {
    // Domain validation: Empty fields
    if (params.email.trim().isEmpty) {
      return Left(EmptyFieldFailure('Email'));
    }
    if (params.password.isEmpty) {
      return Left(EmptyFieldFailure('Password'));
    }

    // Domain validation: Email format
    if (!repository.isValidEmail(params.email)) {
      return const Left(InvalidEmailFailure());
    }

    // Delegate to repository for authentication
    return repository.loginUser(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}

/// Parameters for LoginUser use case
class LoginUserParams {

  LoginUserParams({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;
}
