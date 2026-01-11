// lib/features/settings/data/datasources/account_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Account Remote Data Source Interface
abstract class AccountRemoteDataSource {
  Future<void> changePassword({required String newPassword});
  Future<void> sendEmailVerification();
  Future<bool> checkEmailVerified();
  Future<void> deleteAccount(String userId);
}

/// Account Remote Data Source Implementation (Supabase Auth)
class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {

  AccountRemoteDataSourceImpl({required this.client});
  final SupabaseClient client;

  @override
  Future<void> changePassword({required String newPassword}) async {
    try {
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AccountRemoteException('Failed to change password: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw AccountRemoteException('No authenticated user');
      }

      // Resend email verification
      await client.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
    } catch (e) {
      throw AccountRemoteException('Failed to send verification email: $e');
    }
  }

  @override
  Future<bool> checkEmailVerified() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw AccountRemoteException('No authenticated user');
      }

      // Check if email is confirmed
      return user.emailConfirmedAt != null;
    } catch (e) {
      throw AccountRemoteException('Failed to check email verification: $e');
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      // Delete user via Supabase Admin API
      // This will CASCADE delete all related data (profiles, subscriptions, etc.)
      await client.auth.admin.deleteUser(userId);
    } catch (e) {
      throw AccountRemoteException('Failed to delete account: $e');
    }
  }
}

/// Exception thrown when account remote operations fail
class AccountRemoteException implements Exception {
  AccountRemoteException(this.message);
  final String message;

  @override
  String toString() => message;
}
