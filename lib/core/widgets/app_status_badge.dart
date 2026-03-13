import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

enum AppStatusTone {
  synced,
  pending,
  requiresAction,
  info,
  success,
  warning,
  error,
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    required this.tone,
    this.detail,
    super.key,
  });

  final String label;
  final AppStatusTone tone;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final accent = switch (tone) {
      AppStatusTone.synced => tokens.statusSynced,
      AppStatusTone.pending => tokens.statusPending,
      AppStatusTone.requiresAction => tokens.statusRequiresAction,
      AppStatusTone.info => tokens.statusInfo,
      AppStatusTone.success => tokens.statusSuccess,
      AppStatusTone.warning => tokens.statusWarning,
      AppStatusTone.error => tokens.statusError,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSmall + 2,
        vertical: tokens.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(tokens.borderRadiusMedium),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (detail != null) ...[
            SizedBox(height: tokens.spacingXSmall - 1),
            Text(
              detail!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
