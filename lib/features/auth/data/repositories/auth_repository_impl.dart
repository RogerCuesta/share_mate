// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_model.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of AuthRepository using local data sources
///
/// This repository coordinates between:
/// - UserLocalDataSource (Hive) for user data
/// - AuthLocalDataSource (flutter_secure_storage) for sessions
class AuthRepositoryImpl implements AuthRepository {

  AuthRepositoryImpl({
    required this.userDataSource,
    required this.authDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();
  final UserLocalDataSource userDataSource;
  final AuthLocalDataSource authDataSource;
  final Uuid _uuid;

  @override
  Future<Either<AuthFailure, User>> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if email already exists
      final emailInUse = await userDataSource.emailExists(email);
      if (emailInUse) {
        return const Left(EmailAlreadyExistsFailure());
      }

      // Hash password
      final hashedPassword = userDataSource.hashPassword(password);

      // Create user
      final now = DateTime.now();
      final user = UserModel(
        id: _uuid.v4(),
        email: email,
        fullName: fullName,
        createdAt: now,
      );

      // Save user with credentials
      await userDataSource.saveUser(user, hashedPassword);

      return Right(user.toEntity());
    } catch (e) {
      return Left(StorageFailure('Failed to register user: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Verify credentials
      final user = await userDataSource.verifyCredentials(email, password);
      if (user == null) {
        return const Left(InvalidCredentialsFailure());
      }

      // Create session
      final session = authDataSource.createSession(user.id);

      // Save session
      await authDataSource.saveSession(session);

      return Right(session.toEntity());
    } catch (e) {
      return Left(StorageFailure('Failed to login: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> logoutUser() async {
    try {
      await authDataSource.deleteSession();
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to logout: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, User>> getCurrentUser() async {
    try {
      final user = await userDataSource.getCurrentUser();
      if (user == null) {
        return const Left(UserNotFoundFailure());
      }
      return Right(user.toEntity());
    } catch (e) {
      return Left(StorageFailure('Failed to get current user: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, bool>> checkAuthStatus() async {
    try {
      // Check if session exists and is valid
      final hasSession = await authDataSource.hasValidSession();
      if (!hasSession) {
        return const Right(false);
      }

      // Verify user still exists
      final user = await userDataSource.getCurrentUser();
      if (user == null) {
        // Session exists but user was deleted, clean up session
        await authDataSource.deleteSession();
        return const Right(false);
      }

      return const Right(true);
    } catch (e) {
      return Left(StorageFailure('Failed to check auth status: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> getCurrentSession() async {
    try {
      final session = await authDataSource.getSession();
      if (session == null) {
        return const Left(NoActiveSessionFailure());
      }

      // Check if expired
      if (session.toEntity().isExpired) {
        await authDataSource.deleteSession();
        return const Left(SessionExpiredFailure());
      }

      return Right(session.toEntity());
    } catch (e) {
      return Left(StorageFailure('Failed to get session: $e'));
    }
  }

  @override
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  bool isValidPassword(String password) {
    return password.length >= 8;
  }
}
