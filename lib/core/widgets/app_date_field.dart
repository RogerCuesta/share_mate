import 'package:flutter/material.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Select date',
    super.key,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? hint
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(display),
      ),
    );
  }
}
