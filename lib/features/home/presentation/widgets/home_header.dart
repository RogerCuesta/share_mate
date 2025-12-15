import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

/// Home screen header with greeting and notifications
///
/// Displays:
/// - Dynamic greeting based on time of day
/// - User's full name
/// - Notification icon with badge (if unread notifications exist)
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User greeting
          Expanded(
            child: authState.maybeWhen(
              authenticated: (user) => _UserGreeting(
                greeting: greeting,
                userName: user.fullName,
              ),
              orElse: () => _UserGreeting(
                greeting: greeting,
                userName: 'Guest',
              ),
            ),
          ),

          // Notification button
          const _NotificationButton(),
        ],
      ),
    );
  }

  /// Get greeting based on hour of the day
  ///
  /// - Morning: 0-11
  /// - Afternoon: 12-17
  /// - Evening: 18-23
  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER GREETING
// ═══════════════════════════════════════════════════════════════════════════

class _UserGreeting extends StatelessWidget {
  final String greeting;
  final String userName;

  const _UserGreeting({
    required this.greeting,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting (time-based)
        Text(
          greeting,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),

        // User name
        Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual unread count from notification provider
    const unreadCount = 3;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),

            // Badge (only show if unread count > 0)
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: _NotificationBadge(count: unreadCount),
              ),
          ],
        ),
        onPressed: () {
          // TODO: Navigate to notifications screen
          debugPrint('Navigate to notifications');
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION BADGE
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFF6B6B),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayCount,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
