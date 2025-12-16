import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription.dart';

/// Selector widget for choosing billing cycle (monthly/yearly)
///
/// Displays two options as segmented buttons with Material 3 design.
class BillingSycleSelector extends StatelessWidget {
  final BillingCycle selectedCycle;
  final ValueChanged<BillingCycle> onCycleSelected;

  const BillingSycleSelector({
    required this.selectedCycle,
    required this.onCycleSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing Cycle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CycleOption(
                label: 'Monthly',
                icon: Icons.calendar_today,
                isSelected: selectedCycle == BillingCycle.monthly,
                onTap: () => onCycleSelected(BillingCycle.monthly),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CycleOption(
                label: 'Yearly',
                icon: Icons.calendar_month,
                isSelected: selectedCycle == BillingCycle.yearly,
                onTap: () => onCycleSelected(BillingCycle.yearly),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual billing cycle option button
class _CycleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CycleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF)
              : const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF6C63FF), width: 2)
              : Border.all(color: const Color(0xFF3D3D54), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
