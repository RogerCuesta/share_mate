import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const noHardcodedStyleFiles = <String>[
    'lib/features/home/presentation/screens/home_screen.dart',
    'lib/features/home/presentation/widgets/home_header.dart',
    'lib/features/home/presentation/widgets/debt_home_kpi_card.dart',
    'lib/features/home/presentation/widgets/next_collection_card.dart',
    'lib/features/home/presentation/widgets/stats_cards.dart',
    'lib/features/home/presentation/widgets/action_required_section.dart',
    'lib/features/home/presentation/widgets/active_subscriptions_section.dart',
    'lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart',
    'lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart',
    'lib/features/subscriptions/presentation/widgets/payment_stats_card.dart',
    'lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart',
    'lib/features/subscriptions/presentation/widgets/analytics/overview_cards_section.dart',
    'lib/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart',
    'lib/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart',
  ];

  const noLocalOperationalFeedbackFiles = <String>[
    'lib/features/home/presentation/screens/home_screen.dart',
    'lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart',
    'lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart',
    'lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart',
  ];

  group('Phase 6 source guards', () {
    test(
      'scoped files avoid hardcoded hex colors and local gradient definitions',
      () {
        for (final path in noHardcodedStyleFiles) {
          final source = File(path).readAsStringSync();
          expect(
            RegExp(r'Color\(0xFF').hasMatch(source),
            isFalse,
            reason: 'Hardcoded color literal found in $path',
          );
          expect(
            RegExp(r'LinearGradient\(').hasMatch(source),
            isFalse,
            reason: 'Local gradient definition found in $path',
          );
        }
      },
    );

    test('core surfaces avoid local SnackBar and AlertDialog usage', () {
      for (final path in noLocalOperationalFeedbackFiles) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('SnackBar('),
          isFalse,
          reason: 'Local SnackBar usage detected in $path',
        );
        expect(
          source.contains('AlertDialog('),
          isFalse,
          reason: 'Local AlertDialog usage detected in $path',
        );
      }
    });
  });
}
