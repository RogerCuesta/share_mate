# Quick Start Guide - Patrol Integration Tests

## TL;DR - Get Tests Running in 5 Minutes

### Step 1: Install Patrol CLI (1 min)

```bash
dart pub global activate patrol_cli
```

### Step 2: Add Semantic Keys to Widgets (2 min)

Copy and paste these key additions to your widgets:

#### PaymentStatusToggle Widget
```dart
// lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart
Checkbox(
  key: Key('paymentCheckbox_${widget.member.id}'),  // ADD THIS LINE
  value: isPaid,
  onChanged: _togglePaymentStatus,
  // ...
),
```

#### PaymentActionButtons Widget
```dart
// lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart
OutlinedButton.icon(
  key: const Key('markAllPaidButton'),  // ADD THIS LINE
  onPressed: isLoading ? null : () => _handleMarkAllAsPaid(context, ref),
  // ...
),
```

#### Subscription Detail Screen
```dart
// lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart

// Main Scaffold
Scaffold(
  key: const Key('subscriptionDetailScreen'),  // ADD THIS LINE
  // ...
)

// Members Section
Container(
  key: const Key('membersSection'),  // ADD THIS LINE
  // ...
)
```

#### Home Screen
```dart
// lib/features/home/presentation/widgets/active_subscriptions_section.dart

// Subscription Card
GestureDetector(
  key: Key('subscriptionCard_${subscription.id}'),  // ADD THIS LINE
  // ...
)

// Home Screen Root
Scaffold(
  key: const Key('homeScreen'),  // ADD THIS LINE
  // ...
)
```

#### Stats Section
```dart
// lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart

// In _SplitInformationCard, update _InfoRow calls:
_InfoRow(
  label: 'Collected So Far',
  value: '\$${stats.collectedAmount.toStringAsFixed(2)}',
  valueColor: Colors.green,
  valueKey: const Key('collectedAmount'),  // ADD THIS PARAMETER
),

_InfoRow(
  label: 'Remaining to Collect',
  value: '\$${stats.remainingAmount.toStringAsFixed(2)}',
  valueColor: Colors.orange,
  valueKey: const Key('remainingAmount'),  // ADD THIS PARAMETER
),

// In _CostInformationCard:
_InfoRow(
  label: 'Total Cost',
  value: '\$${subscription.totalCost.toStringAsFixed(2)}',
  valueKey: const Key('totalCost'),  // ADD THIS PARAMETER
),
```

Update the `_InfoRow` widget to accept the key parameter:

```dart
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
    this.valueKey,  // ADD THIS LINE
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final Key? valueKey;  // ADD THIS LINE

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
          key: valueKey,  // ADD THIS LINE
          style: valueStyle ?? TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
```

### Step 3: Run Tests (1 min)

```bash
# Ensure device/emulator is running
flutter devices

# Run all integration tests
patrol test integration_test/mark_payment_as_paid_test.dart

# Or run a specific test
patrol test integration_test/mark_payment_as_paid_test.dart --name="Happy Path - Mark single payment as paid"
```

### Step 4: View Results (1 min)

Tests will output results in the terminal. Look for:
- ✅ Green checkmarks for passing tests
- ❌ Red X for failing tests
- Detailed error messages if any test fails

---

## Common Commands

```bash
# Run all tests
patrol test integration_test/mark_payment_as_paid_test.dart

# Run with verbose output
patrol test integration_test/mark_payment_as_paid_test.dart --verbose

# Run on specific device
patrol test integration_test/mark_payment_as_paid_test.dart --device=<device_id>

# Run single test
patrol test integration_test/mark_payment_as_paid_test.dart --name="Happy Path - Mark single payment as paid"

# List all tests
patrol test integration_test/mark_payment_as_paid_test.dart --list

# Run with coverage
patrol test integration_test/mark_payment_as_paid_test.dart --coverage
```

---

## Test Scenarios Covered

1. ✅ **Single Payment Marking** - Mark one member's payment as paid
2. ✅ **Bulk Payment Marking** - Mark all payments at once
3. ✅ **Undo Functionality** - Undo payment within 5 seconds
4. ✅ **Undo Timeout** - Verify undo button disappears after 5 seconds
5. ✅ **Network Error Handling** - Test offline mode
6. ✅ **UI State Verification** - Check visual feedback (colors, borders)
7. ✅ **Navigation Flow** - Complete user journey
8. ✅ **Stats Verification** - Ensure financial calculations are correct

---

## Troubleshooting

### "Command not found: patrol"
```bash
# Add Dart global packages to PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Or reinstall
dart pub global activate patrol_cli
```

### "No devices found"
```bash
# List available devices
flutter devices

# Start an emulator
flutter emulators
flutter emulators --launch <emulator_id>
```

### Tests timeout
```bash
# Increase timeout
patrol test integration_test/mark_payment_as_paid_test.dart --timeout=10m
```

### Widget not found
- Verify semantic keys are added correctly
- Check widget is visible (not scrolled off screen)
- Use `await $.waitUntilVisible()` before tapping

---

## Next Steps

For detailed information, see:
- **Full Setup Guide:** `integration_test/PATROL_TEST_SETUP.md`
- **Test File:** `integration_test/mark_payment_as_paid_test.dart`

---

## Need Help?

1. Check `PATROL_TEST_SETUP.md` for detailed instructions
2. Review Patrol docs: https://patrol.leancode.co/
3. Check test file comments for inline explanations
