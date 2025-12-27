// lib/features/friends/data/datasources/friendship_local_datasource.dart

import 'package:hive/hive.dart';

import '../models/friend_model.dart';
import '../models/friendship_model.dart';
import '../models/profile_model.dart';

/// Exception thrown when local friendship operations fail
class FriendshipLocalException implements Exception {
  final String message;
  FriendshipLocalException(this.message);

  @override
  String toString() => 'FriendshipLocalException: $message';
}

/// Local data source for friendship operations using Hive
abstract class FriendshipLocalDataSource {
  /// Initialize Hive boxes
  Future<void> init();

  /// Cache friends list
  Future<void> cacheFriends(List<FriendModel> friends);

  /// Get cached friends list
  Future<List<FriendModel>> getCachedFriends();

  /// Cache pending requests list
  Future<void> cachePendingRequests(List<FriendModel> requests);

  /// Get cached pending requests
  Future<List<FriendModel>> getCachedPendingRequests();

  /// Cache a friendship
  Future<void> cacheFriendship(FriendshipModel friendship);

  /// Get cached friendship by ID
  Future<FriendshipModel?> getCachedFriendship(String friendshipId);

  /// Delete cached friendship
  Future<void> deleteCachedFriendship(String friendshipId);

  /// Cache user profile
  Future<void> cacheProfile(ProfileModel profile);

  /// Get cached profile
  Future<ProfileModel?> getCachedProfile(String userId);

  /// Cache current user's profile
  Future<void> cacheMyProfile(ProfileModel profile);

  /// Get cached current user's profile
  Future<ProfileModel?> getCachedMyProfile();

  /// Cache search results
  Future<void> cacheSearchResults(String query, List<ProfileModel> results);

  /// Get cached search results
  Future<List<ProfileModel>?> getCachedSearchResults(String query);

  /// Clear all friendship cache
  Future<void> clearAllCache();
}

/// Implementation of FriendshipLocalDataSource using Hive
class FriendshipLocalDataSourceImpl implements FriendshipLocalDataSource {
  static const String _friendsBoxName = 'friends';
  static const String _pendingRequestsBoxName = 'pending_requests';
  static const String _friendshipsBoxName = 'friendships';
  static const String _profilesBoxName = 'profiles';
  static const String _myProfileBoxName = 'my_profile';
  static const String _searchCacheBoxName = 'friend_search_cache';

  Box<FriendModel>? _friendsBox;
  Box<FriendModel>? _pendingRequestsBox;
  Box<FriendshipModel>? _friendshipsBox;
  Box<ProfileModel>? _profilesBox;
  Box<ProfileModel>? _myProfileBox;
  Box<List<dynamic>>? _searchCacheBox;

  @override
  Future<void> init() async {
    _friendsBox = await Hive.openBox<FriendModel>(_friendsBoxName);
    _pendingRequestsBox = await Hive.openBox<FriendModel>(_pendingRequestsBoxName);
    _friendshipsBox = await Hive.openBox<FriendshipModel>(_friendshipsBoxName);
    _profilesBox = await Hive.openBox<ProfileModel>(_profilesBoxName);
    _myProfileBox = await Hive.openBox<ProfileModel>(_myProfileBoxName);
    _searchCacheBox = await Hive.openBox<List<dynamic>>(_searchCacheBoxName);
  }

  Box<FriendModel> get _ensureFriendsBox {
    if (_friendsBox == null || !_friendsBox!.isOpen) {
      throw FriendshipLocalException('Friends box not initialized');
    }
    return _friendsBox!;
  }

  Box<FriendModel> get _ensurePendingRequestsBox {
    if (_pendingRequestsBox == null || !_pendingRequestsBox!.isOpen) {
      throw FriendshipLocalException('Pending requests box not initialized');
    }
    return _pendingRequestsBox!;
  }

  Box<FriendshipModel> get _ensureFriendshipsBox {
    if (_friendshipsBox == null || !_friendshipsBox!.isOpen) {
      throw FriendshipLocalException('Friendships box not initialized');
    }
    return _friendshipsBox!;
  }

  Box<ProfileModel> get _ensureProfilesBox {
    if (_profilesBox == null || !_profilesBox!.isOpen) {
      throw FriendshipLocalException('Profiles box not initialized');
    }
    return _profilesBox!;
  }

  Box<ProfileModel> get _ensureMyProfileBox {
    if (_myProfileBox == null || !_myProfileBox!.isOpen) {
      throw FriendshipLocalException('My profile box not initialized');
    }
    return _myProfileBox!;
  }

  Box<List<dynamic>> get _ensureSearchCacheBox {
    if (_searchCacheBox == null || !_searchCacheBox!.isOpen) {
      throw FriendshipLocalException('Search cache box not initialized');
    }
    return _searchCacheBox!;
  }

  @override
  Future<void> cacheFriends(List<FriendModel> friends) async {
    final box = _ensureFriendsBox;
    await box.clear();
    for (final friend in friends) {
      await box.put(friend.userId, friend);
    }
  }

  @override
  Future<List<FriendModel>> getCachedFriends() async {
    final box = _ensureFriendsBox;
    return box.values.toList();
  }

  @override
  Future<void> cachePendingRequests(List<FriendModel> requests) async {
    final box = _ensurePendingRequestsBox;
    await box.clear();
    for (final request in requests) {
      await box.put(request.userId, request);
    }
  }

  @override
  Future<List<FriendModel>> getCachedPendingRequests() async {
    final box = _ensurePendingRequestsBox;
    return box.values.toList();
  }

  @override
  Future<void> cacheFriendship(FriendshipModel friendship) async {
    final box = _ensureFriendshipsBox;
    await box.put(friendship.id, friendship);
  }

  @override
  Future<FriendshipModel?> getCachedFriendship(String friendshipId) async {
    final box = _ensureFriendshipsBox;
    return box.get(friendshipId);
  }

  @override
  Future<void> deleteCachedFriendship(String friendshipId) async {
    final box = _ensureFriendshipsBox;
    await box.delete(friendshipId);
  }

  @override
  Future<void> cacheProfile(ProfileModel profile) async {
    final box = _ensureProfilesBox;
    await box.put(profile.userId, profile);
  }

  @override
  Future<ProfileModel?> getCachedProfile(String userId) async {
    final box = _ensureProfilesBox;
    return box.get(userId);
  }

  @override
  Future<void> cacheMyProfile(ProfileModel profile) async {
    final box = _ensureMyProfileBox;
    await box.put('current_user', profile);
  }

  @override
  Future<ProfileModel?> getCachedMyProfile() async {
    final box = _ensureMyProfileBox;
    return box.get('current_user');
  }

  @override
  Future<void> cacheSearchResults(
    String query,
    List<ProfileModel> results,
  ) async {
    final box = _ensureSearchCacheBox;
    final serialized = results.map((p) => p.toJson()).toList();
    await box.put(query.toLowerCase(), serialized);
  }

  @override
  Future<List<ProfileModel>?> getCachedSearchResults(String query) async {
    final box = _ensureSearchCacheBox;
    final cached = box.get(query.toLowerCase());
    if (cached == null) return null;

    return cached
        .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearAllCache() async {
    await _ensureFriendsBox.clear();
    await _ensurePendingRequestsBox.clear();
    await _ensureFriendshipsBox.clear();
    await _ensureProfilesBox.clear();
    await _ensureMyProfileBox.clear();
    await _ensureSearchCacheBox.clear();
  }
}
