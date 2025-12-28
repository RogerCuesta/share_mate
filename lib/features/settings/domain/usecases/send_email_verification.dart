// lib/features/settings/domain/usecases/send_email_verification.dart

import 'package:dartz/dartz.dart';

import '../failures/settings_failure.dart';
import '../repositories/account_repository.dart';

/// Use case: Send Email Verification
///
/// Sends a verification email to the current user's email address.
class SendEmailVerification {
  final AccountRepository repository;

  SendEmailVerification(this.repository);

  Future<Either<SettingsFailure, Unit>> call() async {
    return repository.sendEmailVerification();
  }
}
