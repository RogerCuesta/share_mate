import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/theme/app_theme.dart';
import 'package:flutter_project_agents/core/widgets/app_sticky_submit_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calls callbacks for primary and secondary actions',
      (tester) async {
    var primaryTapped = false;
    var secondaryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AppStickySubmitBar(
              primaryLabel: 'Save',
              secondaryLabel: 'Cancel',
              onPrimaryPressed: () => primaryTapped = true,
              onSecondaryPressed: () => secondaryTapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Cancel'));

    expect(primaryTapped, isTrue);
    expect(secondaryTapped, isTrue);
  });
}
