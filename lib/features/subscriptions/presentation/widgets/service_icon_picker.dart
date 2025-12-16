// lib/features/subscriptions/presentation/widgets/service_icon_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/predefined_services.dart';

/// Widget for selecting a predefined service icon
///
/// Displays a grid of 8 predefined services + 1 custom option.
/// Each service has its own color and icon/logo representation.
class ServiceIconPicker extends StatelessWidget {
  final String? selectedService;
  final ValueChanged<String> onServiceSelected;

  const ServiceIconPicker({
    super.key,
    this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Service',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
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

/// Individual service icon item
class _ServiceIconItem extends StatelessWidget {
  final PredefinedService service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceIconItem({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final serviceColor = _parseColor(service.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? serviceColor : const Color(0xFF3D3D54),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Service icon/text
            Center(
              child: service.iconText != null
                  ? Text(
                      service.iconText!,
                      style: TextStyle(
                        color: serviceColor,
                        fontSize: service.iconText!.length > 3 ? 12 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Icon(
                      service.icon ?? Icons.help_outline,
                      color: serviceColor,
                      size: 28,
                    ),
            ),

            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: serviceColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
