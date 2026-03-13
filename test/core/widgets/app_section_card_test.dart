import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_section_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders child inside section card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppSectionCard(
            child: Text('inside-card'),
          ),
        ),
      ),
    );

    expect(find.text('inside-card'), findsOneWidget);
  });

  testWidgets('supports critical tone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppSectionCard(
            tone: AppSectionCardTone.critical,
            child: Text('critical'),
          ),
        ),
      ),
    );

    expect(find.text('critical'), findsOneWidget);
  });
}
