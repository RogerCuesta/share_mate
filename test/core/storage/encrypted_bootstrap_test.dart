import 'dart:io';

import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/local_migration_runner.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/migrations/v1_non_destructive_baseline_migration.dart';
import 'package:flutter_project_agents/core/storage/local_migrations/migrations/v2_encrypt_sensitive_boxes_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('Encrypted bootstrap migration flow', () {
    late Directory hiveDir;
    late List<int> encryptionKey;

    Future<Box<dynamic>> openPlaintext(String boxName) {
      return Hive.openBox<dynamic>(boxName);
    }

    Future<Box<dynamic>> openEncrypted(String boxName) {
      return Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    }

    Future<void> seedPlaintextBoxes() async {
      for (final boxName
          in V2EncryptSensitiveBoxesMigration.firstWaveSensitiveBoxes) {
        final box = await openPlaintext(boxName);
        await box.put(
          '${boxName}_row_1',
          <String, dynamic>{'id': '${boxName}_row_1', 'name': boxName},
        );
        await box.put(
          '${boxName}_row_2',
          <String, dynamic>{
            'id': '${boxName}_row_2',
            'name': '$boxName-second'
          },
        );
        await box.close();
      }
    }

    Future<Map<String, Map<dynamic, dynamic>>> encryptedSnapshot() async {
      final snapshot = <String, Map<dynamic, dynamic>>{};
      for (final boxName
          in V2EncryptSensitiveBoxesMigration.firstWaveSensitiveBoxes) {
        final box = await openEncrypted(boxName);
        snapshot[boxName] = Map<dynamic, dynamic>.from(box.toMap());
        await box.close();
      }
      return snapshot;
    }

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('encrypted_bootstrap');
      Hive.init(hiveDir.path);
      encryptionKey = Hive.generateSecureKey();
      HiveService.clearKeyFailureSafeModeForTesting();
      HiveService.overrideEncryptionKeyProviderForTesting(
        () async => encryptionKey,
      );
    });

    tearDown(() async {
      HiveService.overrideEncryptionKeyProviderForTesting(null);
      HiveService.clearKeyFailureSafeModeForTesting();
      await Hive.close();
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('first run converts first-wave plaintext boxes to encrypted parity',
        () async {
      await seedPlaintextBoxes();
      final runner = LocalMigrationRunner(
        migrations: <LocalMigration>[
          const V1NonDestructiveBaselineMigration(),
          V2EncryptSensitiveBoxesMigration(),
        ],
        openPlaintextBox: openPlaintext,
        openEncryptedBox: openEncrypted,
        deleteBox: Hive.deleteBoxFromDisk,
      );

      await runner.runPendingMigrations();

      final state = await runner.readState();
      expect(state.currentVersion, 2);
      expect(state.lastSuccessfulMigration, 2);
      expect(state.failedMigration, isNull);

      for (final boxName
          in V2EncryptSensitiveBoxesMigration.firstWaveSensitiveBoxes) {
        final encryptedBox = await openEncrypted(boxName);
        expect(encryptedBox.length, 2);
        expect(encryptedBox.get('${boxName}_row_1'), isNotNull);
        expect(encryptedBox.get('${boxName}_row_2'), isNotNull);
        await encryptedBox.close();
      }
    });

    test('second startup is idempotent with zero duplicate mutations',
        () async {
      await seedPlaintextBoxes();
      final runner = LocalMigrationRunner(
        migrations: <LocalMigration>[
          const V1NonDestructiveBaselineMigration(),
          V2EncryptSensitiveBoxesMigration(),
        ],
        openPlaintextBox: openPlaintext,
        openEncryptedBox: openEncrypted,
        deleteBox: Hive.deleteBoxFromDisk,
      );

      await runner.runPendingMigrations();
      final firstSnapshot = await encryptedSnapshot();

      await runner.runPendingMigrations();
      final secondSnapshot = await encryptedSnapshot();

      expect(secondSnapshot, equals(firstSnapshot));
    });

    test('failure rollback restores plaintext source rows safely', () async {
      await seedPlaintextBoxes();
      final failingMigration = V2EncryptSensitiveBoxesMigration(
        hook: (stage, boxName) {
          if (boxName == 'subscriptions' && stage == 'source_deleted') {
            throw StateError('force rollback');
          }
        },
      );

      final runner = LocalMigrationRunner(
        migrations: <LocalMigration>[
          const V1NonDestructiveBaselineMigration(),
          failingMigration,
        ],
        openPlaintextBox: openPlaintext,
        openEncryptedBox: openEncrypted,
        deleteBox: Hive.deleteBoxFromDisk,
      );

      await expectLater(
        runner.runPendingMigrations(),
        throwsA(isA<LocalMigrationException>()),
      );

      final restoredPlaintext = await openPlaintext('subscriptions');
      expect(restoredPlaintext.length, 2);
      expect(restoredPlaintext.get('subscriptions_row_1'), isNotNull);
      expect(restoredPlaintext.get('subscriptions_row_2'), isNotNull);
      await restoredPlaintext.close();

      final state = await runner.readState();
      expect(state.currentVersion, 1);
      expect(state.failedMigration, 2);
    });

    test('key retrieval failure enables guarded startup safe mode', () async {
      // key-failure safe mode + guided recovery + plaintext fallback assertions
      HiveService.overrideEncryptionKeyProviderForTesting(
        () async => throw StateError('missing-key'),
      );
      HiveService.clearKeyFailureSafeModeForTesting();

      await expectLater(
        HiveService.openBox<dynamic>('safe_mode_contacts', encrypted: true),
        throwsA(isA<HiveKeyFailureException>()),
      );

      expect(HiveService.isKeyFailureSafeModeActive, isTrue);

      expect(
        () => HiveService.ensureWritesAllowed('test-write-operation'),
        throwsA(
          isA<HiveWriteBlockedException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('key-failure safe mode'),
              contains('guided recovery'),
              contains('plaintext fallback'),
            ),
          ),
        ),
      );

      await expectLater(
        HiveService.openBox<dynamic>('safe_mode_contacts', encrypted: true),
        throwsA(isA<HiveWriteBlockedException>()),
      );
    });
  });
}
