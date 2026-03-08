// lib/core/storage/hive_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_project_agents/core/sync/payment_sync_queue.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_credentials_model.dart';
import 'package:flutter_project_agents/features/auth/data/models/user_model.dart';
import 'package:flutter_project_agents/features/contacts/data/models/contact_model.dart';
import 'package:flutter_project_agents/features/settings/data/models/app_settings_model.dart';
import 'package:flutter_project_agents/features/settings/data/models/user_profile_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/payment_history_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveKeyFailureException implements Exception {
  HiveKeyFailureException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'HiveKeyFailureException: $message';
}

class HiveWriteBlockedException implements Exception {
  HiveWriteBlockedException(this.message);

  final String message;

  @override
  String toString() => 'HiveWriteBlockedException: $message';
}

/// HiveService manages Hive database initialization, box opening, and cleanup
///
/// Call HiveService.init() in main() before runApp()
class HiveService {
  HiveService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyName = 'hive_master_encryption_key';
  static bool _keyFailureSafeMode = false;
  static String? _keyFailureReason;
  static Future<List<int>> Function()? _encryptionKeyProviderOverride;

  static const String _safeModeRecovery =
      'key-failure safe mode active: writes are blocked, guided recovery is required, and plaintext fallback is forbidden.';

  static bool get isKeyFailureSafeModeActive => _keyFailureSafeMode;
  static String? get keyFailureReason => _keyFailureReason;
  static String get safeModeRecoveryMessage => _safeModeRecovery;

  static void activateKeyFailureSafeMode(Object cause) {
    _keyFailureSafeMode = true;
    _keyFailureReason = cause.toString();
  }

  static void clearKeyFailureSafeModeForTesting() {
    _keyFailureSafeMode = false;
    _keyFailureReason = null;
  }

  // ignore: use_setters_to_change_properties
  static void overrideEncryptionKeyProviderForTesting(
    Future<List<int>> Function()? provider,
  ) {
    _encryptionKeyProviderOverride = provider;
  }

  static void ensureWritesAllowed(String operation) {
    if (!_keyFailureSafeMode) {
      return;
    }
    throw HiveWriteBlockedException(
      '$operation blocked because $_safeModeRecovery',
    );
  }

  /// Initialize Hive and open all required boxes
  ///
  /// This should be called once at app startup in main()
  ///
  /// Note: This only initializes Hive and registers adapters.
  /// Actual box opening is handled by data sources via initAuthDependencies()
  static Future<void> init() async {
    // Initialize Hive with Flutter
    await Hive.initFlutter();

    // Register all TypeAdapters here
    Hive
      ..registerAdapter(UserModelAdapter())
      ..registerAdapter(UserCredentialsModelAdapter())
      ..registerAdapter(UserProfileModelAdapter())
      ..registerAdapter(AppSettingsModelAdapter())
      ..registerAdapter(SubscriptionModelAdapter())
      ..registerAdapter(SubscriptionMemberModelAdapter())
      ..registerAdapter(PaymentHistoryModelAdapter())
      ..registerAdapter(PaymentSyncOperationAdapter())
      ..registerAdapter(ContactModelAdapter());
  }

  /// Close all Hive boxes
  ///
  /// Call this when the app is terminating
  static Future<void> closeAll() async {
    await Hive.close();
  }

  /// Open a regular box (for small, frequently accessed data)
  static Future<Box<T>> openBox<T>(
    String boxName, {
    bool encrypted = false,
  }) async {
    if (encrypted) {
      if (_keyFailureSafeMode) {
        throw HiveWriteBlockedException(_safeModeRecovery);
      }
      try {
        final encryptionKey = await _getEncryptionKey();
        return Hive.openBox<T>(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      } catch (e) {
        if (e is HiveWriteBlockedException || e is HiveKeyFailureException) {
          rethrow;
        }
        activateKeyFailureSafeMode(e);
        throw HiveKeyFailureException(
          'Unable to open encrypted box "$boxName". $_safeModeRecovery',
          cause: e,
        );
      }
    }

    return Hive.openBox<T>(boxName);
  }

  /// Open a lazy box (for large objects like files/images)
  ///
  /// Use LazyBox when:
  /// - Individual items are >100KB
  /// - You don't need all data loaded in memory
  /// - Random access pattern (not iterating all items)
  static Future<LazyBox<T>> openLazyBox<T>(
    String boxName, {
    bool encrypted = false,
  }) async {
    if (encrypted) {
      if (_keyFailureSafeMode) {
        throw HiveWriteBlockedException(_safeModeRecovery);
      }
      try {
        final encryptionKey = await _getEncryptionKey();
        return Hive.openLazyBox<T>(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
      } catch (e) {
        if (e is HiveWriteBlockedException || e is HiveKeyFailureException) {
          rethrow;
        }
        activateKeyFailureSafeMode(e);
        throw HiveKeyFailureException(
          'Unable to open encrypted lazy box "$boxName". $_safeModeRecovery',
          cause: e,
        );
      }
    }

    return Hive.openLazyBox<T>(boxName);
  }

  /// Get or generate encryption key for Hive
  ///
  /// The key is stored securely using flutter_secure_storage
  static Future<List<int>> _getEncryptionKey() async {
    try {
      if (_encryptionKeyProviderOverride != null) {
        return _encryptionKeyProviderOverride!.call();
      }

      final keyString = await _secureStorage.read(key: _encryptionKeyName);

      if (keyString == null) {
        final newKey = Hive.generateSecureKey();
        await _secureStorage.write(
          key: _encryptionKeyName,
          value: base64UrlEncode(newKey),
        );
        return newKey;
      }

      return base64Url.decode(keyString);
    } catch (e) {
      activateKeyFailureSafeMode(e);
      throw HiveKeyFailureException(
        'Unable to load local encryption key. $_safeModeRecovery',
        cause: e,
      );
    }
  }

  /// Delete all data (use with caution!)
  ///
  /// This is useful for:
  /// - User logout (clear cached data)
  /// - App reset functionality
  /// - Testing
  static Future<void> deleteAllData() async {
    await Hive.deleteFromDisk();
  }

  /// Clear all auth-related data (users, credentials, current user)
  ///
  /// This is useful for:
  /// - Resetting auth state during development
  /// - Fixing corrupted auth data
  /// - Testing
  static Future<void> clearAuthData() async {
    try {
      // Delete auth boxes if they exist
      if (Hive.isBoxOpen('users')) {
        await Hive.box('users').clear();
      }
      if (Hive.isBoxOpen('credentials')) {
        await Hive.box('credentials').clear();
      }
      if (Hive.isBoxOpen('current_user_id')) {
        await Hive.box('current_user_id').clear();
      }
    } catch (e) {
      // Ignore errors if boxes don't exist
    }
  }

  /// Compact a specific box to reclaim space
  ///
  /// Call this after bulk deletions to reduce box file size
  static Future<void> compactBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.compact();
  }

  /// Delete a specific box from disk
  ///
  /// This completely removes the box file. Useful for:
  /// - Schema migrations (clear old data structure)
  /// - Clearing specific cached data
  /// - Fixing corrupted box data
  static Future<void> deleteBox(String boxName) async {
    try {
      // Close the box if it's open
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }

      // Delete the box from disk
      await Hive.deleteBoxFromDisk(boxName);
    } catch (e) {
      // Ignore errors if box doesn't exist
      debugPrint('Error deleting box $boxName: $e');
    }
  }

  // Example: Open task box with auto-compaction
  // static Future<void> _openTaskBox() async {
  //   await Hive.openBox<TaskModel>(
  //     'taskBox',
  //     compactionStrategy: (entries, deletedEntries) {
  //       // Compact when more than 20 items are deleted
  //       return deletedEntries > 20;
  //     },
  //   );
  // }
}
