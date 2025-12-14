// lib/features/auth/data/datasources/user_local_datasource.dart

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_credentials_model.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_model.dart';
import 'package:hive/hive.dart';

/// Local data source for user data using Hive
///
/// Handles:
/// - User data storage (UserModel)
/// - Credentials storage (UserCredentialsModel with hashed passwords)
/// - User lookup and validation
abstract class UserLocalDataSource {
  /// Save a new user with credentials
  Future<void> saveUser(UserModel user, String hashedPassword);

  /// Get user by ID
  Future<UserModel?> getUserById(String userId);

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email);

  /// Check if email already exists
  Future<bool> emailExists(String email);

  /// Verify user credentials (email + password)
  Future<UserModel?> verifyCredentials(String email, String password);

  /// Delete user and credentials
  Future<void> deleteUser(String userId);

  /// Get current logged in user (assumes only one user at a time)
  Future<UserModel?> getCurrentUser();

  /// Hash password using SHA-256
  String hashPassword(String password);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {

  UserLocalDataSourceImpl();
  static const String _usersBoxName = 'users';
  static const String _credentialsBoxName = 'credentials';
  static const String _currentUserKey = 'current_user_id';

  late final Box<UserModel> _usersBox;
  late final Box<UserCredentialsModel> _credentialsBox;

  /// Initialize boxes (call this after Hive.init)
  Future<void> init() async {
    _usersBox = await Hive.openBox<UserModel>(_usersBoxName);
    _credentialsBox = await Hive.openBox<UserCredentialsModel>(_credentialsBoxName);
  }

  @override
  Future<void> saveUser(UserModel user, String hashedPassword) async {
    // Save user data
    await _usersBox.put(user.id, user);

    // Save credentials
    final credentials = UserCredentialsModel(
      userId: user.id,
      email: user.email,
      hashedPassword: hashedPassword,
      createdAt: user.createdAt,
    );
    await _credentialsBox.put(user.email.toLowerCase(), credentials);

    // Set as current user
    await _usersBox.put(_currentUserKey, user);
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    return _usersBox.get(userId);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final credentials = _credentialsBox.get(email.toLowerCase());
    if (credentials == null) return null;
    return _usersBox.get(credentials.userId);
  }

  @override
  Future<bool> emailExists(String email) async {
    return _credentialsBox.containsKey(email.toLowerCase());
  }

  @override
  Future<UserModel?> verifyCredentials(String email, String password) async {
    final credentials = _credentialsBox.get(email.toLowerCase());
    if (credentials == null) return null;

    // Verify password
    final hashedInput = hashPassword(password);
    if (hashedInput != credentials.hashedPassword) return null;

    // Return user if password matches
    return _usersBox.get(credentials.userId);
  }

  @override
  Future<void> deleteUser(String userId) async {
    final user = await getUserById(userId);
    if (user != null) {
      await _credentialsBox.delete(user.email.toLowerCase());
      await _usersBox.delete(userId);

      // Clear current user if it was this user
      final currentUser = await getCurrentUser();
      if (currentUser?.id == userId) {
        await _usersBox.delete(_currentUserKey);
      }
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _usersBox.get(_currentUserKey);
  }

  @override
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
