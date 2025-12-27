// lib/features/friends/domain/usecases/reject_friend_request.dart

import 'package:dartz/dartz.dart';

import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Reject a pending friend request
class RejectFriendRequest {
  final FriendshipRepository _repository;

  RejectFriendRequest(this._repository);

  Future<Either<FriendshipFailure, void>> call({
    required String friendshipId,
  }) {
    return _repository.rejectFriendRequest(friendshipId: friendshipId);
  }
}
