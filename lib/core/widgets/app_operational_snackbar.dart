import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

enum AppOperationalTone { info, success, warning, error }

class AppOperationalSnackbar {
  AppOperationalSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppOperationalTone tone = AppOperationalTone.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final tokens = Theme.of(context).appTokens;
    final accent = switch (tone) {
      AppOperationalTone.info => tokens.statusInfo,
      AppOperationalTone.success => tokens.statusSuccess,
      AppOperationalTone.warning => tokens.statusWarning,
      AppOperationalTone.error => tokens.statusError,
    };
    final icon = switch (tone) {
      AppOperationalTone.info => Icons.info_outline,
      AppOperationalTone.success => Icons.check_circle_outline,
      AppOperationalTone.warning => Icons.warning_amber_rounded,
      AppOperationalTone.error => Icons.error_outline,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: tokens.surfaceRaised,
          content: Row(
            children: [
              Icon(icon, color: accent, size: 18),
              SizedBox(width: tokens.spacingSmall + 2),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: tokens.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
