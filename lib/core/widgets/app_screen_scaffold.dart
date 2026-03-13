import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/theme_extensions.dart';

class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    required this.child,
    this.appBar,
    this.padding,
    this.backgroundColor,
    this.bottomSpacing = 120,
    super.key,
  }) : slivers = null;

  const AppScreenScaffold.slivers({
    required this.slivers,
    this.appBar,
    this.padding,
    this.backgroundColor,
    this.bottomSpacing = 120,
    super.key,
  }) : child = null;

  final Widget? child;
  final List<Widget>? slivers;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).appTokens;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: tokens.spacingLarge,
          vertical: tokens.spacingSmall,
        );

    return Scaffold(
      backgroundColor: backgroundColor ?? tokens.surfaceBase,
      appBar: appBar,
      body: SafeArea(
        child: slivers != null
            ? CustomScrollView(
                slivers: [
                  ...slivers!,
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomSpacing),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: effectivePadding.add(
                  EdgeInsets.only(bottom: bottomSpacing),
                ),
                child: child!,
              ),
      ),
    );
  }
}
