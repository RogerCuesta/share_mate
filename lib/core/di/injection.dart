// lib/core/di/injection.dart

import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'injection.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SUPABASE CLIENT
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for SupabaseClient
///
/// Provides access to the initialized Supabase client.
/// Requires SupabaseService.init() to be called first in main.dart.
@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return SupabaseService.client;
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH FEATURE - DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for UserLocalDataSource (Hive)
///
/// This data source manages user data and credentials in Hive.
/// It MUST be initialized before use via initAuthDependencies().
///
/// Note: This is a singleton that persists across provider rebuilds.
@Riverpod(keepAlive: true)
UserLocalDataSource userLocalDataSource(Ref ref) {
  throw UnimplementedError(
    'userLocalDataSource provider must be overridden in main.dart with the initialized instance',
  );
}

/// Provider for AuthLocalDataSource (flutter_secure_storage)
///
/// This data source manages authentication sessions in secure storage.
///
/// Note: This is a singleton that persists across provider rebuilds.
@Riverpod(keepAlive: true)
AuthLocalDataSource authLocalDataSource(Ref ref) {
  throw UnimplementedError(
    'authLocalDataSource provider must be overridden in main.dart with the initialized instance',
  );
}

/// Provider for AuthRemoteDataSource (Supabase)
///
/// This data source manages authentication with Supabase backend.
/// Requires SupabaseService to be initialized.
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRemoteDataSourceImpl(client: client);
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH FEATURE - REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for AuthRepository implementation
///
/// This is the concrete implementation that coordinates between:
/// - AuthRemoteDataSource (Supabase) for remote authentication
/// - UserLocalDataSource (Hive) for local user data
/// - AuthLocalDataSource (flutter_secure_storage) for sessions
///
/// Note: Presentation layer only knows about AuthRepository (interface),
/// not AuthRepositoryImpl (implementation).
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    userDataSource: ref.watch(userLocalDataSourceProvider),
    authDataSource: ref.watch(authLocalDataSourceProvider),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH FEATURE - USE CASES
// ═══════════════════════════════════════════════════════════════════════════

/// Use case: Register a new user
@riverpod
RegisterUser registerUser(Ref ref) {
  return RegisterUser(ref.watch(authRepositoryProvider));
}

/// Use case: Login an existing user
@riverpod
LoginUser loginUser(Ref ref) {
  return LoginUser(ref.watch(authRepositoryProvider));
}

/// Use case: Logout current user
@riverpod
LogoutUser logoutUser(Ref ref) {
  return LogoutUser(ref.watch(authRepositoryProvider));
}

/// Use case: Get currently authenticated user
@riverpod
GetCurrentUser getCurrentUser(Ref ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
}

/// Use case: Check if user is authenticated
@riverpod
CheckAuthStatus checkAuthStatus(Ref ref) {
  return CheckAuthStatus(ref.watch(authRepositoryProvider));
}

// ═══════════════════════════════════════════════════════════════════════════
// FUTURE FEATURES - Add providers here
// ═══════════════════════════════════════════════════════════════════════════

// Example:
// @riverpod
// SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
//   return SubscriptionRepositoryImpl(...);
// }
