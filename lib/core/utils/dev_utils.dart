// lib/core/utils/dev_utils.dart

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Development utilities for debugging and testing
///
/// ⚠️ WARNING: These methods should ONLY be used in development!
/// Never call these in production code.
class DevUtils {
  DevUtils._();

  /// Clear all auth-related data (Hive + Secure Storage)
  ///
  /// This will:
  /// - Clear all Hive auth boxes (users, credentials, current_user_id)
  /// - Clear all secure storage (sessions)
  ///
  /// Use this when:
  /// - You encounter HiveError about storing same object with different keys
  /// - You want to reset auth state completely during development
  /// - You're testing registration/login flows from scratch
  ///
  /// Example usage:
  /// ```dart
  /// // In your debug menu or during development
  /// await DevUtils.clearAllAuthData();
  /// print('✅ All auth data cleared!');
  /// ```
  static Future<void> clearAllAuthData() async {
    try {
      // Clear Hive auth data
      await HiveService.clearAuthData();

      // Clear secure storage
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      print('✅ DevUtils: All auth data cleared successfully!');
      print('   - Hive boxes: users, credentials, current_user_id');
      print('   - Secure storage: all sessions and tokens');
    } catch (e) {
      print('❌ DevUtils: Error clearing auth data: $e');
      rethrow;
    }
  }

  /// Clear ONLY Hive auth data (keeps secure storage)
  static Future<void> clearHiveAuthData() async {
    try {
      await HiveService.clearAuthData();
      print('✅ DevUtils: Hive auth data cleared!');
    } catch (e) {
      print('❌ DevUtils: Error clearing Hive data: $e');
      rethrow;
    }
  }

  /// Clear ONLY secure storage (keeps Hive data)
  static Future<void> clearSecureStorage() async {
    try {
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
      print('✅ DevUtils: Secure storage cleared!');
    } catch (e) {
      print('❌ DevUtils: Error clearing secure storage: $e');
      rethrow;
    }
  }

  /// Delete all app data (including Hive and secure storage)
  ///
  /// ⚠️ USE WITH EXTREME CAUTION!
  /// This will delete EVERYTHING in the app's storage.
  static Future<void> nukeAllData() async {
    try {
      await HiveService.deleteAllData();
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
      print('✅ DevUtils: ALL app data nuked!');
    } catch (e) {
      print('❌ DevUtils: Error nuking data: $e');
      rethrow;
    }
  }
}
