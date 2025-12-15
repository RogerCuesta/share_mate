// lib/features/auth/presentation/providers/login_form_provider.dart

import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_provider.freezed.dart';

/// Login form state
@freezed
class LoginFormState with _$LoginFormState {
  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isLoading,
    String? errorMessage,
    AuthSession? session,
  }) = _LoginFormState;
}

/// Login form notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {

  LoginFormNotifier({
    required this.loginUser,
  }) : super(const LoginFormState());
  final LoginUser loginUser;

  /// Update email field
  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  /// Update password field
  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  /// Validate form fields
  String? validateEmail() {
    if (state.email.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(state.email)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? validatePassword() {
    if (state.password.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  /// Submit login form
  Future<bool> submit() async {
    // Validate
    final emailError = validateEmail();
    final passwordError = validatePassword();

    if (emailError != null) {
      state = state.copyWith(errorMessage: emailError);
      return false;
    }

    if (passwordError != null) {
      state = state.copyWith(errorMessage: passwordError);
      return false;
    }

    // Submit
    state = state.copyWith(isLoading: true, errorMessage: null);

    final params = LoginUserParams(
      email: state.email,
      password: state.password,
    );

    final result = await loginUser(params);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (session) {
        state = state.copyWith(
          isLoading: false,
          session: session,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  /// Reset form
  void reset() {
    state = const LoginFormState();
  }
}

/// Provider for login form
final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier(
    loginUser: ref.watch(loginUserProvider),
  );
});
