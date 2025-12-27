// lib/features/friends/domain/usecases/remove_friend.dart

import 'package:dartz/dartz.dart';

import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Remove an existing friendship
class RemoveFriend {
  final FriendshipRepository _repository;

  RemoveFriend(this._repository);

  Future<Either<FriendshipFailure, void>> call({
    required String friendshipId,
  }) {
    return _repository.removeFriend(friendshipId: friendshipId);
  }
}
