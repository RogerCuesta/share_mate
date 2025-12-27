// lib/features/friends/domain/usecases/get_friends.dart

import 'package:dartz/dartz.dart';

import '../entities/friend.dart';
import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Get list of all accepted friends
class GetFriends {
  final FriendshipRepository _repository;

  GetFriends(this._repository);

  Future<Either<FriendshipFailure, List<Friend>>> call() {
    return _repository.getFriends();
  }
}
