// lib/features/settings/domain/usecases/delete_account.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/account_repository.dart';

/// Use case: Delete Account
///
/// Permanently deletes the user's account and all associated data.
/// This action is irreversible.
class DeleteAccount {

  DeleteAccount(this.repository);
  final AccountRepository repository;

  Future<Either<SettingsFailure, Unit>> call(String userId) async {
    return repository.deleteAccount(userId);
  }
}
