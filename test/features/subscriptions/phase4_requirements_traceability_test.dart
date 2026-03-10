import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredRequirementIds = <String>{
    'PAYM-01',
    'PAYM-02',
    'PAYM-03',
    'DASH-01',
    'DASH-02',
  };

  const evidenceByRequirement = <String, List<String>>{
    'PAYM-01': [
      'integration_test/payment_debt_home_flow_test.dart',
      'test/features/subscriptions/presentation/widgets/payment_status_toggle_test.dart',
      'test/features/subscriptions/presentation/providers/payment_provider_test.dart',
    ],
    'PAYM-02': [
      'integration_test/payment_debt_home_flow_test.dart',
      'test/features/subscriptions/presentation/providers/payment_provider_test.dart',
      'test/features/home/presentation/providers/debt_home_provider_test.dart',
    ],
    'PAYM-03': [
      'test/features/subscriptions/data/repositories/subscription_repository_impl_sync_test.dart',
      'test/core/sync/payment_sync_orchestrator_test.dart',
      'test/features/subscriptions/presentation/providers/payment_reconciliation_provider_test.dart',
    ],
    'DASH-01': [
      'integration_test/payment_debt_home_flow_test.dart',
      'test/features/home/presentation/providers/debt_home_provider_test.dart',
      'test/features/home/presentation/screens/home_screen_debt_priority_test.dart',
    ],
    'DASH-02': [
      'integration_test/payment_debt_home_flow_test.dart',
      'test/features/subscriptions/presentation/providers/payment_reconciliation_provider_test.dart',
      'test/features/subscriptions/presentation/providers/payment_provider_test.dart',
    ],
  };

  group('Phase 4 requirement traceability', () {
    test('tracks every required ID exactly once', () {
      expect(
        evidenceByRequirement.keys.toSet(),
        equals(requiredRequirementIds),
      );
    });

    test('all evidence references point to existing files', () {
      for (final entry in evidenceByRequirement.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} has no evidence');

        for (final path in entry.value) {
          expect(
            File(path).existsSync(),
            isTrue,
            reason: '${entry.key} evidence file missing: $path',
          );
        }
      }
    });
  });
}
