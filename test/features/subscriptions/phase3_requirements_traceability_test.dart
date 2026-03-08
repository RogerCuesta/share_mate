import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredRequirementIds = <String>{
    'CATA-01',
    'CATA-02',
    'CATA-03',
    'CNTC-01',
    'CNTC-02',
    'SPLT-01',
    'SPLT-02',
    'SPLT-03',
  };

  const evidenceByRequirement = <String, List<String>>{
    'CATA-01': [
      'integration_test/subscription_setup_flow_test.dart',
      'test/features/subscriptions/presentation/screens/create_group_subscription_screen_test.dart',
    ],
    'CATA-02': [
      'integration_test/subscription_setup_flow_test.dart',
      'test/features/subscriptions/presentation/screens/create_group_subscription_screen_test.dart',
    ],
    'CATA-03': [
      'integration_test/subscription_setup_offline_catalog_test.dart',
      'test/features/subscriptions/presentation/widgets/service_template_sheet_test.dart',
    ],
    'CNTC-01': [
      'test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_e2e_test.dart',
      'test/features/subscriptions/presentation/widgets/contacts_selection_sheet_test.dart',
    ],
    'CNTC-02': [
      'integration_test/subscription_setup_flow_test.dart',
      'test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_e2e_test.dart',
      'test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_contacts_test.dart',
    ],
    'SPLT-01': [
      'integration_test/subscription_setup_flow_test.dart',
      'test/features/subscriptions/domain/services/split_calculator_test.dart',
    ],
    'SPLT-02': [
      'integration_test/subscription_setup_flow_test.dart',
      'test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_split_test.dart',
      'test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_e2e_test.dart',
    ],
    'SPLT-03': [
      'integration_test/subscription_setup_flow_test.dart',
      'test/features/subscriptions/domain/services/billing_date_normalizer_test.dart',
    ],
  };

  group('Phase 3 requirement traceability', () {
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
