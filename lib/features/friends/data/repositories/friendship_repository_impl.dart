// lib/features/friends/data/repositories/friendship_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../domain/entities/friend.dart';
import '../../domain/entities/profile.dart';
import '../../domain/failures/friendship_failure.dart';
import '../../domain/repositories/friendship_repository.dart';
import '../datasources/friendship_local_datasource.dart';
import '../datasources/friendship_remote_datasource.dart';

/// Implementation of FriendshipRepository with offline-first strategy
class FriendshipRepositoryImpl implements FriendshipRepository {
  final FriendshipRemoteDataSource _remoteDataSource;
  final FriendshipLocalDataSource _localDataSource;

  FriendshipRepositoryImpl({
    required FriendshipRemoteDataSource remoteDataSource,
    required FriendshipLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<FriendshipFailure, String>> sendFriendRequest({
    required String friendEmail,
  }) async {
    try {
      final friendshipId = await _remoteDataSource.sendFriendRequest(
        friendEmail: friendEmail,
      );
      return Right(friendshipId);
    } on FriendshipRemoteException catch (e) {
      return Left(_mapRemoteException(e));
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, void>> acceptFriendRequest({
    required String friendshipId,
  }) async {
    try {
      await _remoteDataSource.acceptFriendRequest(
        friendshipId: friendshipId,
      );
      // Invalidate cache to force refresh
      await _localDataSource.deleteCachedFriendship(friendshipId);
      return const Right(null);
    } on FriendshipRemoteException catch (e) {
      return Left(_mapRemoteException(e));
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, void>> rejectFriendRequest({
    required String friendshipId,
  }) async {
    try {
      await _remoteDataSource.rejectFriendRequest(
        friendshipId: friendshipId,
      );
      // Invalidate cache
      await _localDataSource.deleteCachedFriendship(friendshipId);
      return const Right(null);
    } on FriendshipRemoteException catch (e) {
      return Left(_mapRemoteException(e));
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, void>> removeFriend({
    required String friendshipId,
  }) async {
    try {
      await _remoteDataSource.removeFriend(friendshipId: friendshipId);
      // Invalidate cache
      await _localDataSource.deleteCachedFriendship(friendshipId);
      return const Right(null);
    } on FriendshipRemoteException catch (e) {
      return Left(_mapRemoteException(e));
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, List<Friend>>> getFriends() async {
    try {
      // Offline-first: Try remote first
      final remoteFriends = await _remoteDataSource.getFriends();
      await _localDataSource.cacheFriends(remoteFriends);
      final friends = remoteFriends.map((m) => m.toEntity()).toList();
      return Right(friends);
    } on FriendshipRemoteException {
      // Fallback to cache on network error
      try {
        final cachedFriends = await _localDataSource.getCachedFriends();
        final friends = cachedFriends.map((m) => m.toEntity()).toList();
        return Right(friends);
      } on FriendshipLocalException catch (e) {
        return Left(FriendshipFailure.cacheError(e.message));
      }
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, List<Friend>>> getPendingRequests() async {
    try {
      // Offline-first: Try remote first
      final remoteRequests = await _remoteDataSource.getPendingRequests();
      await _localDataSource.cachePendingRequests(remoteRequests);
      final requests = remoteRequests.map((m) => m.toEntity()).toList();
      return Right(requests);
    } on FriendshipRemoteException {
      // Fallback to cache on network error
      try {
        final cachedRequests = await _localDataSource.getCachedPendingRequests();
        final requests = cachedRequests.map((m) => m.toEntity()).toList();
        return Right(requests);
      } on FriendshipLocalException catch (e) {
        return Left(FriendshipFailure.cacheError(e.message));
      }
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, List<Profile>>> searchUsersByEmail({
    required String email,
  }) async {
    try {
      // Check cache first for performance
      final cachedResults = await _localDataSource.getCachedSearchResults(email);
      if (cachedResults != null) {
        final profiles = cachedResults.map((m) => m.toEntity()).toList();
        return Right(profiles);
      }

      // Fetch from remote
      final remoteProfiles = await _remoteDataSource.searchUsersByEmail(
        email: email,
      );
      await _localDataSource.cacheSearchResults(email, remoteProfiles);
      final profiles = remoteProfiles.map((m) => m.toEntity()).toList();
      return Right(profiles);
    } on FriendshipRemoteException catch (e) {
      return Left(_mapRemoteException(e));
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, Profile>> getMyProfile() async {
    try {
      // Offline-first: Try remote first
      final remoteProfile = await _remoteDataSource.getMyProfile();
      await _localDataSource.cacheMyProfile(remoteProfile);
      return Right(remoteProfile.toEntity());
    } on FriendshipRemoteException {
      // Fallback to cache on network error
      try {
        final cachedProfile = await _localDataSource.getCachedMyProfile();
        if (cachedProfile == null) {
          return const Left(FriendshipFailure.cacheError('Profile not found in cache'));
        }
        return Right(cachedProfile.toEntity());
      } on FriendshipLocalException catch (e) {
        return Left(FriendshipFailure.cacheError(e.message));
      }
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<FriendshipFailure, Profile>> updateProfile({
    String? fullName,
    String? avatarUrl,
    bool? isDiscoverable,
  }) async {
    try {
      final updatedProfile = await _remoteDataSource.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        isDiscoverable: isDiscoverable,
      );
      await _localDataSource.cacheMyProfile(updatedProfile);
      return Right(updatedProfile.toEntity());
    } on FriendshipRemoteException catch (e) {
      return Left(_mapRemoteException(e));
    } catch (e) {
      return Left(FriendshipFailure.unexpected(e.toString()));
    }
  }

  /// Map remote exceptions to domain failures
  FriendshipFailure _mapRemoteException(FriendshipRemoteException e) {
    final message = e.message.toLowerCase();

    if (message.contains('not found') || message.contains('not discoverable')) {
      return FriendshipFailure.userNotFound(e.message);
    } else if (message.contains('already exists') || message.contains('already friends')) {
      return FriendshipFailure.alreadyFriends(e.message);
    } else if (message.contains('yourself')) {
      return FriendshipFailure.cannotAddSelf(e.message);
    } else if (message.contains('not found') || message.contains('already processed')) {
      return FriendshipFailure.requestNotFound(e.message);
    } else if (message.contains('not authenticated') || message.contains('unauthorized')) {
      return FriendshipFailure.unauthorized(e.message);
    } else if (message.contains('network') || message.contains('timeout')) {
      return FriendshipFailure.networkError(e.message);
    } else {
      return FriendshipFailure.serverError(e.message);
    }
  }
}
