import 'dart:async';

import 'package:flutter_project_agents/core/sync/sync_error_classifier.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncErrorClassifier', () {
    const classifier = SyncErrorClassifier();

    test('classifies timeout exceptions as retryable', () {
      final classification = classifier.classify(
        TimeoutException('request timed out'),
      );

      expect(classification.isRetryable, isTrue);
      expect(classification.errorClass, 'network');
      expect(classification.errorCode, 'timeout');
    });

    test('classifies transient remote errors as retryable', () {
      final classification = classifier.classify(
        SubscriptionRemoteException(
          'Database error marking payment as paid: status 503 unavailable',
        ),
      );

      expect(classification.isRetryable, isTrue);
      expect(classification.errorClass, 'remote_transient');
      expect(classification.errorCode, '503');
      expect(classification.terminalReason, 'transient_remote_failure');
    });

    test('classifies non-retryable remote errors as terminal', () {
      final classification = classifier.classify(
        SubscriptionRemoteException(
          'Database error marking payment as paid: permission denied code 42501',
        ),
      );

      expect(classification.isRetryable, isFalse);
      expect(classification.errorClass, 'remote_terminal');
      expect(classification.errorCode, '42501');
      expect(classification.terminalReason, 'non_retryable_remote_failure');
    });

    test('classifies unknown errors as terminal fallback', () {
      final classification = classifier.classify(StateError('unexpected boom'));

      expect(classification.isRetryable, isFalse);
      expect(classification.errorClass, 'unknown');
      expect(classification.terminalReason, 'unexpected_error');
    });
  });
}
