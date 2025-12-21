// test/features/subscriptions/presentation/widgets/add_member_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/features/subscriptions/domain/entities/subscription_member_input.dart';
import 'package:flutter_project_agents/features/subscriptions/presentation/widgets/add_member_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddMemberDialog', () {
    testWidgets('should display dialog with form fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Verify dialog title
      expect(find.text('Add Member'), findsOneWidget);

      // Verify form fields
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);

      // Verify buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      // Verify hint texts
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('should show validation error when name is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Tap Add button without entering data
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('should show validation error when name is too short',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Enter single character name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        'J',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.text('Name must be at least 2 characters'),
        findsOneWidget,
      );
    });

    testWidgets('should show validation error when name is only numbers',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Enter numbers-only name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        '12345',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Name cannot be only numbers'), findsOneWidget);
    });

    testWidgets('should show validation error when email is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Enter valid name but no email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        'John Doe',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Enter valid name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        'John Doe',
      );

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'john@example.com'),
        'invalid-email',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.text('Please enter a valid email address'),
        findsOneWidget,
      );
    });

    testWidgets('should close dialog when Cancel is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog<SubscriptionMemberInput>(
                    context: context,
                    builder: (context) => const AddMemberDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Add Member'), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Add Member'), findsNothing);
    });

    testWidgets('should close dialog when X button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog<SubscriptionMemberInput>(
                    context: context,
                    builder: (context) => const AddMemberDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find and tap close icon button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Add Member'), findsNothing);
    });

    testWidgets('should return member data when Add is tapped with valid data',
        (tester) async {
      SubscriptionMemberInput? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<SubscriptionMemberInput>(
                    context: context,
                    builder: (context) => const AddMemberDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter valid name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        'John Doe',
      );

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'john@example.com'),
        'john@example.com',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.name, 'John Doe');
      expect(result!.email, 'john@example.com');
      expect(result!.id, isNotEmpty);
      expect(result!.avatar, isNull);
    });

    testWidgets('should normalize email to lowercase', (tester) async {
      SubscriptionMemberInput? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<SubscriptionMemberInput>(
                    context: context,
                    builder: (context) => const AddMemberDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter valid name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        'John Doe',
      );

      // Enter email with uppercase letters
      await tester.enterText(
        find.widgetWithText(TextFormField, 'john@example.com'),
        'John@Example.COM',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify email is normalized to lowercase
      expect(result, isNotNull);
      expect(result!.email, 'john@example.com');
    });

    testWidgets('should trim name whitespace', (tester) async {
      SubscriptionMemberInput? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<SubscriptionMemberInput>(
                    context: context,
                    builder: (context) => const AddMemberDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter name with whitespace
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        '  John Doe  ',
      );

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'john@example.com'),
        'john@example.com',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify name is trimmed
      expect(result, isNotNull);
      expect(result!.name, 'John Doe');
    });

    testWidgets('should display icons for name and email fields',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddMemberDialog(),
          ),
        ),
      );

      // Verify person icon for name field
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Verify email icon for email field
      expect(find.byIcon(Icons.email), findsOneWidget);
    });
  });
}
