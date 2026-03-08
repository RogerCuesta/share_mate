import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/services/billing_date_normalizer.dart';

class BillingDayHint extends StatelessWidget {
  const BillingDayHint({
    required this.billingAnchorDay,
    required this.referenceDate,
    super.key,
  });

  final int billingAnchorDay;
  final DateTime referenceDate;

  @override
  Widget build(BuildContext context) {
    const normalizer = BillingDateNormalizer();
    if (!normalizer.monthOverflows(
      billingAnchorDay: billingAnchorDay,
      referenceDate: referenceDate,
    )) {
      return const SizedBox.shrink();
    }

    final normalizedDate = normalizer.normalizeForMonth(
      billingAnchorDay: billingAnchorDay,
      referenceDate: referenceDate,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3D54)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: Color(0xFF8AA4FF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Day $billingAnchorDay does not exist in '
              '${_monthName(referenceDate.month)}. This month uses day '
              '${normalizedDate.day}, then returns to day $billingAnchorDay when available.',
              style: const TextStyle(
                color: Color(0xFFD0D4FF),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
      default:
        return 'December';
    }
  }
}
