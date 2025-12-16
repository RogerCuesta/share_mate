import 'package:flutter/material.dart';

/// Predefined colors for popular subscription services
class SubscriptionColors {
  static const List<String> predefinedColors = [
    '#E50914', // Netflix red
    '#1DB954', // Spotify green
    '#0063E5', // Disney+ blue
    '#FF0000', // YouTube red
    '#00A8E1', // Amazon Prime blue
    '#6B4FBB', // Twitch purple
    '#FF6C37', // Crunchyroll orange
    '#1877F2', // Facebook blue
    '#25D366', // WhatsApp green
    '#5865F2', // Discord blurple
    '#6C63FF', // Default purple
    '#FF6B9D', // Pink
  ];

  /// Convert hex color string to Color object
  static Color hexToColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// Color picker widget for selecting subscription colors
///
/// Displays a grid of predefined colors with the selected color highlighted.
class ColorPickerWidget extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPickerWidget({
    required this.selectedColor,
    required this.onColorSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: SubscriptionColors.predefinedColors.length,
          itemBuilder: (context, index) {
            final colorHex = SubscriptionColors.predefinedColors[index];
            final isSelected = colorHex.toUpperCase() == selectedColor.toUpperCase();

            return _ColorOption(
              color: colorHex,
              isSelected: isSelected,
              onTap: () => onColorSelected(colorHex),
            );
          },
        ),
      ],
    );
  }
}

/// Individual color option in the color picker
class _ColorOption extends StatelessWidget {
  final String color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: SubscriptionColors.hexToColor(color),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 3,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SubscriptionColors.hexToColor(color).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}
