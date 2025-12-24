# Integration Tests Implementation Checklist

Use this checklist to implement and verify the Patrol integration tests for the "Mark Payment as Paid" feature.

## Phase 1: Pre-Setup (5 minutes)

### Install Patrol CLI
- [ ] Run: `dart pub global activate patrol_cli`
- [ ] Verify: `patrol --version` shows version number
- [ ] Add to PATH if needed: `export PATH="$PATH":"$HOME/.pub-cache/bin"`

### Verify Dependencies
- [ ] Check `pubspec.yaml` has `patrol: ^3.6.1` in `dev_dependencies`
- [ ] Run: `flutter pub get`
- [ ] Ensure device/emulator is running: `flutter devices`

---

## Phase 2: Add Semantic Keys (15 minutes)

### File 1: Payment Status Toggle Widget
**Location:** `lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart`

- [ ] Find the `Checkbox` widget (around line 336)
- [ ] Add key: `key: Key('paymentCheckbox_${widget.member.id}')`
- [ ] Save file

**Code to add:**
```dart
Checkbox(
  key: Key('paymentCheckbox_${widget.member.id}'),  // ADD THIS LINE
  value: isPaid,
  onChanged: _togglePaymentStatus,
  // ... rest of properties
)
```

### File 2: Payment Action Buttons Widget
**Location:** `lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart`

- [ ] Find the `OutlinedButton.icon` for "Mark All as Paid" (around line 135)
- [ ] Add key: `key: const Key('markAllPaidButton')`
- [ ] Save file

**Code to add:**
```dart
OutlinedButton.icon(
  key: const Key('markAllPaidButton'),  // ADD THIS LINE
  onPressed: isLoading ? null : () => _handleMarkAllAsPaid(context, ref),
  // ... rest of properties
)
```

### File 3: Subscription Detail Screen
**Location:** `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`

#### 3a. Main Scaffold
- [ ] Find the `Scaffold` widget in `_buildContent` method (around line 149)
- [ ] Add key: `key: const Key('subscriptionDetailScreen')`
- [ ] Save file

**Code to add:**
```dart
return Scaffold(
  key: const Key('subscriptionDetailScreen'),  // ADD THIS LINE
  backgroundColor: const Color(0xFF0D0D1E),
  // ... rest of properties
)
```

#### 3b. Members Section
- [ ] Find the `_MembersSection` widget container (around line 541)
- [ ] Add key: `key: const Key('membersSection')`
- [ ] Save file

**Code to add:**
```dart
return Container(
  key: const Key('membersSection'),  // ADD THIS LINE
  padding: const EdgeInsets.all(20),
  // ... rest of properties
)
```

#### 3c. Cost Information Card
- [ ] Find the `_CostInformationCard` widget container (around line 387)
- [ ] Add key: `key: const Key('costInformationCard')`
- [ ] Save file

**Code to add:**
```dart
return Container(
  key: const Key('costInformationCard'),  // ADD THIS LINE
  padding: const EdgeInsets.all(20),
  // ... rest of properties
)
```

#### 3d. Split Information Card
- [ ] Find the `_SplitInformationCard` widget container (around line 636)
- [ ] Add key: `key: const Key('splitInformationCard')`
- [ ] Save file

**Code to add:**
```dart
return Container(
  key: const Key('splitInformationCard'),  // ADD THIS LINE
  padding: const EdgeInsets.all(20),
  // ... rest of properties
)
```

#### 3e. Update _InfoRow Widget
- [ ] Find the `_InfoRow` class (around line 682)
- [ ] Add `valueKey` parameter to constructor
- [ ] Add `valueKey` field
- [ ] Apply key to the value `Text` widget

**Code to replace:**
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

#### 3f. Add Keys to _InfoRow Usages
- [ ] In `_CostInformationCard`, find "Total Cost" _InfoRow (around line 407)
- [ ] Add parameter: `valueKey: const Key('totalCost')`

**Code to add:**
```dart
_InfoRow(
  label: 'Total Cost',
  value: '\$${subscription.totalCost.toStringAsFixed(2)}',
  valueKey: const Key('totalCost'),  // ADD THIS LINE
  valueStyle: const TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),
```

- [ ] In `_SplitInformationCard`, find "Collected So Far" _InfoRow (around line 665)
- [ ] Add parameter: `valueKey: const Key('collectedAmount')`

**Code to add:**
```dart
_InfoRow(
  label: 'Collected So Far',
  value: '\$${stats.collectedAmount.toStringAsFixed(2)}',
  valueColor: Colors.green,
  valueKey: const Key('collectedAmount'),  // ADD THIS LINE
),
```

- [ ] In `_SplitInformationCard`, find "Remaining to Collect" _InfoRow (around line 671)
- [ ] Add parameter: `valueKey: const Key('remainingAmount')`

**Code to add:**
```dart
_InfoRow(
  label: 'Remaining to Collect',
  value: '\$${stats.remainingAmount.toStringAsFixed(2)}',
  valueColor: Colors.orange,
  valueKey: const Key('remainingAmount'),  // ADD THIS LINE
),
```

### File 4: Active Subscriptions Section
**Location:** `lib/features/home/presentation/widgets/active_subscriptions_section.dart`

#### 4a. Section Container
- [ ] Find the main `Padding` widget in `ActiveSubscriptionsSection` (around line 32)
- [ ] Add key: `key: const Key('activeSubscriptionsSection')`
- [ ] Save file

**Code to add:**
```dart
return Padding(
  key: const Key('activeSubscriptionsSection'),  // ADD THIS LINE
  padding: const EdgeInsets.symmetric(horizontal: 24),
  // ... rest of properties
)
```

#### 4b. Subscription Card
- [ ] Find the `GestureDetector` in `_SubscriptionCard` (around line 147)
- [ ] Add key: `key: Key('subscriptionCard_${subscription.id}')`
- [ ] Save file

**Code to add:**
```dart
return GestureDetector(
  key: Key('subscriptionCard_${subscription.id}'),  // ADD THIS LINE
  onTap: () {
    context.push('/subscription/${subscription.id}');
  },
  // ... rest of properties
)
```

### File 5: Home Screen
**Location:** `lib/core/presentation/app_shell.dart` or your home screen file

- [ ] Find the main `Scaffold` for the home screen
- [ ] Add key: `key: const Key('homeScreen')`
- [ ] Save file

**Code to add:**
```dart
return Scaffold(
  key: const Key('homeScreen'),  // ADD THIS LINE
  // ... rest of properties
)
```

---

## Phase 3: Verify Changes (5 minutes)

### Hot Reload / Restart
- [ ] Run: `flutter pub get`
- [ ] Hot restart your app
- [ ] Verify app still works correctly
- [ ] Navigate to subscription detail screen
- [ ] Verify payment checkboxes are visible

### Static Analysis
- [ ] Run: `flutter analyze`
- [ ] Verify: No errors reported
- [ ] Fix any issues if found

---

## Phase 4: Run Tests (10 minutes)

### Initial Test Run
- [ ] Ensure device/emulator is running
- [ ] Run: `patrol test integration_test/mark_payment_as_paid_test.dart`
- [ ] Wait for tests to complete (~40 seconds)

### Verify Test Results
- [ ] ✅ Test 1: Happy Path - Single Payment (should pass)
- [ ] ✅ Test 2: Happy Path - Bulk Payment (should pass)
- [ ] ✅ Test 3: Undo Functionality (should pass)
- [ ] ✅ Test 4: Undo Window Expires (should pass)
- [ ] ✅ Test 5: Network Error Handling (should pass)
- [ ] ✅ Test 6: UI State Verification (should pass)
- [ ] ✅ Test 7: Navigation Flow (should pass)
- [ ] ✅ Test 8: Stats Update Verification (should pass)

### If Tests Fail
- [ ] Read error message carefully
- [ ] Check semantic key spelling
- [ ] Verify widget hierarchy hasn't changed
- [ ] Ensure test data is available
- [ ] Check authentication credentials
- [ ] Re-run failed test: `patrol test integration_test/mark_payment_as_paid_test.dart --name="<test_name>"`

---

## Phase 5: CI/CD Integration (Optional, 10 minutes)

### GitHub Actions
- [ ] Create `.github/workflows/integration_tests.yml`
- [ ] Copy example from `PATROL_TEST_SETUP.md`
- [ ] Commit and push
- [ ] Verify tests run in CI

### GitLab CI
- [ ] Update `.gitlab-ci.yml`
- [ ] Add integration_tests stage
- [ ] Commit and push
- [ ] Verify tests run in CI

---

## Phase 6: Documentation Review (5 minutes)

### Read Documentation
- [ ] Read `QUICK_START.md` for quick reference
- [ ] Skim `PATROL_TEST_SETUP.md` for detailed info
- [ ] Review `README.md` for overview
- [ ] Check `IMPLEMENTATION_SUMMARY.md` for complete details

### Bookmark for Future
- [ ] Bookmark test documentation location
- [ ] Share with team members
- [ ] Add to onboarding docs

---

## Phase 7: Final Verification (5 minutes)

### Manual Testing
- [ ] Open app manually
- [ ] Navigate to subscription detail
- [ ] Mark a payment as paid
- [ ] Verify checkbox turns green
- [ ] Tap UNDO
- [ ] Verify payment reverts
- [ ] Tap "Mark All as Paid"
- [ ] Verify all checkboxes turn green

### Code Review
- [ ] Review all code changes
- [ ] Ensure no debug code left
- [ ] Verify semantic keys don't affect production
- [ ] Check for any console warnings

### Commit Changes
- [ ] Stage changes: `git add .`
- [ ] Commit: `git commit -m "feat: Add comprehensive Patrol integration tests for Mark Payment as Paid feature"`
- [ ] Push: `git push origin <branch-name>`

---

## Troubleshooting

### Issue: "Command not found: patrol"
**Solution:**
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
dart pub global activate patrol_cli
```

### Issue: "Widget not found"
**Solution:**
- Verify semantic key is added correctly
- Check spelling of key name
- Ensure widget is visible (not scrolled off-screen)

### Issue: Tests timeout
**Solution:**
```bash
patrol test integration_test/mark_payment_as_paid_test.dart --timeout=10m
```

### Issue: Authentication fails
**Solution:**
- Check `.env` file exists
- Verify Supabase credentials
- Ensure test user exists in database

### Issue: Flaky tests
**Solution:**
- Add `await $.pumpAndSettle()` after actions
- Use `await $.waitUntilVisible()` before interactions
- Increase wait times if needed

---

## Success Criteria

You've successfully implemented the integration tests when:

✅ All 8 test scenarios pass consistently
✅ Tests run in under 60 seconds
✅ No console errors or warnings
✅ Tests work on both iOS and Android (if applicable)
✅ Tests can run in CI/CD pipeline
✅ All semantic keys are properly added
✅ Documentation has been reviewed
✅ Changes are committed to version control

---

## Completion Summary

- [ ] **Phase 1:** Pre-Setup (5 min)
- [ ] **Phase 2:** Add Semantic Keys (15 min)
- [ ] **Phase 3:** Verify Changes (5 min)
- [ ] **Phase 4:** Run Tests (10 min)
- [ ] **Phase 5:** CI/CD Integration (10 min) - Optional
- [ ] **Phase 6:** Documentation Review (5 min)
- [ ] **Phase 7:** Final Verification (5 min)

**Total Time:** ~45 minutes (without CI/CD) or ~55 minutes (with CI/CD)

---

## Next Steps

After completing this checklist:

1. **Share with Team**
   - Notify team members about new tests
   - Share documentation location
   - Schedule knowledge sharing session

2. **Monitor Tests**
   - Watch for test failures in CI/CD
   - Fix any issues promptly
   - Keep tests up to date with code changes

3. **Expand Coverage**
   - Consider adding more test scenarios
   - Test edge cases
   - Add performance tests

---

**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

**Completed By:** ________________

**Date:** ________________

**Notes:**
```
[Space for any notes or issues encountered]
```
