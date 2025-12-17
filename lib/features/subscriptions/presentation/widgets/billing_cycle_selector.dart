import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';

/// Pill-shaped toggle selector for choosing billing cycle (monthly/yearly)
///
/// Displays two options in a compact pill-shaped container with smooth animations.
/// The selected option has a purple background while the inactive option is transparent.
class BillingSycleSelector extends StatelessWidget {
  const BillingSycleSelector({
    required this.selectedCycle,
    required this.onCycleSelected,
    super.key,
  });

  final BillingCycle selectedCycle;
  final ValueChanged<BillingCycle> onCycleSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing Cycle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _CycleOption(
                  label: 'Monthly',
                  isSelected: selectedCycle == BillingCycle.monthly,
                  onTap: () => onCycleSelected(BillingCycle.monthly),
                ),
              ),
              Expanded(
                child: _CycleOption(
                  label: 'Yearly',
                  isSelected: selectedCycle == BillingCycle.yearly,
                  onTap: () => onCycleSelected(BillingCycle.yearly),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual billing cycle option within the pill toggle
class _CycleOption extends StatelessWidget {
  const _CycleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B4FBB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
