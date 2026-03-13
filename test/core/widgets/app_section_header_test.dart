import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_section_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppSectionHeader(
            title: 'Pending',
            count: 2,
          ),
        ),
      ),
    );

    expect(find.text('Pending (2)'), findsOneWidget);
  });

  testWidgets('renders subtitle and trailing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: AppSectionHeader(
            title: 'Section',
            subtitle: 'Subcopy',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Action'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Subcopy'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
  });
}
