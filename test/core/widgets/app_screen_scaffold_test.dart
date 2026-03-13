import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_screen_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders child content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppScreenScaffold(
          child: Text('content'),
        ),
      ),
    );

    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('renders sliver content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AppScreenScaffold.slivers(
          slivers: [
            SliverToBoxAdapter(child: Text('sliver-content')),
          ],
        ),
      ),
    );

    expect(find.text('sliver-content'), findsOneWidget);
  });
}
