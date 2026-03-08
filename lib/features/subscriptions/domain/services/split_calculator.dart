class SplitParticipantInput {
  const SplitParticipantInput({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class SplitBreakdownEntry {
  const SplitBreakdownEntry({
    required this.participantId,
    required this.name,
    required this.amount,
    required this.isOwner,
  });

  final String participantId;
  final String name;
  final double amount;
  final bool isOwner;
}

class SplitCalculationResult {
  const SplitCalculationResult({
    required this.totalAmount,
    required this.totalParticipants,
    required this.approximatePerPersonAmount,
    required this.memberAmount,
    required this.ownerAmount,
    required this.breakdown,
  });

  final double totalAmount;
  final int totalParticipants;
  final double approximatePerPersonAmount;
  final double memberAmount;
  final double ownerAmount;
  final List<SplitBreakdownEntry> breakdown;
}

/// Deterministic split engine:
/// - Owner is always included.
/// - Members get floor/equal cents.
/// - Any cent remainder is assigned to owner.
class SplitCalculator {
  const SplitCalculator();

  static const String defaultOwnerId = 'owner';
  static const String defaultOwnerName = 'You';

  SplitCalculationResult calculate({
    required double totalAmount,
    required List<SplitParticipantInput> members,
    String ownerId = defaultOwnerId,
    String ownerName = defaultOwnerName,
  }) {
    final normalizedTotalCents = _toCents(totalAmount);
    final participantCount = members.length + 1; // owner always included
    final memberAmountCents = participantCount <= 0
        ? 0
        : normalizedTotalCents ~/ participantCount;
    final ownerAmountCents =
        normalizedTotalCents - (memberAmountCents * members.length);

    final breakdown = <SplitBreakdownEntry>[
      for (final member in members)
        SplitBreakdownEntry(
          participantId: member.id,
          name: member.name,
          amount: _fromCents(memberAmountCents),
          isOwner: false,
        ),
      SplitBreakdownEntry(
        participantId: ownerId,
        name: ownerName,
        amount: _fromCents(ownerAmountCents),
        isOwner: true,
      ),
    ];

    final normalizedTotalAmount = _fromCents(normalizedTotalCents);
    final approximatePerPerson = participantCount == 0
        ? 0.0
        : normalizedTotalAmount / participantCount;

    return SplitCalculationResult(
      totalAmount: normalizedTotalAmount,
      totalParticipants: participantCount,
      approximatePerPersonAmount: approximatePerPerson,
      memberAmount: _fromCents(memberAmountCents),
      ownerAmount: _fromCents(ownerAmountCents),
      breakdown: breakdown,
    );
  }

  int _toCents(double value) {
    if (value <= 0) {
      return 0;
    }
    return (value * 100).round();
  }

  double _fromCents(int cents) {
    return cents / 100;
  }
}
