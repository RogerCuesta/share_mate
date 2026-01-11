// lib/features/auth/domain/usecases/check_auth_status.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';

/// Use case for checking if there's an active authentication session
///
/// This use case verifies if the user is currently authenticated.
/// Useful for app initialization and navigation guards.
///
/// Usage:
/// ```dart
/// final result = await checkAuthStatus();
/// result.fold(
///   (failure) => debugPrint('Error checking auth: $failure'),
///   (isAuthenticated) => debugPrint('Is authenticated: $isAuthenticated'),
/// );
/// ```
class CheckAuthStatus {

  CheckAuthStatus(this.repository);
  final AuthRepository repository;

  /// Execute the check auth status use case
  ///
  /// Delegates to repository which handles:
  /// - Checking if session exists in secure storage
  /// - Validating session hasn't expired
  ///
  /// Returns:
  /// - Right(true): User is authenticated with valid session
  /// - Right(false): No valid session found
  /// - Left(AuthFailure): Error occurred while checking
  Future<Either<AuthFailure, bool>> call() async {
    return repository.checkAuthStatus();
  }
}
