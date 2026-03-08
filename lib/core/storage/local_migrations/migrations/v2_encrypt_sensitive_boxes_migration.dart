import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration.dart';
import 'package:hive_ce/hive.dart';

typedef V2MigrationHook = void Function(String stage, String boxName);

class V2EncryptSensitiveBoxesMigration implements LocalMigration {
  V2EncryptSensitiveBoxesMigration({
    List<String>? boxNames,
    this.hook,
  }) : boxNames = boxNames ?? List<String>.from(firstWaveSensitiveBoxes);

  static const List<String> firstWaveSensitiveBoxes = <String>[
    'subscriptions',
    'subscription_members',
    'payment_history',
    'payment_sync_queue',
  ];

  static String doneFlagFor(String boxName) => 'v2_done_$boxName';
  static String backupNameFor(String boxName) => '${boxName}__backup_v2';
  static String encryptedTempNameFor(String boxName) =>
      '${boxName}__encrypted_tmp_v2';

  final List<String> boxNames;
  final V2MigrationHook? hook;

  @override
  int get version => 2;

  @override
  String get name => 'v2_encrypt_sensitive_boxes';

  @override
  Future<void> up(LocalMigrationContext context) async {
    final orderedBoxNames = List<String>.from(boxNames)..sort();
    for (final boxName in orderedBoxNames) {
      final doneKey = doneFlagFor(boxName);
      final isDone =
          (context.metadataBox.get(doneKey, defaultValue: false) as bool?) ??
              false;
      if (isDone) {
        continue;
      }

      await _migrateBox(context, boxName);
      await context.metadataBox.put(doneKey, true);
    }
  }

  Future<void> _migrateBox(
      LocalMigrationContext context, String boxName) async {
    final backupName = backupNameFor(boxName);
    final encryptedTempName = encryptedTempNameFor(boxName);

    try {
      hook?.call('start', boxName);
      final sourceEntries = await _readSourceEntries(context, boxName);
      hook?.call('read_source', boxName);

      final backupBox = await context.openPlaintextBox(backupName);
      try {
        await backupBox.clear();
        await backupBox.putAll(sourceEntries);
      } finally {
        await backupBox.close();
      }
      hook?.call('backup_created', boxName);

      final encryptedTempBox = await _openEncrypted(context, encryptedTempName);
      try {
        await encryptedTempBox.clear();
        await encryptedTempBox.putAll(sourceEntries);
        if (encryptedTempBox.length != sourceEntries.length) {
          throw LocalMigrationException(
            message: 'Encrypted temp parity check failed for $boxName',
            code: 'v2_temp_parity_failed',
            version: version,
          );
        }
      } finally {
        await encryptedTempBox.close();
      }
      hook?.call('temp_encrypted_ready', boxName);

      await context.deleteBox(boxName);
      hook?.call('source_deleted', boxName);

      final finalEncryptedBox = await _openEncrypted(context, boxName);
      final reopenedTempBox = await _openEncrypted(context, encryptedTempName);
      try {
        final encryptedEntries = Map<dynamic, dynamic>.from(
          reopenedTempBox.toMap(),
        );
        await finalEncryptedBox.clear();
        await finalEncryptedBox.putAll(encryptedEntries);
        if (finalEncryptedBox.length != sourceEntries.length) {
          throw LocalMigrationException(
            message: 'Final encrypted parity check failed for $boxName',
            code: 'v2_final_parity_failed',
            version: version,
          );
        }
      } finally {
        await reopenedTempBox.close();
        await finalEncryptedBox.close();
      }

      await context.deleteBox(encryptedTempName);
      await context.deleteBox(backupName);
      hook?.call('completed', boxName);
    } catch (error) {
      await _restoreFromBackup(context, boxName, backupName);
      if (error is LocalMigrationException) {
        rethrow;
      }
      throw LocalMigrationException(
        message: 'Failed to encrypt sensitive box $boxName',
        code: 'v2_migration_failed',
        version: version,
        cause: error,
      );
    }
  }

  Future<Map<dynamic, dynamic>> _readSourceEntries(
    LocalMigrationContext context,
    String boxName,
  ) async {
    try {
      final sourceBox = await context.openPlaintextBox(boxName);
      try {
        return Map<dynamic, dynamic>.from(sourceBox.toMap());
      } finally {
        await sourceBox.close();
      }
    } catch (_) {
      final encryptedBox = await _openEncrypted(context, boxName);
      try {
        return Map<dynamic, dynamic>.from(encryptedBox.toMap());
      } finally {
        await encryptedBox.close();
      }
    }
  }

  Future<Box<dynamic>> _openEncrypted(
    LocalMigrationContext context,
    String boxName,
  ) async {
    try {
      return await context.openEncryptedBox(boxName);
    } on HiveKeyFailureException catch (e) {
      throw LocalMigrationException(
        message: 'Encryption key retrieval failed for $boxName',
        code: 'encryption_key_failure',
        version: version,
        cause: e,
      );
    } on HiveWriteBlockedException catch (e) {
      throw LocalMigrationException(
        message: 'Key-failure safe mode blocks encrypted open for $boxName',
        code: 'encryption_key_failure',
        version: version,
        cause: e,
      );
    }
  }

  Future<void> _restoreFromBackup(
    LocalMigrationContext context,
    String boxName,
    String backupName,
  ) async {
    try {
      final backupBox = await context.openPlaintextBox(backupName);
      Map<dynamic, dynamic> backupEntries;
      try {
        backupEntries = Map<dynamic, dynamic>.from(backupBox.toMap());
      } finally {
        await backupBox.close();
      }

      await context.deleteBox(boxName);
      final restoredBox = await context.openPlaintextBox(boxName);
      try {
        await restoredBox.clear();
        await restoredBox.putAll(backupEntries);
      } finally {
        await restoredBox.close();
      }
    } catch (_) {
      // Keep original failure as source of truth when rollback cannot complete.
    }
  }
}
