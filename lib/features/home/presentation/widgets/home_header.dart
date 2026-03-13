import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_status_badge.dart';
import 'package:flutter_project_agents/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_project_agents/features/billing_automation/domain/services/billing_automation_orchestrator.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final syncStatus = ref.watch(homeSyncStatusProvider);
    final automationHealth = ref.watch(billingAutomationHealthProvider);
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final tokens = Theme.of(context).appTokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spacingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                SizedBox(height: tokens.spacingSmall + 2),
                HomeSyncStatusBadge(
                  status: syncStatus,
                  automationHealth: automationHealth,
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spacingMedium),
          const _NotificationButton(),
        ],
      ),
    );
  }

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
    final timestamp = status.lastSuccessfulSyncAt == null
        ? 'Last sync: Not available'
        : 'Last sync: ${DateFormat('MMM d, HH:mm').format(status.lastSuccessfulSyncAt!.toLocal())}';

    final detailText =
        automationHealth.needsAttention || automationHealth.scheduledCount > 0
            ? automationHealth.detailLabel
            : null;

    return AppStatusBadge(
      label: label,
      detail: detailText ?? timestamp,
      tone: _tone(status.kind),
    );
  }

  AppStatusTone _tone(SyncStatusKind kind) {
    return switch (kind) {
      SyncStatusKind.synced => AppStatusTone.synced,
      SyncStatusKind.pending => AppStatusTone.pending,
      SyncStatusKind.requiresAction => AppStatusTone.requiresAction,
    };
  }
}

class _UserGreeting extends StatelessWidget {
  const _UserGreeting({
    required this.greeting,
    required this.userName,
  });

  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: TextStyle(
            color: tokens.textPrimary,
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

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    const unreadCount = 3;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.borderRadiusMedium),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: IconButton(
        icon: const Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, size: 24),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: _NotificationBadge(count: unreadCount),
              ),
          ],
        ),
        onPressed: () {
          debugPrint('Navigate to notifications');
        },
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: tokens.statusError,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayCount,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: tokens.textOnAccent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
