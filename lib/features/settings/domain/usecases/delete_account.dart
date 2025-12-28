// lib/features/settings/domain/usecases/delete_account.dart

import 'package:dartz/dartz.dart';

import '../failures/settings_failure.dart';
import '../repositories/account_repository.dart';

/// Use case: Delete Account
///
/// Permanently deletes the user's account and all associated data.
/// This action is irreversible.
class DeleteAccount {
  final AccountRepository repository;

  DeleteAccount(this.repository);

  Future<Either<SettingsFailure, Unit>> call(String userId) async {
    return repository.deleteAccount(userId);
  }
}
