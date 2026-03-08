class BillingDateNormalizer {
  const BillingDateNormalizer();

  DateTime toLocalDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int daysInMonth({
    required int year,
    required int month,
  }) {
    final firstOfNextMonth =
        month == 12 ? DateTime(year + 1) : DateTime(year, month + 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  DateTime normalizeForMonth({
    required int billingAnchorDay,
    required DateTime referenceDate,
  }) {
    final localReferenceDate = toLocalDate(referenceDate);
    final maxDay = daysInMonth(
      year: localReferenceDate.year,
      month: localReferenceDate.month,
    );
    final normalizedDay = billingAnchorDay.clamp(1, maxDay);
    return DateTime(
      localReferenceDate.year,
      localReferenceDate.month,
      normalizedDay,
    );
  }

  bool monthOverflows({
    required int billingAnchorDay,
    required DateTime referenceDate,
  }) {
    final localReferenceDate = toLocalDate(referenceDate);
    final maxDay = daysInMonth(
      year: localReferenceDate.year,
      month: localReferenceDate.month,
    );
    return billingAnchorDay > maxDay;
  }
}
