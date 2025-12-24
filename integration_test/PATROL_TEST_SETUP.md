# Patrol Integration Tests - Setup Guide

## Overview

This guide provides comprehensive instructions for setting up and running Patrol integration tests for the "Mark Payment as Paid" feature in SubMate.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Semantic Keys Setup](#semantic-keys-setup)
3. [Running Tests](#running-tests)
4. [Test Coverage](#test-coverage)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Dependencies

Ensure your `pubspec.yaml` includes:

```yaml
dev_dependencies:
  patrol: ^3.6.1
  flutter_test:
    sdk: flutter
```

### Install Patrol CLI

```bash
# Install Patrol CLI globally
dart pub global activate patrol_cli

# Verify installation
patrol --version
```

---

## Semantic Keys Setup

To enable Patrol tests to find and interact with widgets, you need to add semantic keys to specific widgets in your codebase.

### 1. Home Screen Keys

**File:** `lib/core/presentation/app_shell.dart` or `lib/features/home/presentation/screens/home_screen.dart`

Add the following key to the main Home Screen scaffold:

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('homeScreen'),  // ADD THIS
      // ... rest of the code
    );
  }
}
```

### 2. Active Subscriptions Section

**File:** `lib/features/home/presentation/widgets/active_subscriptions_section.dart`

Add key to the ActiveSubscriptionsSection widget:

```dart
class ActiveSubscriptionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('activeSubscriptionsSection'),  // ADD THIS
      padding: const EdgeInsets.symmetric(horizontal: 24),
      // ... rest of the code
    );
  }
}
```

Add key to each subscription card:

```dart
class _SubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('subscriptionCard_${subscription.id}'),  // ADD THIS
      onTap: () {
        context.push('/subscription/${subscription.id}');
      },
      // ... rest of the code
    );
  }
}
```

### 3. Subscription Detail Screen Keys

**File:** `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`

Add key to the main scaffold:

```dart
return Scaffold(
  key: const Key('subscriptionDetailScreen'),  // ADD THIS
  backgroundColor: const Color(0xFF0D0D1E),
  // ... rest of the code
);
```

Add keys to the various card sections:

```dart
// Header Card
class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('headerCard'),  // ADD THIS
      padding: const EdgeInsets.all(24),
      // ... rest of the code
    );
  }
}

// Cost Information Card
class _CostInformationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('costInformationCard'),  // ADD THIS
      padding: const EdgeInsets.all(20),
      // ... rest of the code
    );
  }
}

// Members Section
class _MembersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('membersSection'),  // ADD THIS
      padding: const EdgeInsets.all(20),
      // ... rest of the code
    );
  }
}

// Split Information Card
class _SplitInformationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('splitInformationCard'),  // ADD THIS
      padding: const EdgeInsets.all(20),
      // ... rest of the code
    );
  }
}
```

Add key to the Total Cost text:

```dart
_InfoRow(
  label: 'Total Cost',
  value: '\$${subscription.totalCost.toStringAsFixed(2)}',
  valueKey: const Key('totalCost'),  // ADD THIS PARAMETER
  // ... rest of parameters
),
```

Update `_InfoRow` widget to accept a key parameter:

```dart
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
    this.valueKey,  // ADD THIS
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final Key? valueKey;  // ADD THIS

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
        Text(
          value,
          key: valueKey,  // ADD THIS
          style: valueStyle ??
              TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
```

Add keys to the stats section:

```dart
_InfoRow(
  label: 'Collected So Far',
  value: '\$${stats.collectedAmount.toStringAsFixed(2)}',
  valueColor: Colors.green,
  valueKey: const Key('collectedAmount'),  // ADD THIS
),
const SizedBox(height: 12),
_InfoRow(
  label: 'Remaining to Collect',
  value: '\$${stats.remainingAmount.toStringAsFixed(2)}',
  valueColor: Colors.orange,
  valueKey: const Key('remainingAmount'),  // ADD THIS
),
```

### 4. Payment Status Toggle Widget

**File:** `lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart`

Add key to the main container and checkbox:

```dart
class _PaymentStatusToggleState extends ConsumerState<PaymentStatusToggle> {
  @override
  Widget build(BuildContext context) {
    // ... existing code ...

    return GestureDetector(
      onTap: isLoading ? null : () => _togglePaymentStatus(!isPaid),
      child: Container(
        key: Key('paymentToggle_${widget.member.id}'),  // ADD THIS
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ... existing decoration
        ),
        child: Row(
          children: [
            // ... existing avatar and info ...

            // Checkbox
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6B4FBB),
                ),
              )
            else
              Checkbox(
                key: Key('paymentCheckbox_${widget.member.id}'),  // ADD THIS
                value: isPaid,
                onChanged: _togglePaymentStatus,
                // ... rest of the code
              ),
          ],
        ),
      ),
    );
  }
}
```

### 5. Payment Action Buttons

**File:** `lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart`

Add key to the "Mark All as Paid" button:

```dart
return SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton.icon(
    key: const Key('markAllPaidButton'),  // ADD THIS
    onPressed: isLoading
        ? null
        : () => _handleMarkAllAsPaid(context, ref),
    // ... rest of the code
  ),
);
```

### 6. Member Tile Keys

**File:** `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`

In the `_MembersSection` widget, add keys to each member tile:

```dart
// Member tiles
...members.asMap().entries.map(
  (entry) => Padding(
    key: Key('memberTile_${entry.key}'),  // ADD THIS
    padding: const EdgeInsets.only(bottom: 12),
    child: _MemberTile(
      member: entry.value,
      subscriptionId: subscriptionId,
    ),
  ),
),
```

---

## Running Tests

### 1. Basic Test Execution

Run all integration tests:

```bash
# Run on connected device/emulator
patrol test integration_test/mark_payment_as_paid_test.dart

# Run on specific device
patrol test integration_test/mark_payment_as_paid_test.dart --device=<device_id>

# List available devices
flutter devices
```

### 2. Run Specific Test

Run a single test by name:

```bash
patrol test integration_test/mark_payment_as_paid_test.dart --name="Happy Path - Mark single payment as paid"
```

### 3. Debug Mode

Run tests with verbose output:

```bash
patrol test integration_test/mark_payment_as_paid_test.dart --verbose
```

### 4. Platform-Specific Execution

```bash
# Run on iOS
patrol test integration_test/mark_payment_as_paid_test.dart --target=ios

# Run on Android
patrol test integration_test/mark_payment_as_paid_test.dart --target=android
```

### 5. CI/CD Integration

For GitHub Actions or other CI systems:

```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Install Patrol CLI
        run: dart pub global activate patrol_cli

      - name: Run integration tests
        run: patrol test integration_test/mark_payment_as_paid_test.dart
```

---

## Test Coverage

The `mark_payment_as_paid_test.dart` file includes 8 comprehensive test scenarios:

### Test 1: Happy Path - Single Payment Marking
- **Coverage:** Basic payment marking flow
- **User Journey:** Home → Subscription Detail → Mark payment → Verify UI updates
- **Assertions:**
  - Checkbox becomes checked (green)
  - SnackBar appears with success message
  - UNDO button is visible
  - Stats update correctly
  - Payment tile shows green border

### Test 2: Happy Path - Bulk Payment Marking
- **Coverage:** Mark all payments at once
- **User Journey:** Subscription Detail → Tap "Mark All as Paid" → Verify all checkboxes
- **Assertions:**
  - Loading indicator appears
  - All checkboxes become green
  - SnackBar shows count
  - "Mark All as Paid" button disappears
  - Stats show 100% collected

### Test 3: Undo Functionality
- **Coverage:** Undo within 5-second window
- **User Journey:** Mark payment → Tap UNDO → Verify revert
- **Assertions:**
  - Payment reverts to unpaid
  - Checkbox becomes grey
  - Stats revert to original values
  - Undo confirmation appears

### Test 4: Undo Window Expires
- **Coverage:** Undo button timeout
- **User Journey:** Mark payment → Wait 6 seconds → Verify UNDO disappears
- **Assertions:**
  - UNDO button disappears after 5 seconds
  - Payment remains marked as paid

### Test 5: Network Error Handling
- **Coverage:** Offline mode and error states
- **User Journey:** Mark payment with no network → Verify optimistic update
- **Assertions:**
  - Optimistic UI update works
  - Operation queued for sync
  - Error handling graceful

### Test 6: UI State Verification
- **Coverage:** Visual feedback and styling
- **User Journey:** Verify all UI states
- **Assertions:**
  - Paid members have green borders
  - Unpaid members have grey borders
  - Amounts display correctly
  - Avatars visible
  - Loading states work

### Test 7: Navigation Flow
- **Coverage:** Complete app navigation
- **User Journey:** Home → Subscription Detail → Back
- **Assertions:**
  - All screen sections visible
  - Navigation works correctly
  - Back button returns to home

### Test 8: Stats Update Verification
- **Coverage:** Financial calculations
- **User Journey:** Mark payment → Verify stats math
- **Assertions:**
  - Collected amount increases
  - Remaining amount decreases
  - Collected + Remaining = Total

---

## Test Best Practices

### 1. Use Descriptive Test Names

Good:
```dart
patrolTest('Happy Path - Mark single payment as paid', ($) async { ... });
```

Bad:
```dart
patrolTest('test1', ($) async { ... });
```

### 2. Follow AAA Pattern

- **Arrange:** Setup initial state
- **Act:** Perform user actions
- **Assert:** Verify expected outcomes

```dart
// GIVEN: User is on subscription detail screen
await _login($);
await $.tap($(#subscriptionCard).first);

// WHEN: User marks a payment
await $.tap($(#paymentCheckbox).first);

// THEN: Checkbox becomes checked
expect(checkbox.value, isTrue);
```

### 3. Add Wait Conditions

Always wait for elements before interacting:

```dart
await $.waitUntilVisible(find.text('Subscription Details'));
await $.tap($(#paymentCheckbox).first);
```

### 4. Use Semantic Keys Consistently

Prefer semantic keys over text finders:

Good:
```dart
await $.tap($(#paymentCheckbox).first);
```

Better than:
```dart
await $.tap(find.text('Pay'));
```

### 5. Clean Up Test Data

If tests create data, clean it up:

```dart
tearDown(() async {
  // Clean up test data
  await _deleteTestSubscriptions();
});
```

---

## Troubleshooting

### Issue: Tests Can't Find Widgets

**Solution:** Ensure semantic keys are properly added to widgets.

```dart
// Verify key exists
expect($(#paymentCheckbox), findsOneWidget);
```

### Issue: Tests Timeout

**Solution:** Increase timeout duration or check for network issues.

```dart
patrol test integration_test/mark_payment_as_paid_test.dart --timeout=5m
```

### Issue: Authentication Fails

**Solution:** Ensure test credentials are valid and .env file is loaded.

```dart
// Check .env file
await EnvConfig.load();
```

### Issue: Flaky Tests

**Solution:** Add proper wait conditions and pump commands.

```dart
// Wait for animations to complete
await $.pumpAndSettle();

// Wait for specific element
await $.waitUntilVisible(find.text('Expected Text'));
```

### Issue: Supabase Connection Fails

**Solution:** Verify Supabase credentials in .env file.

```bash
# .env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

---

## Expected Test Coverage

After implementing all semantic keys and running the tests, you should achieve:

- **Widget Coverage:** 100% of payment-related widgets
- **User Flow Coverage:** All critical payment journeys
- **Edge Case Coverage:** Undo, timeout, errors
- **Integration Coverage:** Full end-to-end flows

### Coverage Report

Run tests with coverage:

```bash
patrol test integration_test/mark_payment_as_paid_test.dart --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Additional Resources

- [Patrol Documentation](https://patrol.leancode.co/)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Patrol GitHub](https://github.com/leancodepl/patrol)

---

## Summary

This test suite provides comprehensive coverage of the "Mark Payment as Paid" feature:

1. **8 test scenarios** covering happy paths, edge cases, and error states
2. **Semantic keys** for reliable widget identification
3. **User-centric** test design following real user journeys
4. **Production-ready** with CI/CD integration support

By following this guide, you'll have a robust integration test suite that ensures the payment feature works correctly across all scenarios.
