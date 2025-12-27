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
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/create_subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_active_subscriptions.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_monthly_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_payment_stats.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_pending_payments.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/get_subscription_details.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_all_payments_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/mark_payment_as_paid.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/unmark_payment.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/usecases/update_subscription.dart';
import 'package:flutter_project_agents/features/friends/data/datasources/friendship_local_datasource.dart';
import 'package:flutter_project_agents/features/friends/data/datasources/friendship_remote_datasource.dart';
import 'package:flutter_project_agents/features/friends/data/repositories/friendship_repository_impl.dart';
import 'package:flutter_project_agents/features/friends/domain/repositories/friendship_repository.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/accept_friend_request.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/get_friends.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/get_pending_requests.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/reject_friend_request.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/remove_friend.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/search_users.dart';
import 'package:flutter_project_agents/features/friends/domain/usecases/send_friend_request.dart';
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

// ═══════════════════════════════════════════════════════════════════════════
// FRIENDS FEATURE - DATA SOURCES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for FriendshipLocalDataSource (Hive)
///
/// This data source manages friendship and profile data in Hive cache.
/// It MUST be initialized before use via initFriendsDependencies().
///
/// Note: This is a singleton that persists across provider rebuilds.
@Riverpod(keepAlive: true)
FriendshipLocalDataSource friendshipLocalDataSource(Ref ref) {
  throw UnimplementedError(
    'friendshipLocalDataSource provider must be overridden in main.dart with the initialized instance',
  );
}

/// Provider for FriendshipRemoteDataSource (Supabase)
///
/// This data source manages friendship operations with Supabase backend.
/// Requires SupabaseService to be initialized.
@riverpod
FriendshipRemoteDataSource friendshipRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return FriendshipRemoteDataSourceImpl(client: client);
}

// ═══════════════════════════════════════════════════════════════════════════
// FRIENDS FEATURE - REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for FriendshipRepository implementation
///
/// The implementation coordinates between:
/// - FriendshipRemoteDataSource (Supabase) for remote operations
/// - FriendshipLocalDataSource (Hive) for local cache
///
/// Implements offline-first strategy: tries Supabase first, falls back to cache.
@riverpod
FriendshipRepository friendshipRepository(Ref ref) {
  return FriendshipRepositoryImpl(
    remoteDataSource: ref.watch(friendshipRemoteDataSourceProvider),
    localDataSource: ref.watch(friendshipLocalDataSourceProvider),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// FRIENDS FEATURE - USE CASES
// ═══════════════════════════════════════════════════════════════════════════

/// Use case: Send friend request
@riverpod
SendFriendRequest sendFriendRequest(Ref ref) {
  return SendFriendRequest(ref.watch(friendshipRepositoryProvider));
}

/// Use case: Accept friend request
@riverpod
AcceptFriendRequest acceptFriendRequest(Ref ref) {
  return AcceptFriendRequest(ref.watch(friendshipRepositoryProvider));
}

/// Use case: Reject friend request
@riverpod
RejectFriendRequest rejectFriendRequest(Ref ref) {
  return RejectFriendRequest(ref.watch(friendshipRepositoryProvider));
}

/// Use case: Remove friend
@riverpod
RemoveFriend removeFriend(Ref ref) {
  return RemoveFriend(ref.watch(friendshipRepositoryProvider));
}

/// Use case: Get friends list
@riverpod
GetFriends getFriends(Ref ref) {
  return GetFriends(ref.watch(friendshipRepositoryProvider));
}

/// Use case: Get pending friend requests
@riverpod
GetPendingRequests getPendingRequests(Ref ref) {
  return GetPendingRequests(ref.watch(friendshipRepositoryProvider));
}

/// Use case: Search users by email
@riverpod
SearchUsers searchUsers(Ref ref) {
  return SearchUsers(ref.watch(friendshipRepositoryProvider));
}
