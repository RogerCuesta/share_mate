// lib/features/friends/domain/usecases/search_users.dart

import 'package:dartz/dartz.dart';

import '../entities/profile.dart';
import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Search for users by email
class SearchUsers {
  final FriendshipRepository _repository;

  SearchUsers(this._repository);

  Future<Either<FriendshipFailure, List<Profile>>> call({
    required String email,
  }) {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      return Future.value(const Right([]));
    }

    return _repository.searchUsersByEmail(email: trimmedEmail);
  }
}
