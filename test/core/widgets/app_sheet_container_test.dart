import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_sheet_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders title and child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: AppSheetContainer(
            title: 'Catalog',
            child: Text('content'),
          ),
        ),
      ),
    );

    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });
}
