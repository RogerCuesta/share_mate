import 'dart:io';

import 'package:flutter_project_agents/core/storage/local_migrations/local_migration.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class _FakeMigration implements LocalMigration {
  _FakeMigration({
    required this.version,
    required this.name,
    required this.onRun,
  });

  @override
  final int version;

  @override
  final String name;

  final Future<void> Function(LocalMigrationContext context) onRun;

  @override
  Future<void> up(LocalMigrationContext context) => onRun(context);
}

void main() {
  group('LocalMigrationRunner', () {
    late Directory hiveDir;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('migration_runner_test');
      Hive.init(hiveDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    Future<Box<dynamic>> openPlaintext(String boxName) {
      return Hive.openBox<dynamic>(boxName);
    }

    test('runs pending migrations once in ascending version order', () async {
      final executedVersions = <int>[];

      final runner = LocalMigrationRunner(
        migrations: [
          _FakeMigration(
            version: 2,
            name: 'v2',
            onRun: (_) async => executedVersions.add(2),
          ),
          _FakeMigration(
            version: 1,
            name: 'v1',
            onRun: (_) async => executedVersions.add(1),
          ),
        ],
        openPlaintextBox: openPlaintext,
        openEncryptedBox: openPlaintext,
        deleteBox: (boxName) => Hive.deleteBoxFromDisk(boxName),
      );

      await runner.runPendingMigrations();
      await runner.runPendingMigrations();

      expect(executedVersions, equals([1, 2]));

      final state = await runner.readState();
      expect(state.currentVersion, 2);
      expect(state.lastSuccessfulMigration, 2);
      expect(state.inProgress, isFalse);
      expect(state.failedMigration, isNull);
      expect(state.failureCode, isNull);
    });

    test('preserves existing box rows when a migration fails', () async {
      final subscriptionsBox = await Hive.openBox<dynamic>('subscriptions');
      await subscriptionsBox.put('sub_1', {'id': 'sub_1', 'name': 'Netflix'});

      final runner = LocalMigrationRunner(
        migrations: [
          _FakeMigration(
            version: 1,
            name: 'baseline',
            onRun: (_) async {},
          ),
          _FakeMigration(
            version: 2,
            name: 'explode',
            onRun: (_) async {
              throw LocalMigrationException(
                message: 'boom',
                code: 'forced_failure',
              );
            },
          ),
        ],
        openPlaintextBox: openPlaintext,
        openEncryptedBox: openPlaintext,
        deleteBox: (boxName) => Hive.deleteBoxFromDisk(boxName),
      );

      await expectLater(
        runner.runPendingMigrations(),
        throwsA(isA<LocalMigrationException>()),
      );

      final preservedBox = await Hive.openBox<dynamic>('subscriptions');
      expect(preservedBox.get('sub_1'), isNotNull);

      final state = await runner.readState();
      expect(state.currentVersion, 1);
      expect(state.lastSuccessfulMigration, 1);
      expect(state.failedMigration, 2);
      expect(state.failureCode, 'forced_failure');
      expect(state.inProgress, isFalse);
    });
  });
}
