import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_confirmation_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns true when confirmed', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AppConfirmationDialog.show(
                  context,
                  title: 'Delete',
                  message: 'Confirm delete?',
                  confirmLabel: 'Delete',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false when cancelled', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AppConfirmationDialog.show(
                  context,
                  title: 'Close',
                  message: 'Cancel?',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
