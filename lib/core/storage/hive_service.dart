// lib/core/storage/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// HiveService manages Hive database initialization, box opening, and cleanup
/// 
/// Call HiveService.init() in main() before runApp()
class HiveService {
  HiveService._();
  
  static const _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyName = 'hive_master_encryption_key';
  
  /// Initialize Hive and open all required boxes
  /// 
  /// This should be called once at app startup in main()
  static Future<void> init() async {
    // Initialize Hive with Flutter
    await Hive.initFlutter();
    
    // Register all TypeAdapters here
    // Example: Hive.registerAdapter(TaskModelAdapter());
    // TODO: Register your TypeAdapters after code generation
    
    // Open boxes (add your boxes here)
    // Example: await _openTaskBox();
    // TODO: Open your boxes
    
    print('✅ HiveService initialized successfully');
  }
  
  /// Close all Hive boxes
  /// 
  /// Call this when the app is terminating
  static Future<void> closeAll() async {
    await Hive.close();
    print('✅ All Hive boxes closed');
  }
  
  /// Open a regular box (for small, frequently accessed data)
  static Future<Box<T>> openBox<T>(
    String boxName, {
    bool encrypted = false,
  }) async {
    if (encrypted) {
      final encryptionKey = await _getEncryptionKey();
      return await Hive.openBox<T>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    }
    
    return await Hive.openBox<T>(boxName);
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
      final encryptionKey = await _getEncryptionKey();
      return await Hive.openLazyBox<T>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    }
    
    return await Hive.openLazyBox<T>(boxName);
  }
  
  /// Get or generate encryption key for Hive
  /// 
  /// The key is stored securely using flutter_secure_storage
  static Future<List<int>> _getEncryptionKey() async {
    var keyString = await _secureStorage.read(key: _encryptionKeyName);
    
    if (keyString == null) {
      // Generate new encryption key
      final newKey = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(newKey),
      );
      return newKey;
    }
    
    return base64Url.decode(keyString);
  }
  
  /// Delete all data (use with caution!)
  /// 
  /// This is useful for:
  /// - User logout (clear cached data)
  /// - App reset functionality
  /// - Testing
  static Future<void> deleteAllData() async {
    await Hive.deleteFromDisk();
    print('⚠️  All Hive data deleted');
  }
  
  /// Compact a specific box to reclaim space
  /// 
  /// Call this after bulk deletions to reduce box file size
  static Future<void> compactBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.compact();
    print('✅ Box "$boxName" compacted');
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
