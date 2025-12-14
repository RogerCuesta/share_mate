// lib/features/auth/data/datasources/auth_local_datasource.dart

import 'dart:convert';

import 'package:flutter_project_agents/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Local data source for authentication session using flutter_secure_storage
///
/// Handles:
/// - Session storage in secure storage (NOT in Hive)
/// - Session token generation
/// - Session validation
abstract class AuthLocalDataSource {
  /// Save authentication session
  Future<void> saveSession(AuthSessionModel session);

  /// Get current session
  Future<AuthSessionModel?> getSession();

  /// Delete session (logout)
  Future<void> deleteSession();

  /// Check if session exists and is valid
  Future<bool> hasValidSession();

  /// Generate a new session token
  String generateToken();

  /// Create a new session with generated token
  AuthSessionModel createSession(String userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {

  AuthLocalDataSourceImpl({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();
  static const String _sessionKey = 'auth_session';
  static const int _sessionDurationDays = 30;

  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    final jsonString = json.encode(session.toJson());
    await _secureStorage.write(key: _sessionKey, value: jsonString);
  }

  @override
  Future<AuthSessionModel?> getSession() async {
    try {
      final jsonString = await _secureStorage.read(key: _sessionKey);
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(jsonMap);
    } catch (e) {
      // If there's any error reading/parsing session, return null
      return null;
    }
  }

  @override
  Future<void> deleteSession() async {
    await _secureStorage.delete(key: _sessionKey);
  }

  @override
  Future<bool> hasValidSession() async {
    final session = await getSession();
    if (session == null) return false;

    // Check if session is expired
    if (session.toEntity().isExpired) {
      await deleteSession();
      return false;
    }

    return true;
  }

  @override
  String generateToken() {
    return _uuid.v4();
  }

  @override
  AuthSessionModel createSession(String userId) {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: _sessionDurationDays));

    return AuthSessionModel(
      userId: userId,
      token: generateToken(),
      expiresAt: expiresAt,
      createdAt: now,
    );
  }
}
