// lib/features/settings/presentation/providers/account_actions_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/failures/settings_failure.dart';

part 'account_actions_provider.g.dart';

/// Account Actions State
///
/// Represents the state of account-related operations
/// (password change, email verification, account deletion)
sealed class AccountActionState {
  const AccountActionState();
}

class AccountActionIdle extends AccountActionState {
  const AccountActionIdle();
}

class AccountActionLoading extends AccountActionState {
  const AccountActionLoading();
}

class AccountActionSuccess extends AccountActionState {
  final String message;
  const AccountActionSuccess(this.message);
}

class AccountActionError extends AccountActionState {
  final String message;
  const AccountActionError(this.message);
}

/// Account Actions Provider
///
/// Manages account-related operations like password changes,
/// email verification, and account deletion.
@riverpod
class AccountActions extends _$AccountActions {
  @override
  AccountActionState build() {
    return const AccountActionIdle();
  }

  /// Change password
  Future<bool> changePassword(String newPassword) async {
    state = const AccountActionLoading();

    final changePassword = ref.read(changePasswordProvider);
    final result = await changePassword(newPassword: newPassword);

    return result.fold(
      (failure) {
        state = AccountActionError(_getErrorMessage(failure));
        return false;
      },
      (_) {
        state = const AccountActionSuccess('Password changed successfully');
        // Reset to idle after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (state is AccountActionSuccess) {
            state = const AccountActionIdle();
          }
        });
        return true;
      },
    );
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    state = const AccountActionLoading();

    final sendVerification = ref.read(sendEmailVerificationProvider);
    final result = await sendVerification();

    return result.fold(
      (failure) {
        state = AccountActionError(_getErrorMessage(failure));
        return false;
      },
      (_) {
        state = const AccountActionSuccess(
          'Verification email sent. Please check your inbox.',
        );
        // Reset to idle after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (state is AccountActionSuccess) {
            state = const AccountActionIdle();
          }
        });
        return true;
      },
    );
  }

  /// Delete account
  Future<bool> deleteAccount(String userId) async {
    state = const AccountActionLoading();

    final deleteAccount = ref.read(deleteAccountProvider);
    final result = await deleteAccount(userId);

    return result.fold(
      (failure) {
        state = AccountActionError(_getErrorMessage(failure));
        return false;
      },
      (_) {
        state = const AccountActionSuccess('Account deleted successfully');
        return true;
      },
    );
  }

  /// Reset state to idle
  void resetState() {
    state = const AccountActionIdle();
  }

  /// Extract error message from failure
  String _getErrorMessage(SettingsFailure failure) {
    return failure.when(
      profileUpdateError: (msg) => msg,
      avatarUploadError: (msg) => msg,
      avatarDeleteError: (msg) => msg,
      settingsSaveError: (msg) => msg,
      passwordChangeError: (msg) => msg,
      accountDeletionError: (msg) => msg,
      networkError: () => 'Network error. Please check your connection.',
      storageError: (msg) => msg,
      validationError: (msg) => msg,
      fileTooLarge: (maxSizeMB) => 'File too large (max ${maxSizeMB}MB)',
      invalidFileType: (acceptedTypes) => 'Invalid file type. Accepted: $acceptedTypes',
      emailVerificationError: (msg) => msg,
    );
  }
}

/// Email Verification Status Provider
///
/// Checks if the current user's email is verified.
@riverpod
Future<bool> emailVerificationStatus(EmailVerificationStatusRef ref) async {
  // This will be implemented when we integrate with Supabase Auth
  // For now, return false as placeholder
  return false;
}
