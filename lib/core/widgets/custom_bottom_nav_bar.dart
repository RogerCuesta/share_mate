import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Custom Bottom Navigation Bar with notched design for centered FAB
///
/// Features:
/// - 4 navigation items (Home, Friends, Analytics, Settings)
/// - Circular notch in center for FAB
/// - Active state with color transition
/// - Filled/Outlined icons based on state
/// - Glassmorphism background
/// - Smooth animations
class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedBottomNavIndexProvider);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFF1F1F2E).withValues(alpha: 0.95),
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    isActive: selectedIndex == 0,
                    onTap: () => ref
                        .read(selectedBottomNavIndexProvider.notifier)
                        .setIndex(0),
                  ),
                  _NavBarItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Friends',
                    isActive: selectedIndex == 1,
                    onTap: () => ref
                        .read(selectedBottomNavIndexProvider.notifier)
                        .setIndex(1),
                  ),
                  // Spacer for the notch/FAB
                  const SizedBox(width: 48),
                  _NavBarItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    label: 'Analytics',
                    isActive: selectedIndex == 2,
                    onTap: () => ref
                        .read(selectedBottomNavIndexProvider.notifier)
                        .setIndex(2),
                  ),
                  _NavBarItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    isActive: selectedIndex == 3,
                    onTap: () => ref
                        .read(selectedBottomNavIndexProvider.notifier)
                        .setIndex(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NAV BAR ITEM
// ═══════════════════════════════════════════════════════════════════════════

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: const Color(0xFF6C63FF),
    ).animate(_controller);

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
      highlightColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isActive
              ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with scale animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  return Icon(
                    widget.isActive ? widget.activeIcon : widget.icon,
                    color: _colorAnimation.value,
                    size: 26,
                  );
                },
              ),
            ),
            const SizedBox(height: 4),

            // Label with color animation
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return Text(
                  widget.label,
                  style: TextStyle(
                    color: _colorAnimation.value,
                    fontSize: 12,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
