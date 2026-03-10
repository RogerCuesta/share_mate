class DebtHomeSnapshot {
  const DebtHomeSnapshot({
    required this.totalPendingDebt,
    required this.nextCollection,
  });

  const DebtHomeSnapshot.debtFree()
      : totalPendingDebt = 0,
        nextCollection = null;

  final double totalPendingDebt;
  final NextCollectionCandidate? nextCollection;

  bool get hasDebt => totalPendingDebt > 0;
  bool get isDebtFree => !hasDebt;
}

class NextCollectionCandidate {
  const NextCollectionCandidate({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.dueDate,
    required this.pendingAmount,
    required this.isOverdue,
  });

  final String subscriptionId;
  final String subscriptionName;
  final DateTime dueDate;
  final double pendingAmount;
  final bool isOverdue;
}
