---
phase: 06
slug: ux-system-consistency
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-12
updated: 2026-03-14
---

# Phase 06 Validation Matrix

This matrix is the release gate for **UX-01** and **UX-02**.

## Quick Verification

```bash
flutter analyze lib/core/theme lib/core/widgets
flutter test \
  test/core/theme/app_theme_extension_test.dart \
  test/core/widgets/app_screen_scaffold_test.dart \
  test/core/widgets/app_section_card_test.dart \
  test/core/widgets/app_section_header_test.dart \
  test/core/widgets/app_status_badge_test.dart \
  test/core/widgets/app_operational_snackbar_test.dart \
  test/core/widgets/app_confirmation_dialog_test.dart
```

## Plan-Level Verification

### 06-02 Home adoption

```bash
flutter test \
  test/features/home/presentation/screens/home_screen_debt_priority_test.dart \
  test/features/home/presentation/widgets/debt_home_kpi_card_test.dart \
  test/features/home/presentation/widgets/home_header_sync_badge_test.dart
```

### 06-03 Create/Split foundations

```bash
flutter test \
  test/core/widgets/app_text_field_test.dart \
  test/core/widgets/app_date_field_test.dart \
  test/core/widgets/app_sheet_container_test.dart \
  test/core/widgets/app_sticky_submit_bar_test.dart \
  test/features/subscriptions/presentation/widgets/billing_cycle_selector_test.dart \
  test/features/subscriptions/presentation/screens/create_subscription_screen_test.dart \
  test/features/subscriptions/presentation/widgets/add_member_dialog_test.dart \
  test/features/subscriptions/presentation/widgets/service_template_sheet_test.dart \
  test/features/subscriptions/presentation/widgets/contacts_selection_sheet_test.dart \
  test/features/subscriptions/presentation/widgets/split_bill_preview_card_test.dart
```

### 06-04 Detail migration

```bash
flutter test \
  test/features/subscriptions/presentation/screens/subscription_detail_payment_ordering_test.dart \
  test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart \
  test/features/subscriptions/presentation/widgets/payment_status_toggle_test.dart

flutter analyze \
  lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart \
  lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart \
  lib/features/subscriptions/presentation/widgets/payment_stats_card.dart \
  lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart \
  lib/features/subscriptions/presentation/widgets/analytics/overview_cards_section.dart \
  lib/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart \
  lib/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart

bash -lc "! rg -n 'Color\\(0xFF|LinearGradient\\(|AlertDialog\\(|SnackBar\\(' \
  lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart \
  lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart \
  lib/features/subscriptions/presentation/widgets/payment_stats_card.dart \
  lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart \
  lib/features/subscriptions/presentation/widgets/analytics/overview_cards_section.dart \
  lib/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart \
  lib/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart"
```

### 06-05 Traceability, guards, and goldens

```bash
flutter test \
  test/features/subscriptions/phase6_requirements_traceability_test.dart \
  test/features/subscriptions/phase6_source_guards_test.dart

flutter test --update-goldens \
  test/features/home/presentation/screens/home_screen_golden_test.dart \
  test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart \
  test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart

flutter test \
  test/features/home/presentation/screens/home_screen_golden_test.dart \
  test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart \
  test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart
```

## Full Regression

```bash
flutter test
```

## Integration Smoke

Use UTF-8 locale variables for CocoaPods runtime compatibility:

```bash
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter test integration_test/subscription_setup_flow_test.dart
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter test integration_test/subscription_setup_offline_catalog_test.dart
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter test integration_test/payment_debt_home_flow_test.dart
```

## Manual UX Checklist

- Validate dark-theme hierarchy across Home, Create, and Detail first folds.
- Confirm shared status/dialog/snackbar patterns are consistent and readable.
- Confirm CTA hierarchy: primary, secondary, and destructive actions are visually distinct.
- Confirm no regression in payment toggle responsiveness and debt reconciliation behavior.

## Evidence Links

- Traceability: `test/features/subscriptions/phase6_requirements_traceability_test.dart`
- Source guards: `test/features/subscriptions/phase6_source_guards_test.dart`
- Goldens: `test/goldens/phase6/*.png`
