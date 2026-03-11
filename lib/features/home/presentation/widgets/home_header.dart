import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final syncStatus = ref.watch(homeSyncStatusProvider);
    final automationHealth = ref.watch(billingAutomationHealthProvider);
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                authState.maybeWhen(
                  authenticated: (user) => _UserGreeting(
                    greeting: greeting,
                    userName: user.fullName,
                  ),
                  orElse: () => _UserGreeting(
                    greeting: greeting,
                    userName: 'Guest',
                  ),
                ),
                const SizedBox(height: 10),
                HomeSyncStatusBadge(
                  status: syncStatus,
                  automationHealth: automationHealth,
                ),
              ],
            ),
          ),

          // Notification button
          const SizedBox(width: 16),
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

class HomeSyncStatusBadge extends StatelessWidget {
  const HomeSyncStatusBadge({
    required this.status,
    this.automationHealth = const BillingAutomationHealth.initial(),
    super.key,
  });

  final SyncStatus status;
  final BillingAutomationHealth automationHealth;

  @override
  Widget build(BuildContext context) {
    final label = syncStatusLabel(status);
    final tone = _toneForLabel(label);
    final timestamp = status.lastSuccessfulSyncAt == null
        ? 'Last sync: Not available'
        : 'Last sync: ${DateFormat('MMM d, HH:mm').format(status.lastSuccessfulSyncAt!.toLocal())}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tone.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timestamp,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (automationHealth.needsAttention ||
              automationHealth.scheduledCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              automationHealth.detailLabel,
              style: TextStyle(
                color: automationHealth.needsAttention
                    ? const Color(0xFFEF5350)
                    : Colors.grey[300],
                fontSize: 11,
                fontWeight: automationHealth.needsAttention
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _toneForLabel(String label) {
    return switch (label) {
      syncedStatusLabel => const Color(0xFF26A69A),
      pendingStatusLabel => const Color(0xFFFFB74D),
      _ => const Color(0xFFEF5350),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER GREETING
// ═══════════════════════════════════════════════════════════════════════════

class _UserGreeting extends StatelessWidget {
  const _UserGreeting({
    required this.greeting,
    required this.userName,
  });
  final String greeting;
  final String userName;

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
        icon: const Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
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
  const _NotificationBadge({required this.count});
  final int count;

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
