import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredRequirementIds = <String>{
    'BILL-01',
    'BILL-02',
    'BILL-03',
  };

  const evidenceByRequirement = <String, List<String>>{
    'BILL-01': [
      'lib/features/billing_automation/domain/services/billing_reminder_scheduler.dart',
      'test/features/billing_automation/domain/billing_reminder_scheduler_test.dart',
      'test/features/billing_automation/data/billing_reminder_registry_test.dart',
      'integration_test/billing_automation_cycle_uat_test.dart',
    ],
    'BILL-02': [
      'lib/features/billing_automation/domain/services/billing_automation_orchestrator.dart',
      'test/features/billing_automation/domain/billing_automation_orchestrator_test.dart',
      'test/features/settings/presentation/screens/settings_sync_section_test.dart',
      'test/features/home/presentation/widgets/home_header_sync_badge_test.dart',
      'integration_test/billing_automation_cycle_uat_test.dart',
    ],
    'BILL-03': [
      'supabase/migrations/20260311_phase5_billing_cycle_reset.sql',
      'test/core/sync/conflict_resolution_test.dart',
      'test/core/sync/payment_sync_orchestrator_test.dart',
      'test/features/subscriptions/presentation/providers/payment_reconciliation_provider_test.dart',
      'test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart',
      'integration_test/billing_automation_cycle_uat_test.dart',
    ],
  };

  group('Phase 5 requirement traceability', () {
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
