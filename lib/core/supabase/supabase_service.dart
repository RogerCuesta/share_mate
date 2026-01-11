// lib/core/supabase/supabase_service.dart
import 'package:flutter/foundation.dart';

import 'package:flutter_project_agents/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase initialization and client management service
///
/// Provides centralized Supabase configuration and client access.
/// Must be initialized once during app startup, after environment variables are loaded.
///
/// Usage:
/// ```dart
/// // In main.dart (after EnvConfig.load())
/// await SupabaseService.init();
///
/// // Access client anywhere
/// final client = SupabaseService.client;
/// final auth = SupabaseService.client.auth;
/// final db = SupabaseService.client.from('table_name');
/// ```
class SupabaseService {
  SupabaseService._(); // Private constructor to prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  static bool _isInitialized = false;

  /// Initialize Supabase client
  ///
  /// Call this ONCE during app startup, after EnvConfig.load().
  ///
  /// Configuration:
  /// - Uses environment variables from .env file
  /// - PKCE auth flow for enhanced security
  /// - FlutterSecureStorage for local session persistence
  ///
  /// Throws [Exception] if:
  /// - Environment variables are not loaded
  /// - Supabase URL or anon key are missing
  /// - Initialization fails
  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Validate environment configuration
      if (!EnvConfig.isConfigured) {
        throw Exception(
          'Environment variables not configured. '
          'Make sure EnvConfig.load() is called before SupabaseService.init(). '
          'Check your .env file and ensure SUPABASE_URL and SUPABASE_ANON_KEY are set.',
        );
      }

      final url = EnvConfig.supabaseUrl;
      final anonKey = EnvConfig.supabaseAnonKey;

      // Additional validation
      if (url.isEmpty) {
        throw Exception(
          'SUPABASE_URL is empty. '
          'Please set a valid Supabase project URL in your .env file.',
        );
      }

      if (anonKey.isEmpty) {
        throw Exception(
          'SUPABASE_ANON_KEY is empty. '
          'Please set a valid Supabase anonymous key in your .env file.',
        );
      }

      // Initialize Supabase with PKCE flow and secure storage
      // - PKCE (Proof Key for Code Exchange) is used by default for enhanced security
      // - FlutterSecureStorage is used automatically for session persistence
      // - Sessions are encrypted at the OS level
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );

      _isInitialized = true;
    } catch (e) {
      // Rethrow with additional context
      throw Exception(
        'Failed to initialize Supabase. '
        'Please check your .env configuration and network connection.\n'
        'Error: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLIENT ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the Supabase client instance
  ///
  /// Must call init() before accessing this.
  ///
  /// Throws [StateError] if Supabase is not initialized.
  ///
  /// Example:
  /// ```dart
  /// // Auth
  /// final auth = SupabaseService.client.auth;
  /// final user = auth.currentUser;
  ///
  /// // Database
  /// final response = await SupabaseService.client
  ///   .from('users')
  ///   .select();
  ///
  /// // Storage
  /// final storage = SupabaseService.client.storage;
  /// ```
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'Supabase is not initialized. '
        'Call SupabaseService.init() in main.dart before accessing the client.',
      );
    }
    return Supabase.instance.client;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVENIENCE GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Quick access to Supabase Auth
  ///
  /// Equivalent to `SupabaseService.client.auth`
  ///
  /// Example:
  /// ```dart
  /// final currentUser = SupabaseService.auth.currentUser;
  /// final session = SupabaseService.auth.currentSession;
  /// ```
  static GoTrueClient get auth => client.auth;

  /// Quick access to current authenticated user
  ///
  /// Returns null if no user is authenticated.
  ///
  /// Example:
  /// ```dart
  /// final user = SupabaseService.currentUser;
  /// if (user != null) {
  ///   debugPrint('Logged in as: ${user.email}');
  /// }
  /// ```
  static User? get currentUser => auth.currentUser;

  /// Quick access to current session
  ///
  /// Returns null if no active session exists.
  ///
  /// Example:
  /// ```dart
  /// final session = SupabaseService.currentSession;
  /// if (session != null) {
  ///   debugPrint('Access token: ${session.accessToken}');
  /// }
  /// ```
  static Session? get currentSession => auth.currentSession;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS & DEBUGGING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if user is currently authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Print Supabase status (for debugging)
  ///
  /// ⚠️ Only use in development. Never log sensitive data in production.
  // ignore: avoid_print
  static void debugPrintStatus() {
    // ignore: avoid_print
    debugPrint('═══════════════════════════════════════════════════════════');
    // ignore: avoid_print
    debugPrint('Supabase Service Status');
    // ignore: avoid_print
    debugPrint('═══════════════════════════════════════════════════════════');
    // ignore: avoid_print
    debugPrint('Initialized: ${isInitialized ? '✅ Yes' : '❌ No'}');
    // ignore: avoid_print
    debugPrint('Authenticated: ${isAuthenticated ? '✅ Yes' : '❌ No'}');
    if (isAuthenticated && currentUser != null) {
      // ignore: avoid_print
      debugPrint('User ID: ${currentUser!.id}');
      // ignore: avoid_print
      debugPrint('User Email: ${currentUser!.email ?? 'N/A'}');
    }
    // ignore: avoid_print
    debugPrint('═══════════════════════════════════════════════════════════');
  }
}
