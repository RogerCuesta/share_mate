import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

class AppSheetContainer extends StatelessWidget {
  const AppSheetContainer({
    required this.child,
    this.title,
    this.padding,
    super.key,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceBase,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.borderRadiusLarge + 4),
        ),
      ),
      child: Padding(
        padding: padding ??
            EdgeInsets.fromLTRB(
              tokens.spacingLarge,
              tokens.spacingSmall,
              tokens.spacingLarge,
              tokens.spacingLarge,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.spacingMedium),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
