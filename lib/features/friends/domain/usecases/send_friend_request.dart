// lib/features/friends/domain/usecases/send_friend_request.dart

import 'package:dartz/dartz.dart';

import '../failures/friendship_failure.dart';
import '../repositories/friendship_repository.dart';

/// Use case: Send a friend request by email
///
/// Validates email format and delegates to repository.
/// Returns the friendship ID on success.
class SendFriendRequest {
  final FriendshipRepository _repository;

  SendFriendRequest(this._repository);

  Future<Either<FriendshipFailure, String>> call({
    required String friendEmail,
  }) async {
    // Basic email validation
    final trimmedEmail = friendEmail.trim().toLowerCase();
    if (trimmedEmail.isEmpty || !_isValidEmail(trimmedEmail)) {
      return const Left(
        FriendshipFailure.userNotFound('Invalid email format'),
      );
    }

    return await _repository.sendFriendRequest(friendEmail: trimmedEmail);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}
