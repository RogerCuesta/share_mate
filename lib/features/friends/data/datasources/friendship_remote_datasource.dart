// lib/features/friends/data/datasources/friendship_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friend_model.dart';
import '../models/friendship_model.dart';
import '../models/profile_model.dart';

/// Exception thrown when friendship remote operations fail
class FriendshipRemoteException implements Exception {
  final String message;
  FriendshipRemoteException(this.message);

  @override
  String toString() => 'FriendshipRemoteException: $message';
}

/// Remote data source for friendship operations using Supabase
abstract class FriendshipRemoteDataSource {
  /// Send a friend request by email
  Future<String> sendFriendRequest({required String friendEmail});

  /// Accept a pending friend request
  Future<void> acceptFriendRequest({required String friendshipId});

  /// Reject a pending friend request
  Future<void> rejectFriendRequest({required String friendshipId});

  /// Remove an existing friendship
  Future<void> removeFriend({required String friendshipId});

  /// Get list of all accepted friends
  Future<List<FriendModel>> getFriends();

  /// Get list of pending friend requests
  Future<List<FriendModel>> getPendingRequests();

  /// Search for users by email
  Future<List<ProfileModel>> searchUsersByEmail({required String email});

  /// Get current user's profile
  Future<ProfileModel> getMyProfile();

  /// Update current user's profile
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? avatarUrl,
    bool? isDiscoverable,
  });
}

/// Implementation of FriendshipRemoteDataSource using Supabase
class FriendshipRemoteDataSourceImpl implements FriendshipRemoteDataSource {
  final SupabaseClient client;

  FriendshipRemoteDataSourceImpl({required this.client});

  @override
  Future<String> sendFriendRequest({required String friendEmail}) async {
    try {
      final response = await client.rpc(
        'send_friend_request',
        params: {'p_friend_email': friendEmail},
      );

      if (response == null) {
        throw FriendshipRemoteException('Failed to send friend request');
      }

      return response as String;
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> acceptFriendRequest({required String friendshipId}) async {
    try {
      await client.rpc(
        'accept_friend_request',
        params: {'p_friendship_id': friendshipId},
      );
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectFriendRequest({required String friendshipId}) async {
    try {
      await client.rpc(
        'reject_friend_request',
        params: {'p_friendship_id': friendshipId},
      );
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> removeFriend({required String friendshipId}) async {
    try {
      await client.rpc(
        'remove_friend',
        params: {'p_friendship_id': friendshipId},
      );
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<FriendModel>> getFriends() async {
    try {
      final response = await client.rpc('get_friends_list') as List<dynamic>;

      return response
          .map((json) => FriendModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<FriendModel>> getPendingRequests() async {
    try {
      final response =
          await client.rpc('get_pending_friend_requests') as List<dynamic>;

      return response
          .map((json) => FriendModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<ProfileModel>> searchUsersByEmail({required String email}) async {
    try {
      final response = await client.rpc(
        'search_users_by_email',
        params: {'p_email_query': email},
      ) as List<dynamic>;

      return response
          .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<ProfileModel> getMyProfile() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw FriendshipRemoteException('User not authenticated');
      }

      final response = await client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    String? fullName,
    String? avatarUrl,
    bool? isDiscoverable,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw FriendshipRemoteException('User not authenticated');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (isDiscoverable != null) updates['is_discoverable'] = isDiscoverable;

      if (updates.isEmpty) {
        throw FriendshipRemoteException('No fields to update');
      }

      final response = await client
          .from('profiles')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw FriendshipRemoteException(e.message);
    } catch (e) {
      throw FriendshipRemoteException('Unexpected error: ${e.toString()}');
    }
  }
}
