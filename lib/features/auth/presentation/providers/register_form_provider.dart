// lib/features/auth/presentation/providers/register_form_provider.dart

import 'package:flutter_project_agents/core/di/app_dependencies.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_form_provider.freezed.dart';

/// Register form state
@freezed
class RegisterFormState with _$RegisterFormState {
  const factory RegisterFormState({
    @Default('') String email,
    @Default('') String password,
    @Default('') String confirmPassword,
    @Default('') String fullName,
    @Default(false) bool isLoading,
    String? errorMessage,
    User? user,
  }) = _RegisterFormState;
}

/// Register form notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {

  RegisterFormNotifier({
    required this.registerUser,
  }) : super(const RegisterFormState());
  final RegisterUser registerUser;

  /// Update email field
  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  /// Update password field
  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  /// Update confirm password field
  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword, errorMessage: null);
  }

  /// Update full name field
  void updateFullName(String fullName) {
    state = state.copyWith(fullName: fullName, errorMessage: null);
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
    if (state.password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? validateConfirmPassword() {
    if (state.confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (state.password != state.confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateFullName() {
    if (state.fullName.trim().isEmpty) {
      return 'Full name is required';
    }
    if (state.fullName.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  /// Submit registration form
  Future<bool> submit() async {
    // Validate all fields
    final emailError = validateEmail();
    final passwordError = validatePassword();
    final confirmPasswordError = validateConfirmPassword();
    final fullNameError = validateFullName();

    if (emailError != null) {
      state = state.copyWith(errorMessage: emailError);
      return false;
    }

    if (passwordError != null) {
      state = state.copyWith(errorMessage: passwordError);
      return false;
    }

    if (confirmPasswordError != null) {
      state = state.copyWith(errorMessage: confirmPasswordError);
      return false;
    }

    if (fullNameError != null) {
      state = state.copyWith(errorMessage: fullNameError);
      return false;
    }

    // Submit
    state = state.copyWith(isLoading: true, errorMessage: null);

    final params = RegisterUserParams(
      email: state.email,
      password: state.password,
      fullName: state.fullName,
    );

    final result = await registerUser(params);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  /// Reset form
  void reset() {
    state = const RegisterFormState();
  }
}

/// Provider for register form
final registerFormProvider =
    StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((ref) {
  return RegisterFormNotifier(
    registerUser: ref.watch(registerUserProvider),
  );
});
