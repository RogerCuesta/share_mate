// lib/core/config/env_config.dart
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
///
/// Provides type-safe access to environment variables from .env file.
/// Validates that required variables exist and throws descriptive errors if missing.
///
/// Usage:
/// ```dart
/// // In main.dart (before runApp)
/// await EnvConfig.load();
///
/// // Access variables anywhere
/// final url = EnvConfig.supabaseUrl;
/// final key = EnvConfig.supabaseAnonKey;
/// ```
class EnvConfig {
  EnvConfig._(); // Private constructor to prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load environment variables from .env file
  ///
  /// Call this ONCE during app startup, before runApp().
  /// Throws [Exception] if .env file is missing or required variables are not set.
  static Future<void> load() async {
    try {
      await dotenv.load();
      _validateRequiredVariables();
    } catch (e) {
      throw Exception(
        'Failed to load .env file. '
        'Make sure .env exists in the project root and contains all required variables. '
        'See .env.example for reference.\n'
        'Error: $e',
      );
    }
  }

  /// Validates that all required environment variables are present
  static void _validateRequiredVariables() {
    final missing = <String>[];

    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    if (missing.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missing.join(', ')}\n'
        'Please check your .env file and ensure all variables are set.\n'
        'See .env.example for reference.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPABASE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Supabase project URL
  ///
  /// Format: https://your-project.supabase.co
  /// Required for all Supabase API calls.
  static String get supabaseUrl {
    return dotenv.get('SUPABASE_URL', fallback: '');
  }

  /// Supabase anonymous key (public key)
  ///
  /// Safe to use in client-side code.
  /// Used for authentication and public API access.
  static String get supabaseAnonKey {
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  }

  /// Supabase service role key (private key)
  ///
  /// ⚠️ WARNING: This key has full admin access to your database.
  /// NEVER expose this in client-side code or commit to version control.
  /// Only use for server-side operations or secure admin functions.
  ///
  /// Returns empty string if not set (optional for client-only apps).
  static String get supabaseServiceRoleKey {
    return dotenv.get('SUPABASE_SERVICE_ROLE_KEY', fallback: '');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if environment is properly configured
  ///
  /// Returns true if all required variables are set.
  static bool get isConfigured {
    try {
      _validateRequiredVariables();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get custom environment variable
  ///
  /// Use this for additional variables you add to .env
  ///
  /// Example:
  /// ```dart
  /// final apiKey = EnvConfig.get('API_KEY');
  /// final apiKeyWithDefault = EnvConfig.get('API_KEY', fallback: 'default');
  /// ```
  static String get(String key, {String fallback = ''}) {
    return dotenv.get(key, fallback: fallback);
  }

  /// Check if a specific variable exists
  static bool has(String key) {
    return dotenv.env.containsKey(key);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUGGING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Print configuration status (for debugging)
  ///
  /// ⚠️ Only use in development. Never log actual values in production.
  static void debugPrintStatus() {
    // ignore: avoid_print
    debugPrint('═══════════════════════════════════════════════════════════');
    // ignore: avoid_print
    debugPrint('Environment Configuration Status');
    // ignore: avoid_print
    debugPrint('═══════════════════════════════════════════════════════════');
    // ignore: avoid_print
    debugPrint('SUPABASE_URL: ${supabaseUrl.isNotEmpty ? '✅ Set' : '❌ Missing'}');
    // ignore: avoid_print
    debugPrint('SUPABASE_ANON_KEY: ${supabaseAnonKey.isNotEmpty ? '✅ Set' : '❌ Missing'}');
    // ignore: avoid_print
    debugPrint('SUPABASE_SERVICE_ROLE_KEY: ${supabaseServiceRoleKey.isNotEmpty ? '✅ Set (optional)' : '⚠️ Not set (optional)'}');
    // ignore: avoid_print
    debugPrint('Overall Status: ${isConfigured ? '✅ Configured' : '❌ Not Configured'}');
    // ignore: avoid_print
    debugPrint('═══════════════════════════════════════════════════════════');
  }
}
