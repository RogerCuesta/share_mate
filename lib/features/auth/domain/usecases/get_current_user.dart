// lib/features/auth/domain/usecases/get_current_user.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';

/// Use case for getting the currently authenticated user
///
/// This use case retrieves the user data for the current session.
///
/// Usage:
/// ```dart
/// final result = await getCurrentUser();
/// result.fold(
///   (failure) => print('No user logged in: $failure'),
///   (user) => print('Current user: ${user.email}'),
/// );
/// ```
class GetCurrentUser {

  GetCurrentUser(this.repository);
  final AuthRepository repository;

  /// Execute the get current user use case
  ///
  /// Delegates to repository which handles:
  /// - Retrieving user data from local storage
  /// - Validating user data
  Future<Either<AuthFailure, User>> call() async {
    return repository.getCurrentUser();
  }
}
