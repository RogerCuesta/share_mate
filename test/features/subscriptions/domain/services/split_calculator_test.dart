import 'package:flutter_project_agents/features/subscriptions/domain/services/split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitCalculator', () {
    const calculator = SplitCalculator();

    test('always includes owner when no members are selected', () {
      final result = calculator.calculate(
        totalAmount: 24.99,
        members: const [],
      );

      expect(result.totalParticipants, 1);
      expect(result.memberAmount, 24.99);
      expect(result.ownerAmount, 24.99);
      expect(result.breakdown, hasLength(1));
      expect(result.breakdown.single.name, SplitCalculator.defaultOwnerName);
      expect(result.breakdown.single.isOwner, isTrue);
      expect(result.breakdown.single.amount, 24.99);
    });

    test('assigns cent remainder to owner deterministically', () {
      final result = calculator.calculate(
        totalAmount: 10.0,
        members: const [
          SplitParticipantInput(id: 'm1', name: 'Alex'),
          SplitParticipantInput(id: 'm2', name: 'Blair'),
        ],
      );

      expect(result.totalParticipants, 3);
      expect(result.memberAmount, 3.33);
      expect(result.ownerAmount, 3.34);
      expect(result.breakdown[0].amount, 3.33);
      expect(result.breakdown[1].amount, 3.33);
      expect(result.breakdown[2].amount, 3.34);
      expect(result.breakdown[2].isOwner, isTrue);
    });

    test('keeps stable arithmetic for decimal-heavy totals', () {
      final result = calculator.calculate(
        totalAmount: 19.99,
        members: const [
          SplitParticipantInput(id: 'm1', name: 'Alex'),
          SplitParticipantInput(id: 'm2', name: 'Blair'),
          SplitParticipantInput(id: 'm3', name: 'Casey'),
        ],
      );

      expect(result.memberAmount, 4.99);
      expect(result.ownerAmount, 5.02);

      final breakdownSum = result.breakdown.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      );
      expect(breakdownSum, closeTo(19.99, 0.00001));
    });

    test('normalizes amounts via cents conversion', () {
      final result = calculator.calculate(
        totalAmount: 10.005,
        members: const [SplitParticipantInput(id: 'm1', name: 'Alex')],
      );

      expect(result.totalAmount, 10.01);
      expect(result.memberAmount, 5.0);
      expect(result.ownerAmount, 5.01);
    });

    test('returns zero amounts for invalid totals', () {
      final result = calculator.calculate(
        totalAmount: -12.5,
        members: const [SplitParticipantInput(id: 'm1', name: 'Alex')],
      );

      expect(result.totalAmount, 0.0);
      expect(result.memberAmount, 0.0);
      expect(result.ownerAmount, 0.0);
      expect(result.breakdown[0].amount, 0.0);
      expect(result.breakdown[1].amount, 0.0);
    });
  });
}
