import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration.dart';
import 'package:hive_ce/hive.dart';

class LocalMigrationRunner {
  LocalMigrationRunner({
    required List<LocalMigration> migrations,
    this.metadataBoxName = _defaultMetadataBoxName,
    MigrationBoxOpener? openPlaintextBox,
    MigrationEncryptedBoxOpener? openEncryptedBox,
    MigrationBoxDeleter? deleteBox,
  })  : _migrations = List<LocalMigration>.unmodifiable(migrations),
        _openPlaintextBox = openPlaintextBox ?? _defaultPlaintextOpen,
        _openEncryptedBox = openEncryptedBox ?? _defaultEncryptedOpen,
        _deleteBox = deleteBox ?? _defaultDelete {
    _assertUniqueVersions(_migrations);
  }

  static const String _defaultMetadataBoxName = '_local_migration_meta';

  static const String keySchemaVersion = 'storage_schema_version';
  static const String keyInProgress = 'in_progress';
  static const String keyInProgressMigration = 'in_progress_migration';
  static const String keyLastSuccessfulMigration = 'last_successful_migration';
  static const String keyFailedMigration = 'failed_migration';
  static const String keyFailureCode = 'failure_code';

  final List<LocalMigration> _migrations;
  final String metadataBoxName;
  final MigrationBoxOpener _openPlaintextBox;
  final MigrationEncryptedBoxOpener _openEncryptedBox;
  final MigrationBoxDeleter _deleteBox;

  Future<void> runPendingMigrations() async {
    final metadataBox = await _openPlaintextBox(metadataBoxName);
    final currentVersion =
        (metadataBox.get(keySchemaVersion, defaultValue: 0) as int?) ?? 0;

    final pending = _migrations
        .where((migration) => migration.version > currentVersion)
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));

    if (pending.isEmpty) {
      await metadataBox.put(keyInProgress, false);
      await metadataBox.put(keyInProgressMigration, null);
      return;
    }

    final context = LocalMigrationContext(
      openPlaintextBox: _openPlaintextBox,
      openEncryptedBox: _openEncryptedBox,
      deleteBox: _deleteBox,
      metadataBox: metadataBox,
    );

    for (final migration in pending) {
      await _markMigrationStart(metadataBox, migration.version);

      try {
        await migration.up(context);
        await _markMigrationSuccess(metadataBox, migration.version);
      } catch (error) {
        final exception = error is LocalMigrationException
            ? error
            : LocalMigrationException(
                message: 'Migration "${migration.name}" failed',
                code: 'unknown_migration_error',
                version: migration.version,
                cause: error,
              );
        await _markMigrationFailure(metadataBox, migration.version, exception);
        throw exception;
      }
    }
  }

  Future<LocalMigrationState> readState() async {
    final metadataBox = await _openPlaintextBox(metadataBoxName);
    return LocalMigrationState(
      currentVersion:
          (metadataBox.get(keySchemaVersion, defaultValue: 0) as int?) ?? 0,
      lastSuccessfulMigration:
          metadataBox.get(keyLastSuccessfulMigration) as int?,
      inProgress:
          (metadataBox.get(keyInProgress, defaultValue: false) as bool?) ??
              false,
      inProgressMigration: metadataBox.get(keyInProgressMigration) as int?,
      failedMigration: metadataBox.get(keyFailedMigration) as int?,
      failureCode: metadataBox.get(keyFailureCode) as String?,
    );
  }

  static void _assertUniqueVersions(List<LocalMigration> migrations) {
    final versions = <int>{};
    for (final migration in migrations) {
      if (!versions.add(migration.version)) {
        throw ArgumentError(
          'Duplicate migration version detected: ${migration.version}',
        );
      }
    }
  }

  Future<void> _markMigrationStart(
    Box<dynamic> metadataBox,
    int version,
  ) async {
    await metadataBox.put(keyInProgress, true);
    await metadataBox.put(keyInProgressMigration, version);
    await metadataBox.put(keyFailedMigration, null);
    await metadataBox.put(keyFailureCode, null);
  }

  Future<void> _markMigrationSuccess(
    Box<dynamic> metadataBox,
    int version,
  ) async {
    await metadataBox.put(keySchemaVersion, version);
    await metadataBox.put(keyLastSuccessfulMigration, version);
    await metadataBox.put(keyInProgress, false);
    await metadataBox.put(keyInProgressMigration, null);
    await metadataBox.put(keyFailedMigration, null);
    await metadataBox.put(keyFailureCode, null);
  }

  Future<void> _markMigrationFailure(
    Box<dynamic> metadataBox,
    int version,
    LocalMigrationException exception,
  ) async {
    await metadataBox.put(keyInProgress, false);
    await metadataBox.put(keyInProgressMigration, null);
    await metadataBox.put(keyFailedMigration, version);
    await metadataBox.put(keyFailureCode, exception.code);
  }

  static Future<Box<dynamic>> _defaultPlaintextOpen(String boxName) {
    return Hive.openBox<dynamic>(boxName);
  }

  static Future<Box<dynamic>> _defaultEncryptedOpen(String boxName) {
    return HiveService.openBox<dynamic>(boxName, encrypted: true);
  }

  static Future<void> _defaultDelete(String boxName) {
    return HiveService.deleteBox(boxName);
  }
}

