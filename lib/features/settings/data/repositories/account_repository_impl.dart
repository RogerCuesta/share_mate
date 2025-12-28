// lib/features/settings/data/repositories/account_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../domain/failures/settings_failure.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

/// Account Repository Implementation
///
/// Manages account operations via Supabase Auth.
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<SettingsFailure, Unit>> changePassword({
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(newPassword: newPassword);
      return const Right(unit);
    } on AccountRemoteException catch (e) {
      return Left(SettingsFailure.passwordChangeError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.passwordChangeError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> sendEmailVerification() async {
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(unit);
    } on AccountRemoteException catch (e) {
      return Left(SettingsFailure.emailVerificationError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.emailVerificationError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, bool>> checkEmailVerified() async {
    try {
      final isVerified = await remoteDataSource.checkEmailVerified();
      return Right(isVerified);
    } on AccountRemoteException catch (e) {
      return Left(SettingsFailure.emailVerificationError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.emailVerificationError('Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Either<SettingsFailure, Unit>> deleteAccount(String userId) async {
    try {
      await remoteDataSource.deleteAccount(userId);
      return const Right(unit);
    } on AccountRemoteException catch (e) {
      return Left(SettingsFailure.accountDeletionError(e.message));
    } catch (e) {
      return Left(
        SettingsFailure.accountDeletionError('Unexpected error: $e'),
      );
    }
  }
}
