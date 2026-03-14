import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const requiredRequirementIds = <String>{
    'UX-01',
    'UX-02',
  };

  const evidenceByRequirement = <String, List<String>>{
    'UX-01': [
      'design-system/share-mate/MASTER.md',
      'lib/core/theme/theme_extensions.dart',
      'lib/core/widgets/app_section_card.dart',
      'lib/features/home/presentation/screens/home_screen.dart',
      'lib/features/home/presentation/widgets/home_header.dart',
      'lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart',
      'lib/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart',
      'lib/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart',
      '.planning/phases/06-ux-system-consistency/06-01-SUMMARY.md',
      '.planning/phases/06-ux-system-consistency/06-02-SUMMARY.md',
      '.planning/phases/06-ux-system-consistency/06-03-SUMMARY.md',
      '.planning/phases/06-ux-system-consistency/06-04-SUMMARY.md',
      '.planning/phases/06-ux-system-consistency/06-05-SUMMARY.md',
    ],
    'UX-02': [
      'lib/core/widgets/app_screen_scaffold.dart',
      'lib/core/widgets/app_status_badge.dart',
      'lib/core/widgets/app_operational_snackbar.dart',
      'lib/core/widgets/app_confirmation_dialog.dart',
      'lib/features/subscriptions/presentation/widgets/billing_cycle_selector.dart',
      'lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart',
      'lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart',
      'test/core/theme/app_theme_extension_test.dart',
      'test/features/subscriptions/presentation/widgets/billing_cycle_selector_test.dart',
      'test/features/home/presentation/screens/home_screen_debt_priority_test.dart',
      'test/features/home/presentation/screens/home_screen_golden_test.dart',
      'test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart',
      'test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart',
      'test/goldens/phase6/home_screen_first_fold.png',
      'test/goldens/phase6/create_group_subscription_screen_default.png',
      'test/goldens/phase6/create_group_subscription_screen_with_members.png',
      'test/goldens/phase6/subscription_detail_screen_summary_first.png',
    ],
  };

  group('Phase 6 requirement traceability', () {
    test('tracks every required ID exactly once', () {
      expect(evidenceByRequirement.keys.toSet(), equals(requiredRequirementIds));
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
