import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/sync/sync_status.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_project_agents/core/widgets/app_section_header.dart';
import 'package:flutter_project_agents/core/widgets/app_status_badge.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/providers/sync_status_provider.dart';
import 'package:intl/intl.dart';

class SubscriptionDetailSyncStatusCard extends StatelessWidget {
  const SubscriptionDetailSyncStatusCard({
    required this.syncStatus,
    super.key,
  });

  final SyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final statusLabel = syncStatusLabel(syncStatus);
    final helperText = switch (syncStatus.kind) {
      SyncStatusKind.synced =>
        'Changes for this subscription are synchronized.',
      SyncStatusKind.pending =>
        'Pending changes are syncing in the background.',
      SyncStatusKind.requiresAction =>
        'Requires action: recover terminal sync failures in Settings.',
    };

    final lastSyncText = syncStatus.lastSuccessfulSyncAt == null
        ? 'Last successful sync: Not available'
        : 'Last successful sync: ${DateFormat('MMM dd, HH:mm').format(syncStatus.lastSuccessfulSyncAt!.toLocal())}';

    return AppSectionCard(
      tone: _tone(syncStatus.kind),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, size: 20, color: tokens.iconPrimary),
              SizedBox(width: tokens.spacingSmall),
              const Expanded(
                child: AppSectionHeader(
                  title: 'Sync status',
                ),
              ),
              AppStatusBadge(
                label: statusLabel,
                tone: _badgeTone(syncStatus.kind),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingSmall),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
          SizedBox(height: tokens.spacingXSmall),
          Text(
            lastSyncText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tokens.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  AppSectionCardTone _tone(SyncStatusKind kind) {
    return switch (kind) {
      SyncStatusKind.synced => AppSectionCardTone.base,
      SyncStatusKind.pending => AppSectionCardTone.raised,
      SyncStatusKind.requiresAction => AppSectionCardTone.critical,
    };
  }

  AppStatusTone _badgeTone(SyncStatusKind kind) {
    return switch (kind) {
      SyncStatusKind.synced => AppStatusTone.synced,
      SyncStatusKind.pending => AppStatusTone.pending,
      SyncStatusKind.requiresAction => AppStatusTone.requiresAction,
    };
  }
}
