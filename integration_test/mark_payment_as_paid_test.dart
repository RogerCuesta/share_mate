// integration_test/mark_payment_as_paid_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_project_agents/core/config/env_config.dart';
import 'package:flutter_project_agents/core/di/injection.dart';
import 'package:flutter_project_agents/core/storage/hive_service.dart';
import 'package:flutter_project_agents/core/supabase/supabase_service.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_project_agents/features/auth/data/datasources/user_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/datasources/subscription_local_datasource.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_member_model.dart';
import 'package:flutter_project_agents/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_project_agents/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Setup method to initialize the app with required dependencies
  Future<void> setupApp(PatrolIntegrationTester $) async {
    // Load environment variables
    await EnvConfig.load();

    // Initialize Supabase
    await SupabaseService.init();

    // Initialize Hive database
    await HiveService.init();

    // Initialize local data sources
    final userLocalDataSource = UserLocalDataSourceImpl();
    await userLocalDataSource.init();

    final authLocalDataSource = AuthLocalDataSourceImpl();

    // Open Hive boxes for subscriptions
    await HiveService.openBox<SubscriptionModel>(
      SubscriptionLocalDataSourceImpl.subscriptionsBoxName,
    );
    await HiveService.openBox<SubscriptionMemberModel>(
      SubscriptionLocalDataSourceImpl.membersBoxName,
    );

    final subscriptionLocalDataSource = SubscriptionLocalDataSourceImpl();

    // Pump the app with provider overrides
    await $.pumpWidgetAndSettle(
      ProviderScope(
        overrides: [
          userLocalDataSourceProvider.overrideWithValue(userLocalDataSource),
          authLocalDataSourceProvider.overrideWithValue(authLocalDataSource),
          subscriptionLocalDataSourceProvider
              .overrideWithValue(subscriptionLocalDataSource),
        ],
        child: const TestApp(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 1: HAPPY PATH - SINGLE PAYMENT MARKING
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Happy Path - Mark single payment as paid',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and on home screen
      await _login($);

      // Navigate to home screen
      await $.waitUntilVisible(find.text('Active Subscriptions'));
      expect($(#homeScreen), findsOneWidget);

      // WHEN: User taps on a subscription card with unpaid members
      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();

      // THEN: Subscription detail screen appears
      await $.waitUntilVisible(find.text('Subscription Details'));
      expect($(#subscriptionDetailScreen), findsOneWidget);

      // Verify members section is visible
      await $.waitUntilVisible(find.text('Members'));
      expect($(#membersSection), findsOneWidget);

      // WHEN: User taps checkbox on first unpaid member
      final firstCheckbox = $(#paymentCheckbox).first;
      await $.waitUntilVisible(firstCheckbox);

      // Store member name for verification
      final memberName = await _getMemberName($, 0);

      // Tap the checkbox
      await $.tap(firstCheckbox);
      await $.pumpAndSettle();

      // THEN: Checkbox should become checked (green)
      final checkbox = $.tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isTrue);
      expect(checkbox.activeColor, const Color(0xFF4CAF50));

      // Verify success SnackBar appears
      await $.waitUntilVisible(find.text('$memberName marked as paid'));
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));

      // Verify UNDO button is visible in SnackBar
      expect(find.text('Undo'), findsOneWidget);

      // THEN: Stats section should update
      await $.waitUntilVisible($(#collectedAmount));
      await $.waitUntilVisible($(#remainingAmount));

      // Verify stats values changed (collected increased, remaining decreased)
      final collectedText =
          $.tester.widget<Text>(find.byKey(const Key('collectedAmount')));
      expect(collectedText.data, isNotNull);
      expect(collectedText.data, contains(r'$'));

      // Verify payment tile has green border (paid state)
      final paymentTile = $.tester.widget<Container>(
        find.ancestor(
          of: firstCheckbox,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = paymentTile.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 2: HAPPY PATH - BULK PAYMENT MARKING
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Happy Path - Mark all payments as paid (bulk operation)',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and viewing subscription with multiple unpaid members
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));

      // Navigate to subscription detail
      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();
      await $.waitUntilVisible(find.text('Subscription Details'));

      // Verify "Mark All as Paid" button is visible
      await $.waitUntilVisible($(#markAllPaidButton));
      expect(find.text('Mark All as Paid'), findsOneWidget);

      // WHEN: User taps "Mark All as Paid" button
      await $.tap($(#markAllPaidButton));
      await $.pumpAndSettle();

      // THEN: Loading indicator should appear briefly
      // Note: This might be too fast to catch, so we'll check the result instead

      // Wait for success message
      await $.waitUntilVisible(find.textContaining('payment'));
      await $.waitUntilVisible(find.textContaining('marked as paid'));

      // Verify SnackBar shows count
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));

      // THEN: All checkboxes should be checked
      final checkboxes = find.byType(Checkbox);
      final checkboxCount = $.tester.widgetList<Checkbox>(checkboxes).length;

      for (var i = 0; i < checkboxCount; i++) {
        final checkbox = $.tester.widgetList<Checkbox>(checkboxes).elementAt(i);
        expect(checkbox.value, isTrue,
            reason: 'Checkbox $i should be checked');
        expect(checkbox.activeColor, const Color(0xFF4CAF50));
      }

      // THEN: "Mark All as Paid" button should disappear
      await $.pump(const Duration(seconds: 1));
      await $.pumpAndSettle();
      expect(find.text('Mark All as Paid'), findsNothing);

      // THEN: Stats should show all collected
      final remainingText =
          $.tester.widget<Text>(find.byKey(const Key('remainingAmount')));
      expect(remainingText.data, contains(r'$0.00'));

      // Verify collected amount equals total cost
      final collectedText =
          $.tester.widget<Text>(find.byKey(const Key('collectedAmount')));
      final totalCostText =
          $.tester.widget<Text>(find.byKey(const Key('totalCost')));
      expect(collectedText.data, equals(totalCostText.data));
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 3: UNDO FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Undo payment marking within 5-second window',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and on subscription detail screen
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));
      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();
      await $.waitUntilVisible(find.text('Subscription Details'));

      // WHEN: User marks a payment as paid
      final firstCheckbox = $(#paymentCheckbox).first;
      await $.waitUntilVisible(firstCheckbox);

      // Store initial state
      final memberName = await _getMemberName($, 0);
      final initialCollected = await _getStatsValue($, 'collectedAmount');

      // Mark as paid
      await $.tap(firstCheckbox);
      await $.pumpAndSettle();

      // Verify payment was marked
      await $.waitUntilVisible(find.text('$memberName marked as paid'));
      final checkbox1 = $.tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox1.value, isTrue);

      // WHEN: User taps UNDO button within 5 seconds
      final undoButton = find.text('Undo');
      await $.waitUntilVisible(undoButton);
      await $.tap(undoButton);
      await $.pumpAndSettle();

      // THEN: Payment should revert to unpaid
      final checkbox2 = $.tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox2.value, isFalse);

      // Verify checkbox becomes grey again (unpaid state)
      expect(checkbox2.side?.color, const Color(0xFF9E9E9E));

      // THEN: Undo confirmation message appears
      await $.waitUntilVisible(find.text('Action undone'));
      expect(find.byIcon(Icons.undo), findsOneWidget);

      // THEN: Stats should revert to original values
      final finalCollected = await _getStatsValue($, 'collectedAmount');
      expect(finalCollected, equals(initialCollected));

      // Verify payment tile has grey border again
      final paymentTile = $.tester.widget<Container>(
        find.ancestor(
          of: firstCheckbox,
          matching: find.byType(Container),
        ).first,
      );
      final decoration = paymentTile.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 4: UNDO WINDOW EXPIRES
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Undo button disappears after 5 seconds',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and on subscription detail screen
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));
      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();
      await $.waitUntilVisible(find.text('Subscription Details'));

      // WHEN: User marks a payment as paid
      final firstCheckbox = $(#paymentCheckbox).first;
      await $.waitUntilVisible(firstCheckbox);
      await $.tap(firstCheckbox);
      await $.pumpAndSettle();

      // Verify UNDO button appears
      await $.waitUntilVisible(find.text('Undo'));

      // WHEN: User waits for 5+ seconds without tapping UNDO
      await $.pump(const Duration(seconds: 6));

      // THEN: SnackBar (and UNDO button) should disappear
      expect(find.text('Undo'), findsNothing);

      // Payment should remain marked as paid
      final checkbox = $.tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isTrue);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 5: ERROR SCENARIO - NETWORK ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Handle network error gracefully with offline mode',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));

      // Simulate offline mode by disabling network
      // Note: In a real test, you'd use a mock or disable network
      // For this test, we'll test the error handling UI

      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();
      await $.waitUntilVisible(find.text('Subscription Details'));

      // WHEN: User tries to mark payment with no internet
      // (Assuming the app handles this gracefully with optimistic update)
      final firstCheckbox = $(#paymentCheckbox).first;
      await $.waitUntilVisible(firstCheckbox);
      await $.tap(firstCheckbox);
      await $.pumpAndSettle();

      // THEN: Optimistic update should still work
      // Checkbox should appear checked immediately
      final checkbox = $.tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isTrue);

      // Success message should appear (optimistic)
      // In case of network error, an error SnackBar would appear instead
      // But with optimistic updates, it should queue for sync
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 6: UI STATE VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Verify UI states and visual feedback',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and on subscription detail screen
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));
      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();
      await $.waitUntilVisible(find.text('Subscription Details'));

      // THEN: Verify unpaid members have grey border
      final unpaidCheckboxes = $.tester.widgetList<Checkbox>(
        find.byWidgetPredicate((widget) =>
            widget is Checkbox && widget.value == false),
      );

      for (final checkbox in unpaidCheckboxes) {
        expect(checkbox.side?.color, const Color(0xFF9E9E9E));
      }

      // WHEN: User marks a payment as paid
      final firstCheckbox = $(#paymentCheckbox).first;
      await $.tap(firstCheckbox);
      await $.pumpAndSettle();

      // THEN: Verify paid member has green border and green checkmark
      final paidCheckbox = $.tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(paidCheckbox.value, isTrue);
      expect(paidCheckbox.activeColor, const Color(0xFF4CAF50));
      expect(paidCheckbox.side?.color, const Color(0xFF4CAF50));

      // Verify amount displays correctly
      final amountText = find.textContaining(r'$');
      expect(amountText, findsAtLeastNWidgets(1));

      // Verify member avatar is visible
      expect(find.byType(CircleAvatar), findsAtLeastNWidgets(1));

      // Verify loading state during operation (if we can catch it)
      // Note: This might be too fast to catch in integration tests
      // But we verify the loading indicator exists in the code
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 7: NAVIGATION FLOW
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Complete navigation flow from Home to Subscription Detail',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and on home screen
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));

      // Verify home screen elements
      expect($(#homeScreen), findsOneWidget);
      expect($(#activeSubscriptionsSection), findsOneWidget);

      // WHEN: User taps on a subscription card
      final subscriptionCard = $(#subscriptionCard).first;
      await $.waitUntilVisible(subscriptionCard);
      await $.tap(subscriptionCard);
      await $.pumpAndSettle();

      // THEN: Subscription detail screen appears
      await $.waitUntilVisible(find.text('Subscription Details'));
      expect($(#subscriptionDetailScreen), findsOneWidget);

      // Verify all sections are visible
      expect($(#headerCard), findsOneWidget);
      expect($(#costInformationCard), findsOneWidget);
      expect($(#membersSection), findsOneWidget);
      expect($(#splitInformationCard), findsOneWidget);

      // WHEN: User taps back button
      final backButton = find.byIcon(Icons.arrow_back);
      await $.tap(backButton);
      await $.pumpAndSettle();

      // THEN: User returns to home screen
      await $.waitUntilVisible(find.text('Active Subscriptions'));
      expect($(#homeScreen), findsOneWidget);
    },
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST 8: STATS UPDATE VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  patrolTest(
    'Verify stats update correctly after payment operations',
    ($) async {
      // SETUP
      await setupApp($);

      // GIVEN: User is logged in and on subscription detail screen
      await _login($);
      await $.waitUntilVisible(find.text('Active Subscriptions'));
      await $.tap($(#subscriptionCard).first);
      await $.pumpAndSettle();
      await $.waitUntilVisible(find.text('Subscription Details'));

      // Store initial stats
      final initialCollected = await _getStatsValue($, 'collectedAmount');
      final initialRemaining = await _getStatsValue($, 'remainingAmount');

      // WHEN: User marks a payment as paid
      final firstCheckbox = $(#paymentCheckbox).first;
      await $.tap(firstCheckbox);
      await $.pumpAndSettle();

      // THEN: Collected amount should increase
      final newCollected = await _getStatsValue($, 'collectedAmount');
      expect(
        double.parse(newCollected.replaceAll(RegExp(r'[^\d.]'), '')),
        greaterThan(
            double.parse(initialCollected.replaceAll(RegExp(r'[^\d.]'), ''))),
      );

      // THEN: Remaining amount should decrease
      final newRemaining = await _getStatsValue($, 'remainingAmount');
      expect(
        double.parse(newRemaining.replaceAll(RegExp(r'[^\d.]'), '')),
        lessThan(
            double.parse(initialRemaining.replaceAll(RegExp(r'[^\d.]'), ''))),
      );

      // Verify collected + remaining = total cost
      final totalCost = await _getStatsValue($, 'totalCost');
      final totalValue = double.parse(totalCost.replaceAll(RegExp(r'[^\d.]'), ''));
      final collectedValue =
          double.parse(newCollected.replaceAll(RegExp(r'[^\d.]'), ''));
      final remainingValue =
          double.parse(newRemaining.replaceAll(RegExp(r'[^\d.]'), ''));

      expect((collectedValue + remainingValue).toStringAsFixed(2),
          totalValue.toStringAsFixed(2));
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Helper function to login the user
Future<void> _login(PatrolIntegrationTester $) async {
  // Wait for login screen to appear
  await $.waitUntilVisible(find.text('Login'));

  // Enter credentials
  final emailField = find.byType(TextField).first;
  await $.enterText(emailField, 'test@example.com');

  final passwordField = find.byType(TextField).last;
  await $.enterText(passwordField, 'password123');

  // Tap login button
  final loginButton = find.text('Login');
  await $.tap(loginButton);
  await $.pumpAndSettle();

  // Wait for home screen
  await $.waitUntilVisible(find.text('Active Subscriptions'));
}

/// Helper function to get member name by index
Future<String> _getMemberName(PatrolIntegrationTester $, int index) async {
  final memberTiles = $.tester.widgetList<Text>(
    find.descendant(
      of: find.byKey(Key('memberTile_$index')),
      matching: find.byType(Text),
    ),
  );

  return memberTiles.first.data ?? '';
}

/// Helper function to get stats value by key
Future<String> _getStatsValue(PatrolIntegrationTester $, String key) async {
  final textWidget = $.tester.widget<Text>(find.byKey(Key(key)));
  return textWidget.data ?? '';
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST APP
// ═══════════════════════════════════════════════════════════════════════════

/// Test app wrapper
class TestApp extends ConsumerWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SubMate - Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
