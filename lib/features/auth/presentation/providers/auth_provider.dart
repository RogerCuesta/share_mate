// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:flutter_project_agents/core/di/app_dependencies.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/check_auth_status.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_provider.freezed.dart';

/// Authentication state
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

/// Auth provider that manages global authentication state
class AuthNotifier extends StateNotifier<AuthState> {

  AuthNotifier({
    required this.checkAuthStatus,
    required this.getCurrentUser,
    required this.logoutUser,
  }) : super(const AuthState.initial());
  final CheckAuthStatus checkAuthStatus;
  final GetCurrentUser getCurrentUser;
  final LogoutUser logoutUser;

  /// Check authentication status on app start
  Future<void> checkAuth() async {
    state = const AuthState.loading();

    final result = await checkAuthStatus();
    await result.fold(
      (failure) async {
        state = AuthState.error(failure.message);
      },
      (isAuthenticated) async {
        if (isAuthenticated) {
          await _loadUser();
        } else {
          state = const AuthState.unauthenticated();
        }
      },
    );
  }

  /// Load current user data
  Future<void> _loadUser() async {
    final result = await getCurrentUser();
    result.fold(
      (failure) {
        state = AuthState.error(failure.message);
      },
      (user) {
        state = AuthState.authenticated(user);
      },
    );
  }

  /// Set authenticated state after successful login/registration
  void setAuthenticated(User user) {
    state = AuthState.authenticated(user);
  }

  /// Logout user
  Future<void> logout() async {
    state = const AuthState.loading();

    final result = await logoutUser();
    result.fold(
      (failure) {
        state = AuthState.error(failure.message);
      },
      (_) {
        state = const AuthState.unauthenticated();
      },
    );
  }
}

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    checkAuthStatus: ref.watch(checkAuthStatusProvider),
    getCurrentUser: ref.watch(getCurrentUserProvider),
    logoutUser: ref.watch(logoutUserProvider),
  );
});
