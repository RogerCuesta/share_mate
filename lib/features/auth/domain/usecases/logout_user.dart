// lib/features/auth/domain/usecases/logout_user.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';

/// Use case for logging out the current user
///
/// This use case clears the authentication session.
///
/// Usage:
/// ```dart
/// final result = await logoutUser();
/// result.fold(
///   (failure) => print('Logout failed: $failure'),
///   (_) => print('Logged out successfully'),
/// );
/// ```
class LogoutUser {

  LogoutUser(this.repository);
  final AuthRepository repository;

  /// Execute the logout use case
  ///
  /// Delegates to repository which handles:
  /// - Clearing session from secure storage
  /// - Any cleanup operations
  Future<Either<AuthFailure, Unit>> call() async {
    return repository.logoutUser();
  }
}
