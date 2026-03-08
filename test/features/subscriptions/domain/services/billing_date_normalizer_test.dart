import 'package:flutter_project_agents/features/subscriptions/domain/services/billing_date_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingDateNormalizer', () {
    const normalizer = BillingDateNormalizer();

    test('keeps anchor day when month supports it', () {
      final normalized = normalizer.normalizeForMonth(
        billingAnchorDay: 31,
        referenceDate: DateTime(2026, 3, 1),
      );

      expect(normalized.year, 2026);
      expect(normalized.month, 3);
      expect(normalized.day, 31);
      expect(
        normalizer.monthOverflows(
          billingAnchorDay: 31,
          referenceDate: DateTime(2026, 3, 1),
        ),
        isFalse,
      );
    });

    test('normalizes 31st to last day for non-leap-year february', () {
      final normalized = normalizer.normalizeForMonth(
        billingAnchorDay: 31,
        referenceDate: DateTime(2026, 2, 15),
      );

      expect(normalized.year, 2026);
      expect(normalized.month, 2);
      expect(normalized.day, 28);
      expect(
        normalizer.monthOverflows(
          billingAnchorDay: 31,
          referenceDate: DateTime(2026, 2, 15),
        ),
        isTrue,
      );
    });

    test('normalizes 31st to february 29 in leap year', () {
      final normalized = normalizer.normalizeForMonth(
        billingAnchorDay: 31,
        referenceDate: DateTime(2024, 2, 10),
      );

      expect(normalized.year, 2024);
      expect(normalized.month, 2);
      expect(normalized.day, 29);
    });

    test('uses local date-only semantics by clearing time component', () {
      final dateOnly = normalizer.toLocalDate(DateTime(2026, 6, 7, 23, 59, 59));

      expect(dateOnly, DateTime(2026, 6, 7));
    });
  });
}
