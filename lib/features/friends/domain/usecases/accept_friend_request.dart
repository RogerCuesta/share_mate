// lib/features/friends/domain/usecases/accept_friend_request.dart

import 'package:dartz/dartz.dart';

import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Accept a pending friend request
class AcceptFriendRequest {
  final FriendshipRepository _repository;

  AcceptFriendRequest(this._repository);

  Future<Either<FriendshipFailure, void>> call({
    required String friendshipId,
  }) {
    return _repository.acceptFriendRequest(friendshipId: friendshipId);
  }
}
