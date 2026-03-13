import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/widgets/app_segmented_control.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';

/// Kept for backward compatibility with existing imports.
class BillingSycleSelector extends BillingCycleSelector {
  const BillingSycleSelector({
    required super.selectedCycle,
    required super.onCycleSelected,
    super.key,
  });
}

class BillingCycleSelector extends StatelessWidget {
  const BillingCycleSelector({
    required this.selectedCycle,
    required this.onCycleSelected,
    super.key,
  });

  final BillingCycle selectedCycle;
  final ValueChanged<BillingCycle> onCycleSelected;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<BillingCycle>(
      selectedValue: selectedCycle,
      onSelected: onCycleSelected,
      options: const [
        AppSegmentedOption(
          value: BillingCycle.monthly,
          label: 'Monthly',
        ),
        AppSegmentedOption(
          value: BillingCycle.yearly,
          label: 'Yearly',
        ),
      ],
    );
  }
}
