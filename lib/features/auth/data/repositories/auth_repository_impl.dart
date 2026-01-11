// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_model.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_project_agents/features/auth/domain/entities/user.dart';
import 'package:flutter_project_agents/features/auth/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of AuthRepository using Supabase + Local data sources
///
/// This repository coordinates between:
/// - AuthRemoteDataSource (Supabase) for remote authentication
/// - UserLocalDataSource (Hive) for local user data
/// - AuthLocalDataSource (flutter_secure_storage) for sessions
///
/// Strategy:
/// - Online: Use Supabase for auth, cache locally
/// - Offline: Fallback to local auth (for already registered users)
class AuthRepositoryImpl implements AuthRepository {

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.userDataSource,
    required this.authDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();
  final AuthRemoteDataSource remoteDataSource;
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
      // Try to register with Supabase (online)
      final authResponse = await remoteDataSource.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      final supabaseUser = authResponse.user;
      if (supabaseUser == null) {
        return const Left(
          UnknownAuthFailure('Registration failed: User is null'),
        );
      }

      // Extract full name from metadata or use provided one
      final userFullName =
          supabaseUser.userMetadata?['full_name'] as String? ?? fullName;

      // Create User entity with Supabase ID
      final user = User(
        id: supabaseUser.id, // Use Supabase ID as primary ID
        supabaseId: supabaseUser.id,
        email: email,
        fullName: userFullName,
        createdAt: DateTime.parse(supabaseUser.createdAt),
      );

      // Save user locally in Hive
      final userModel = UserModel.fromEntity(user);
      final hashedPassword = userDataSource.hashPassword(password);
      await userDataSource.saveUser(userModel, hashedPassword);

      // Create and save session from Supabase
      if (authResponse.session != null) {
        final sessionModel = AuthSessionModel(
          userId: user.id,
          token: authResponse.session!.accessToken,
          expiresAt: DateTime.fromMillisecondsSinceEpoch(
            authResponse.session!.expiresAt! * 1000,
          ),
          createdAt: DateTime.now(),
        );
        await authDataSource.saveSession(sessionModel);
      }

      return Right(user);
    } on EmailAlreadyInUseRemoteException {
      return const Left(EmailAlreadyInUseFailure());
    } on WeakPasswordRemoteException {
      return const Left(WeakPasswordFailure());
    } on InvalidEmailRemoteException {
      return const Left(InvalidEmailFailure());
    } on NetworkException {
      // Offline fallback: Try local registration
      return _registerUserLocally(email, password, fullName);
    } on AuthRemoteException catch (e) {
      return Left(SupabaseAuthFailure(e.message));
    } catch (e) {
      return Left(UnknownAuthFailure('Failed to register user: $e'));
    }
  }

  /// Fallback registration when offline
  Future<Either<AuthFailure, User>> _registerUserLocally(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Check if email already exists locally
      final emailInUse = await userDataSource.emailExists(email);
      if (emailInUse) {
        return const Left(EmailAlreadyExistsFailure());
      }

      // Create user locally (without Supabase ID)
      final now = DateTime.now();
      final user = User(
        id: _uuid.v4(), // Generate local ID
        email: email,
        fullName: fullName,
        createdAt: now,
      );

      // Save user with hashed password
      final userModel = UserModel.fromEntity(user);
      final hashedPassword = userDataSource.hashPassword(password);
      await userDataSource.saveUser(userModel, hashedPassword);

      return Right(user);
    } catch (e) {
      return Left(StorageFailure('Failed to register user locally: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Try to login with Supabase (online)
      final authResponse = await remoteDataSource.login(
        email: email,
        password: password,
      );

      final supabaseUser = authResponse.user;
      if (supabaseUser == null) {
        return const Left(
          UnknownAuthFailure('Login failed: User is null'),
        );
      }

      // Extract full name from metadata
      final fullName =
          supabaseUser.userMetadata?['full_name'] as String? ?? '';

      // Create/update User entity
      final user = User(
        id: supabaseUser.id,
        supabaseId: supabaseUser.id,
        email: email,
        fullName: fullName,
        createdAt: DateTime.parse(supabaseUser.createdAt),
      );

      // Save/update user locally
      final userModel = UserModel.fromEntity(user);
      final hashedPassword = userDataSource.hashPassword(password);
      await userDataSource.saveUser(userModel, hashedPassword);

      // Create and save session from Supabase
      final sessionModel = AuthSessionModel(
        userId: user.id,
        token: authResponse.session!.accessToken,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          authResponse.session!.expiresAt! * 1000,
        ),
        createdAt: DateTime.now(),
      );
      await authDataSource.saveSession(sessionModel);

      return Right(sessionModel.toEntity());
    } on InvalidCredentialsRemoteException {
      return const Left(InvalidCredentialsFailure());
    } on UserNotFoundRemoteException {
      return const Left(UserNotFoundFailure());
    } on TooManyRequestsRemoteException {
      return const Left(TooManyRequestsFailure());
    } on NetworkException {
      // Offline fallback: Try local login
      return _loginUserLocally(email, password);
    } on AuthRemoteException catch (e) {
      return Left(SupabaseAuthFailure(e.message));
    } catch (e) {
      return Left(UnknownAuthFailure('Failed to login: $e'));
    }
  }

  /// Fallback login when offline
  Future<Either<AuthFailure, AuthSession>> _loginUserLocally(
    String email,
    String password,
  ) async {
    try {
      // Verify credentials locally
      final user = await userDataSource.verifyCredentials(email, password);
      if (user == null) {
        return const Left(InvalidCredentialsFailure());
      }

      // Create local session (UUID token)
      final session = authDataSource.createSession(user.id);

      // Save session
      await authDataSource.saveSession(session);

      return Right(session.toEntity());
    } catch (e) {
      return Left(StorageFailure('Failed to login locally: $e'));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> logoutUser() async {
    try {
      // Try to logout from Supabase (online)
      try {
        await remoteDataSource.logout();
      } on NetworkException {
        // Network error is acceptable - continue with local logout
        // User can still logout locally even if Supabase signout fails
      } catch (_) {
        // Other Supabase errors are also acceptable during logout
        // The important thing is to clear local session
      }

      // Always clear local session (even if Supabase logout failed)
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
