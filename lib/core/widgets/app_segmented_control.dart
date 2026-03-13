import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

class AppSegmentedOption<T> {
  const AppSegmentedOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    super.key,
  });

  final List<AppSegmentedOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.borderRadiusLarge + 4),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options
            .map(
              (option) => Expanded(
                child: _SegmentCell<T>(
                  option: option,
                  selected: option.value == selectedValue,
                  onTap: () => onSelected(option.value),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SegmentCell<T> extends StatelessWidget {
  const _SegmentCell({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentedOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.borderRadiusLarge),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? tokens.ctaPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.borderRadiusLarge),
        ),
        child: Text(
          option.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? tokens.textOnAccent : tokens.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
