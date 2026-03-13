import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_text_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label and updates on change', (tester) async {
    String? value;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: AppTextField(
            label: 'Service',
            hintText: 'Netflix',
            onChanged: (next) => value = next,
          ),
        ),
      ),
    );

    expect(find.text('Service'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Spotify');
    expect(value, 'Spotify');
  });
}
