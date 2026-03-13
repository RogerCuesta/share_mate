import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_operational_snackbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows info snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                AppOperationalSnackbar.show(
                  context,
                  message: 'Saved',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
  });
}
