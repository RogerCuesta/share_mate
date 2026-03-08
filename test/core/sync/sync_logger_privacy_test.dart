import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_project_agents/core/sync/sync_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncLogger privacy contract', () {
    test('buildPayload keeps only technical metadata keys', () {
      const logger = SyncLogger(scope: 'sync-test');

      final payload = logger.buildPayload(
        level: 'INFO',
        event: 'sync_event',
        operationId: 'operation-123',
        actionType: 'paid',
        retryCount: 2,
        errorClass: 'network_timeout',
        errorCode: '504',
        occurredAt: DateTime.utc(2026, 3, 8, 12),
        metadata: {
          'retry_window_ms': 2000,
          'transport': 'wifi',
          'amount_value': 31.5,
          'notes_text': 'sensitive value',
          'member_identifier': 'user-42',
        },
      );

      expect(payload['scope'], 'sync-test');
      expect(payload['event'], 'sync_event');
      expect(payload['operation_hash'], isNotNull);
      expect(payload['operation_hash'], isNot('operation-123'));

      final metadata = payload['metadata']! as Map<String, Object?>;
      expect(metadata['retry_window_ms'], 2000);
      expect(metadata['transport'], 'wifi');
      expect(metadata.containsKey('amount_value'), isFalse);
      expect(metadata.containsKey('notes_text'), isFalse);
      expect(metadata.containsKey('member_identifier'), isFalse);
    });

    test('logSync output excludes raw operation id and sensitive payload text',
        () {
      const logger = SyncLogger(scope: 'sync-test');
      final captured = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          captured.add(message);
        }
      };
      addTearDown(() {
        debugPrint = previousDebugPrint;
      });

      logger.logSync(
        event: 'sync_retry',
        operationId: 'raw-operation-id',
        actionType: 'unpaid',
        retryCount: 1,
        metadata: {
          'network_state': 'offline',
          'notes_text': 'private note',
        },
      );

      expect(captured, isNotEmpty);
      final line = captured.single;
      expect(line.contains('raw-operation-id'), isFalse);
      expect(line.contains('private note'), isFalse);

      final jsonStart = line.indexOf('{');
      final payload =
          jsonDecode(line.substring(jsonStart)) as Map<String, Object?>;
      expect(payload['operation_hash'], isNotNull);
      expect(payload['retry_count'], 1);

      final metadata = payload['metadata']! as Map<String, Object?>;
      expect(metadata.containsKey('notes_text'), isFalse);
      expect(metadata['network_state'], 'offline');
    });
  });
}
