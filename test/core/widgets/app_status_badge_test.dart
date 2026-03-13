import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_status_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label and detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppStatusBadge(
            label: 'Synced',
            detail: 'Last sync: now',
            tone: AppStatusTone.synced,
          ),
        ),
      ),
    );

    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Last sync: now'), findsOneWidget);
  });

  testWidgets('renders requires-action tone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppStatusBadge(
            label: 'Requires action',
            tone: AppStatusTone.requiresAction,
          ),
        ),
      ),
    );

    expect(find.text('Requires action'), findsOneWidget);
  });
}
