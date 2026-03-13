import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_date_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders date and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: AppDateField(
            label: 'Renewal date',
            value: DateTime(2026, 3, 20),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('2026-03-20'), findsOneWidget);
    await tester.tap(find.byType(AppDateField));
    expect(tapped, isTrue);
  });
}
