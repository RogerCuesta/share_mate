import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

enum AppSectionCardTone { base, raised, accent, critical }

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    this.tone = AppSectionCardTone.base,
    this.padding,
    this.margin,
    super.key,
  });

  final Widget child;
  final AppSectionCardTone tone;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final background = switch (tone) {
      AppSectionCardTone.base => tokens.surfaceRaised,
      AppSectionCardTone.raised => tokens.surfaceAccent,
      AppSectionCardTone.accent => tokens.surfaceAccent,
      AppSectionCardTone.critical => tokens.surfaceCritical,
    };
    final border = switch (tone) {
      AppSectionCardTone.base => tokens.borderSubtle,
      AppSectionCardTone.raised => tokens.borderStrong,
      AppSectionCardTone.accent => tokens.statusInfo.withValues(alpha: 0.5),
      AppSectionCardTone.critical => tokens.statusError.withValues(alpha: 0.45),
    };

    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(tokens.spacingMedium + 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.borderRadiusLarge),
        border: Border.all(color: border),
        boxShadow: tone == AppSectionCardTone.base ? null : tokens.cardShadow,
      ),
      child: child,
    );
  }
}
