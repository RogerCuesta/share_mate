// lib/features/friends/domain/usecases/get_pending_requests.dart

import 'package:dartz/dartz.dart';

import '../entities/friend.dart';
import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Get list of pending friend requests
class GetPendingRequests {
  final FriendshipRepository _repository;

  GetPendingRequests(this._repository);

  Future<Either<FriendshipFailure, List<Friend>>> call() {
    return _repository.getPendingRequests();
  }
}
