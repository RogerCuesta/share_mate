// lib/features/settings/domain/usecases/send_email_verification.dart

import 'package:dartz/dartz.dart';

import 'package:flutter_project_agents/features/settings/domain/failures/settings_failure.dart';
import 'package:flutter_project_agents/features/settings/domain/repositories/account_repository.dart';

/// Use case: Send Email Verification
///
/// Sends a verification email to the current user's email address.
class SendEmailVerification {

  SendEmailVerification(this.repository);
  final AccountRepository repository;

  Future<Either<SettingsFailure, Unit>> call() async {
    return repository.sendEmailVerification();
  }
}
