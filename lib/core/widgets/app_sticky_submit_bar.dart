import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

class AppStickySubmitBar extends StatelessWidget {
  const AppStickySubmitBar({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.isBusy = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool isBusy;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.spacingLarge,
        tokens.spacingSmall,
        tokens.spacingLarge,
        tokens.spacingLarge,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceBase,
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Row(
        children: [
          if (secondaryLabel != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onSecondaryPressed,
                child: Text(secondaryLabel!),
              ),
            ),
            SizedBox(width: tokens.spacingSmall),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: isBusy ? null : onPrimaryPressed,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
