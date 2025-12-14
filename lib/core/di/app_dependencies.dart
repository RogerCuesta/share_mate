// lib/core/di/app_dependencies.dart

/// Dependency Injection configuration for the entire app
///
/// This file is in the core layer and is responsible for wiring up
/// all dependencies. It's the ONLY place where we import from the data layer.
///
/// Clean Architecture layers:
/// - Domain: Pure business logic, no dependencies
/// - Data: Implementation details (Hive, API, etc.)
/// - Presentation: UI and state management
/// - Infrastructure/Core/DI: Wires everything together ✅ YOU ARE HERE
///
/// This approach keeps the Presentation layer clean and only dependent on Domain.
library;


import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
// ✅ Core can import from Data (implementation details)
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/repositories/auth_repository_impl.dart';
// ✅ And from Domain (interfaces and use cases)
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AUTH FEATURE - DEPENDENCY INJECTION
// ═══════════════════════════════════════════════════════════════════════════

/// Singleton instances for data sources
/// These are created once and reused throughout the app lifecycle
late final UserLocalDataSourceImpl _userLocalDataSource;
late final AuthLocalDataSourceImpl _authLocalDataSource;

/// Flag to track initialization
bool _isAuthDependenciesInitialized = false;

/// Initialize auth dependencies
///
/// Call this ONCE during app startup, after HiveService.init()
/// This ensures data sources are properly initialized before use.
Future<void> initAuthDependencies() async {
  if (_isAuthDependenciesInitialized) {
    return;
  }

  _userLocalDataSource = UserLocalDataSourceImpl();
  await _userLocalDataSource.init();

  _authLocalDataSource = AuthLocalDataSourceImpl();
  // AuthLocalDataSource doesn't need async init

  _isAuthDependenciesInitialized = true;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA SOURCES
// ─────────────────────────────────────────────────────────────────────────────

/// Provider for UserLocalDataSource (Hive)
///
/// This data source manages user data and credentials in Hive.
/// It MUST be initialized before use via initAuthDependencies().
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  if (!_isAuthDependenciesInitialized) {
    throw StateError(
      'Auth dependencies not initialized. '
      'Call initAuthDependencies() in main.dart before runApp().',
    );
  }
  return _userLocalDataSource;
});

/// Provider for AuthLocalDataSource (flutter_secure_storage)
///
/// This data source manages authentication sessions in secure storage.
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  if (!_isAuthDependenciesInitialized) {
    throw StateError(
      'Auth dependencies not initialized. '
      'Call initAuthDependencies() in main.dart before runApp().',
    );
  }
  return _authLocalDataSource;
});

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

/// Provider for AuthRepository implementation
///
/// This is the concrete implementation that coordinates between
/// UserLocalDataSource and AuthLocalDataSource.
///
/// Note: Presentation layer only knows about AuthRepository (interface),
/// not AuthRepositoryImpl (implementation).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    userDataSource: ref.watch(userLocalDataSourceProvider),
    authDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// USE CASES
// ─────────────────────────────────────────────────────────────────────────────

/// Use case: Register a new user
final registerUserProvider = Provider<RegisterUser>((ref) {
  return RegisterUser(ref.watch(authRepositoryProvider));
});

/// Use case: Login an existing user
final loginUserProvider = Provider<LoginUser>((ref) {
  return LoginUser(ref.watch(authRepositoryProvider));
});

/// Use case: Logout current user
final logoutUserProvider = Provider<LogoutUser>((ref) {
  return LogoutUser(ref.watch(authRepositoryProvider));
});

/// Use case: Get currently authenticated user
final getCurrentUserProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

/// Use case: Check if user is authenticated
final checkAuthStatusProvider = Provider<CheckAuthStatus>((ref) {
  return CheckAuthStatus(ref.watch(authRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════════
// FUTURE FEATURES - Add dependency injection here
// ═══════════════════════════════════════════════════════════════════════════

// Example:
// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTIONS FEATURE
// ─────────────────────────────────────────────────────────────────────────────
// final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
//   return SubscriptionRepositoryImpl(...);
// });
