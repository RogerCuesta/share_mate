// lib/features/subscriptions/presentation/widgets/service_icon_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/predefined_services.dart';

/// Widget for selecting a predefined service icon
///
/// Displays a grid of 8 predefined services in a 4x2 layout.
/// Each service has its own background color with white icon/text.
/// Selected service shows a white border.
class ServiceIconPicker extends StatelessWidget {
  const ServiceIconPicker({
    required this.onServiceSelected,
    this.selectedService,
    super.key,
  });

  final String? selectedService;
  final ValueChanged<String> onServiceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Service Icon',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: PredefinedServices.services.length,
          itemBuilder: (context, index) {
            final service = PredefinedServices.services[index];
            final isSelected = selectedService == service.name;

            return _ServiceIconItem(
              service: service,
              isSelected: isSelected,
              onTap: () => onServiceSelected(service.name),
            );
          },
        ),
      ],
    );
  }
}

/// Individual service icon item with animated selection
class _ServiceIconItem extends StatelessWidget {
  const _ServiceIconItem({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  final PredefinedService service;
  final bool isSelected;
  final VoidCallback onTap;

  /// Parse hex color string to Color object
  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final serviceColor = _parseColor(service.color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: serviceColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 3,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: serviceColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _buildServiceContent(),
        ),
      ),
    );
  }

  /// Build the icon or text content for the service
  Widget _buildServiceContent() {
    if (service.iconText != null) {
      // Calculate font size based on text length
      final fontSize = _calculateFontSize(service.iconText!);

      return Text(
        service.iconText!,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: service.iconText!.length > 1 ? -0.5 : 0,
        ),
        textAlign: TextAlign.center,
      );
    }

    // Use icon if no text is provided
    return Icon(
      _getIconFromName(service.iconName),
      color: Colors.white,
      size: 32,
    );
  }

  /// Map icon name string to IconData
  IconData _getIconFromName(String? iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'add_circle_outline':
        return Icons.add_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  /// Calculate appropriate font size based on text length
  double _calculateFontSize(String text) {
    if (text.length == 1) {
      return 28; // Single letter (N, P, C)
    } else if (text.length <= 3) {
      return 18; // HBO, CR
    } else {
      return 14; // hulu or longer
    }
  }
}
