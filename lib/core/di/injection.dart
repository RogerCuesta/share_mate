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
import 'package:flutter_project_agents/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:flutter_project_agents/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:flutter_project_agents/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:flutter_project_agents/features/contacts/domain/repositories/contact_repository.dart';
import 'package:flutter_project_agents/features/contacts/domain/usecases/add_contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/usecases/delete_contact.dart';
import 'package:flutter_project_agents/features/contacts/domain/usecases/get_my_contacts.dart';
import 'package:flutter_project_agents/features/contacts/domain/usecases/update_contact.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/account_remote_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/profile_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_project_agents/features/settings/data/repositories/account_repository_impl.dart';
import 'package:flutter_project_agents/features/settings/data/repositories/profile_repository_impl.dart';
import 'package:flutter_project_agents/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/account_repository.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/profile_repository.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/change_password.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/delete_account.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/delete_avatar.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/get_profile.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/save_settings.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/send_email_verification.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/update_profile.dart';
import 'package:flutter_project_agents/features/settings/domain/usecases/upload_avatar.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/create_subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_active_subscriptions.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_analytics_data.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_pending_payments.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_subscription_details.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_all_payments_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_payment_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/unmark_payment.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/update_subscription.dart';
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
// SUBSCRIPTIONS FEATURE - DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for SubscriptionLocalDataSource (Hive)
///
/// This data source manages subscription and member data in Hive cache.
/// It MUST be initialized before use via initSubscriptionsDependencies().
///
/// Note: This is a singleton that persists across provider rebuilds.
@Riverpod(keepAlive: true)
SubscriptionLocalDataSource subscriptionLocalDataSource(Ref ref) {
  throw UnimplementedError(
    'subscriptionLocalDataSource provider must be overridden in main.dart with the initialized instance',
  );
}

/// Provider for SubscriptionRemoteDataSource (Supabase)
///
/// This data source manages subscription operations with Supabase backend.
/// Requires SupabaseService to be initialized.
@riverpod
SubscriptionRemoteDataSource subscriptionRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return SubscriptionRemoteDataSourceImpl(client: client);
}

// ═══════════════════════════════════════════════════════════════════════════
// SUBSCRIPTIONS FEATURE - REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for SubscriptionRepository implementation
///
/// **PRODUCTION MODE**: Using real Supabase backend with offline-first strategy.
///
/// The implementation coordinates between:
/// - SubscriptionRemoteDataSource (Supabase) for remote operations
/// - SubscriptionLocalDataSource (Hive) for local cache
///
/// Implements offline-first strategy: tries Supabase first, falls back to cache.
@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  // ============================================================================
  // REAL REPOSITORY - Production Implementation (ACTIVE)
  // ============================================================================
  return SubscriptionRepositoryImpl(
    remoteDataSource: ref.watch(subscriptionRemoteDataSourceProvider),
    localDataSource: ref.watch(subscriptionLocalDataSourceProvider),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SUBSCRIPTIONS FEATURE - USE CASES
// ═══════════════════════════════════════════════════════════════════════════

/// Use case: Get monthly statistics
@riverpod
GetMonthlyStats getMonthlyStats(Ref ref) {
  return GetMonthlyStats(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Get payment statistics
@riverpod
GetPaymentStats getPaymentStats(Ref ref) {
  return GetPaymentStats(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Get active subscriptions
@riverpod
GetActiveSubscriptions getActiveSubscriptions(Ref ref) {
  return GetActiveSubscriptions(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Get pending payments
@riverpod
GetPendingPayments getPendingPayments(Ref ref) {
  return GetPendingPayments(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Get subscription details
@riverpod
GetSubscriptionDetails getSubscriptionDetails(Ref ref) {
  return GetSubscriptionDetails(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Create subscription
@riverpod
CreateSubscription createSubscription(Ref ref) {
  return CreateSubscription(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Update subscription
@riverpod
UpdateSubscription updateSubscription(Ref ref) {
  return UpdateSubscription(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Delete subscription
@riverpod
DeleteSubscription deleteSubscription(Ref ref) {
  return DeleteSubscription(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Mark payment as paid
@riverpod
MarkPaymentAsPaid markPaymentAsPaid(Ref ref) {
  return MarkPaymentAsPaid(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Mark all payments as paid
@riverpod
MarkAllPaymentsAsPaid markAllPaymentsAsPaid(Ref ref) {
  return MarkAllPaymentsAsPaid(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Unmark payment
@riverpod
UnmarkPayment unmarkPayment(Ref ref) {
  return UnmarkPayment(ref.watch(subscriptionRepositoryProvider));
}

/// Use case: Get analytics data
@riverpod
GetAnalyticsData getAnalyticsData(Ref ref) {
  return GetAnalyticsData(ref.watch(subscriptionRepositoryProvider));
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTACTS FEATURE - DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for ContactLocalDataSource (Hive)
///
/// This data source manages contact data in Hive cache.
/// Simple instantiation - no initialization required.
@riverpod
ContactLocalDataSource contactLocalDataSource(Ref ref) {
  return const ContactLocalDataSource();
}

/// Provider for ContactRemoteDataSource (Supabase)
///
/// This data source manages contact operations with Supabase backend.
/// Requires SupabaseService to be initialized.
@riverpod
ContactRemoteDataSource contactRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return ContactRemoteDataSource(client);
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTACTS FEATURE - REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for ContactRepository implementation
///
/// The implementation coordinates between:
/// - ContactRemoteDataSource (Supabase) for remote operations
/// - ContactLocalDataSource (Hive) for local cache
///
/// Implements offline-first strategy: tries Supabase first, falls back to cache.
@riverpod
ContactRepository contactRepository(Ref ref) {
  return ContactRepositoryImpl(
    ref.watch(contactRemoteDataSourceProvider),
    ref.watch(contactLocalDataSourceProvider),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTACTS FEATURE - USE CASES
// ═══════════════════════════════════════════════════════════════════════════

/// Use case: Get my contacts
@riverpod
GetMyContacts getMyContacts(Ref ref) {
  return GetMyContacts(ref.watch(contactRepositoryProvider));
}

/// Use case: Add contact
@riverpod
AddContact addContact(Ref ref) {
  return AddContact(ref.watch(contactRepositoryProvider));
}

/// Use case: Update contact
@riverpod
UpdateContact updateContact(Ref ref) {
  return UpdateContact(ref.watch(contactRepositoryProvider));
}

/// Use case: Delete contact
@riverpod
DeleteContact deleteContact(Ref ref) {
  return DeleteContact(ref.watch(contactRepositoryProvider));
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS FEATURE - DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for ProfileLocalDataSource (Hive)
///
/// This data source manages user profile data in Hive cache.
/// It MUST be initialized before use via initSettingsDependencies().
///
/// Note: This is a singleton that persists across provider rebuilds.
@Riverpod(keepAlive: true)
ProfileLocalDataSource profileLocalDataSource(Ref ref) {
  throw UnimplementedError(
    'profileLocalDataSource provider must be overridden in main.dart with the initialized instance',
  );
}

/// Provider for SettingsLocalDataSource (Hive)
///
/// This data source manages app settings data in Hive cache.
/// It MUST be initialized before use via initSettingsDependencies().
///
/// Note: This is a singleton that persists across provider rebuilds.
@Riverpod(keepAlive: true)
SettingsLocalDataSource settingsLocalDataSource(Ref ref) {
  throw UnimplementedError(
    'settingsLocalDataSource provider must be overridden in main.dart with the initialized instance',
  );
}

/// Provider for ProfileRemoteDataSource (Supabase)
///
/// This data source manages profile operations with Supabase backend.
/// Requires SupabaseService to be initialized.
@riverpod
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRemoteDataSourceImpl(client: client);
}

/// Provider for AccountRemoteDataSource (Supabase Auth)
///
/// This data source manages account operations with Supabase Auth.
/// Requires SupabaseService to be initialized.
@riverpod
AccountRemoteDataSource accountRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return AccountRemoteDataSourceImpl(client: client);
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS FEATURE - REPOSITORIES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for ProfileRepository implementation
///
/// The implementation coordinates between:
/// - ProfileRemoteDataSource (Supabase) for remote operations
/// - ProfileLocalDataSource (Hive) for local cache
///
/// Implements offline-first strategy: tries Supabase first, falls back to cache.
@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
  );
}

/// Provider for SettingsRepository implementation
///
/// The implementation manages app settings in local storage only.
/// Settings are persisted in Hive and do not sync to Supabase.
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepositoryImpl(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
  );
}

/// Provider for AccountRepository implementation
///
/// The implementation manages account operations via Supabase Auth.
/// Handles password changes, email verification, and account deletion.
@riverpod
AccountRepository accountRepository(Ref ref) {
  return AccountRepositoryImpl(
    remoteDataSource: ref.watch(accountRemoteDataSourceProvider),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS FEATURE - USE CASES
// ═══════════════════════════════════════════════════════════════════════════

/// Use case: Get user profile
@riverpod
GetProfile getProfile(Ref ref) {
  return GetProfile(ref.watch(profileRepositoryProvider));
}

/// Use case: Update user profile
@riverpod
UpdateProfile updateProfile(Ref ref) {
  return UpdateProfile(ref.watch(profileRepositoryProvider));
}

/// Use case: Upload avatar
@riverpod
UploadAvatar uploadAvatar(Ref ref) {
  return UploadAvatar(ref.watch(profileRepositoryProvider));
}

/// Use case: Delete avatar
@riverpod
DeleteAvatar deleteAvatar(Ref ref) {
  return DeleteAvatar(ref.watch(profileRepositoryProvider));
}

/// Use case: Get app settings
@riverpod
GetSettings getSettings(Ref ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
}

/// Use case: Save app settings
@riverpod
SaveSettings saveSettings(Ref ref) {
  return SaveSettings(ref.watch(settingsRepositoryProvider));
}

/// Use case: Change password
@riverpod
ChangePassword changePassword(Ref ref) {
  return ChangePassword(ref.watch(accountRepositoryProvider));
}

/// Use case: Send email verification
@riverpod
SendEmailVerification sendEmailVerification(Ref ref) {
  return SendEmailVerification(ref.watch(accountRepositoryProvider));
}

/// Use case: Delete account
@riverpod
DeleteAccount deleteAccount(Ref ref) {
  return DeleteAccount(ref.watch(accountRepositoryProvider));
}
