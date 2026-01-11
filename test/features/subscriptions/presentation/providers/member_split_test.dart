// test/features/subscriptions/presentation/providers/member_split_test.dart

import 'package:flutter_project_agents/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for MemberSplit helper class
///
/// MemberSplit is used for split bill breakdown calculations,
/// ensuring each member's share is properly calculated and tracked.
void main() {
  group('MemberSplit', () {
    test('should create MemberSplit with name and amount', () {
      const split = MemberSplit(name: 'John Doe', amount: 25.50);

      expect(split.name, 'John Doe');
      expect(split.amount, 25.50);
    });

    test('should handle decimal amounts correctly', () {
      const split = MemberSplit(name: 'Jane Smith', amount: 33.33);

      expect(split.amount, 33.33);
    });

    test('should handle zero amount', () {
      const split = MemberSplit(name: 'Test User', amount: 0);

      expect(split.amount, 0.0);
    });

    test('should handle large amounts', () {
      const split = MemberSplit(name: 'Premium User', amount: 999.99);

      expect(split.amount, 999.99);
    });

    test('should allow unicode characters in names', () {
      const split = MemberSplit(name: 'José García', amount: 50);

      expect(split.name, 'José García');
      expect(split.amount, 50.00);
    });
  });
}
