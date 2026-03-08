import 'package:hive_ce/hive.dart';

typedef MigrationBoxOpener = Future<Box<dynamic>> Function(String boxName);
typedef MigrationEncryptedBoxOpener =
    Future<Box<dynamic>> Function(String boxName);
typedef MigrationBoxDeleter = Future<void> Function(String boxName);

/// Immutable metadata persisted by [LocalMigrationRunner].
class LocalMigrationState {
  const LocalMigrationState({
    required this.currentVersion,
    required this.lastSuccessfulMigration,
    required this.inProgress,
    this.inProgressMigration,
    this.failedMigration,
    this.failureCode,
  });

  final int currentVersion;
  final int? lastSuccessfulMigration;
  final bool inProgress;
  final int? inProgressMigration;
  final int? failedMigration;
  final String? failureCode;
}

class LocalMigrationContext {
  const LocalMigrationContext({
    required this.openPlaintextBox,
    required this.openEncryptedBox,
    required this.deleteBox,
    required this.metadataBox,
  });

  final MigrationBoxOpener openPlaintextBox;
  final MigrationEncryptedBoxOpener openEncryptedBox;
  final MigrationBoxDeleter deleteBox;
  final Box<dynamic> metadataBox;
}

class LocalMigrationException implements Exception {
  LocalMigrationException({
    required this.message,
    required this.code,
    this.version,
    this.cause,
  });

  final String message;
  final String code;
  final int? version;
  final Object? cause;

  @override
  String toString() {
    final versionPart = version == null ? '' : ' (v$version)';
    return 'LocalMigrationException[$code]$versionPart: $message';
  }
}

abstract class LocalMigration {
  int get version;
  String get name;

  Future<void> up(LocalMigrationContext context);
}

