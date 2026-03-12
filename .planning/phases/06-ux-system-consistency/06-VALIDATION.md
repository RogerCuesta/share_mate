---
phase: 06
slug: ux-system-consistency
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-12
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (package:test + widget/golden/integration) |
| **Config file** | `analysis_options.yaml` |
| **Quick run command** | `flutter analyze lib/core/theme lib/core/widgets && flutter test test/core/theme/app_theme_extension_test.dart test/core/widgets/app_screen_scaffold_test.dart test/core/widgets/app_section_card_test.dart test/core/widgets/app_section_header_test.dart test/core/widgets/app_status_badge_test.dart test/core/widgets/app_operational_snackbar_test.dart test/core/widgets/app_confirmation_dialog_test.dart` |
| **Full suite command** | `flutter analyze && flutter test && flutter test integration_test/subscription_setup_flow_test.dart && flutter test integration_test/subscription_setup_offline_catalog_test.dart && flutter test integration_test/payment_debt_home_flow_test.dart` |
| **Estimated runtime** | ~420 seconds |

---

## Sampling Rate

- **After every task commit:** Run the exact task-specific `<automated>` command from the active plan/per-task map. The `Quick run command` is supplemental once its Wave 1 artifacts exist, and from Wave 3 onward the promoted phase guards (`phase6_requirements_traceability_test.dart` + `phase6_source_guards_test.dart`) also become mandatory.
- **After every plan wave:** Run the focused phase suite for completed plans, then the full suite command before final close.
- **Before `$gsd-verify-work`:** Full suite command must be green.
- **Max feedback latency:** 150 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | UX-02 | unit | `flutter test test/core/theme/app_theme_extension_test.dart` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | UX-02 | widget | `flutter test test/core/widgets/app_screen_scaffold_test.dart test/core/widgets/app_section_card_test.dart test/core/widgets/app_section_header_test.dart test/core/widgets/app_status_badge_test.dart test/core/widgets/app_operational_snackbar_test.dart test/core/widgets/app_confirmation_dialog_test.dart` | ❌ W0 | ⬜ pending |
| 06-01-03 | 01 | 1 | UX-01,UX-02 | source-doc | `bash -lc "! rg -n 'Mental Health App|Pricing-Focused Landing|Minimal Single Column' design-system/share-mate/MASTER.md && rg -n 'dark|transactional|surface|status|Home|Create|Detail|Catalog' design-system/share-mate/MASTER.md"` | ✅ | ⬜ pending |
| 06-02-01 | 02 | 2 | UX-01,UX-02 | widget | `flutter test test/features/home/presentation/screens/home_screen_debt_priority_test.dart test/features/home/presentation/widgets/home_header_sync_badge_test.dart` | ✅ | ⬜ pending |
| 06-02-02 | 02 | 2 | UX-01,UX-02 | widget | `flutter test test/features/home/presentation/widgets/debt_home_kpi_card_test.dart test/features/home/presentation/widgets/home_header_sync_badge_test.dart` | ✅ | ⬜ pending |
| 06-02-03 | 02 | 2 | UX-01,UX-02 | widget | `flutter test test/features/home/presentation/screens/home_screen_debt_priority_test.dart test/features/home/presentation/widgets/debt_home_kpi_card_test.dart test/features/home/presentation/widgets/home_header_sync_badge_test.dart` | ✅ | ⬜ pending |
| 06-03-01 | 03 | 2 | UX-01,UX-02 | widget | `flutter test test/core/widgets/app_text_field_test.dart test/core/widgets/app_date_field_test.dart test/core/widgets/app_sheet_container_test.dart test/core/widgets/app_sticky_submit_bar_test.dart test/features/subscriptions/presentation/widgets/billing_cycle_selector_test.dart` | ❌ W0 | ⬜ pending |
| 06-03-02 | 03 | 2 | UX-01,UX-02 | widget | `flutter test test/features/subscriptions/presentation/screens/create_subscription_screen_test.dart test/features/subscriptions/presentation/screens/create_group_subscription_screen_test.dart test/features/subscriptions/presentation/widgets/add_member_dialog_test.dart` | ❌ W0 | ⬜ pending |
| 06-03-03 | 03 | 2 | UX-01,UX-02 | widget | `flutter test test/features/subscriptions/presentation/widgets/service_template_sheet_test.dart test/features/subscriptions/presentation/widgets/contacts_selection_sheet_test.dart test/features/subscriptions/presentation/widgets/split_bill_preview_card_test.dart` | ❌ W0 | ⬜ pending |
| 06-04-01 | 04 | 2 | UX-01,UX-02 | widget | `flutter test test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart` | ✅ | ⬜ pending |
| 06-04-02 | 04 | 2 | UX-01,UX-02 | widget | `flutter test test/features/subscriptions/presentation/screens/subscription_detail_payment_ordering_test.dart test/features/subscriptions/presentation/widgets/payment_status_toggle_test.dart` | ✅ | ⬜ pending |
| 06-04-03 | 04 | 2 | UX-01,UX-02 | widget | `flutter test test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart` | ✅ | ⬜ pending |
| 06-05-01 | 05 | 3 | UX-01,UX-02 | traceability | `flutter test test/features/subscriptions/phase6_requirements_traceability_test.dart test/features/subscriptions/phase6_source_guards_test.dart` | ❌ W0 | ⬜ pending |
| 06-05-02 | 05 | 3 | UX-01,UX-02 | golden-bootstrap+verify | `flutter test --update-goldens test/features/home/presentation/screens/home_screen_golden_test.dart test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart && flutter test test/features/home/presentation/screens/home_screen_golden_test.dart test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart` | ❌ W0 | ⬜ pending |
| 06-05-03 | 05 | 3 | UX-01,UX-02 | integration | `flutter test integration_test/subscription_setup_flow_test.dart && flutter test integration_test/subscription_setup_offline_catalog_test.dart && flutter test integration_test/payment_debt_home_flow_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/theme/app_theme_extension_test.dart` — semantic theme/token contract for UX-02 foundation.
- [ ] `test/core/widgets/app_screen_scaffold_test.dart` — shared screen shell contract.
- [ ] `test/core/widgets/app_section_card_test.dart` — shared card variants and density roles.
- [ ] `test/core/widgets/app_section_header_test.dart` — shared section header hierarchy contract.
- [ ] `test/core/widgets/app_status_badge_test.dart` — status semantics and visual variants.
- [ ] `test/core/widgets/app_operational_snackbar_test.dart` — shared feedback surface contract.
- [ ] `test/core/widgets/app_confirmation_dialog_test.dart` — shared destructive confirmation contract.
- [ ] `test/core/widgets/app_text_field_test.dart` — shared text-field theming contract.
- [ ] `test/core/widgets/app_date_field_test.dart` — shared date-field trigger contract.
- [ ] `test/core/widgets/app_sheet_container_test.dart` — shared bottom-sheet surface contract.
- [ ] `test/core/widgets/app_sticky_submit_bar_test.dart` — shared sticky submit CTA contract.
- [ ] `test/features/subscriptions/phase6_requirements_traceability_test.dart` — phase-level guard for UX-01/UX-02.
- [ ] `test/features/subscriptions/phase6_source_guards_test.dart` — scoped hardcoded-style regressions.
- [ ] `test/features/home/presentation/screens/home_screen_golden_test.dart` — Home first fold visual contract.
- [ ] `test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart` — Create/Split compact flow visual contract.
- [ ] `test/features/subscriptions/presentation/screens/create_subscription_screen_test.dart` — Routed single-create surface adoption contract.
- [ ] `test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart` — Detail summary-first visual contract.
- [ ] `test/goldens/phase6/home_screen_first_fold.png` — Home golden baseline asset.
- [ ] `test/goldens/phase6/create_group_subscription_screen_default.png` — Create default-state golden baseline asset.
- [ ] `test/goldens/phase6/create_group_subscription_screen_with_members.png` — Create with-members golden baseline asset.
- [ ] `test/goldens/phase6/subscription_detail_screen_summary_first.png` — Detail summary-first golden baseline asset.

---

## Golden Baseline Contract

- Baseline directory: `test/goldens/phase6/`
- Bootstrap command: `flutter test --update-goldens test/features/home/presentation/screens/home_screen_golden_test.dart test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart`
- Steady-state verification: `flutter test test/features/home/presentation/screens/home_screen_golden_test.dart test/features/subscriptions/presentation/screens/create_group_subscription_screen_golden_test.dart test/features/subscriptions/presentation/screens/subscription_detail_screen_golden_test.dart`
- Expected assets:
  - `test/goldens/phase6/home_screen_first_fold.png`
  - `test/goldens/phase6/create_group_subscription_screen_default.png`
  - `test/goldens/phase6/create_group_subscription_screen_with_members.png`
  - `test/goldens/phase6/subscription_detail_screen_summary_first.png`

---

## Supplemental Plan-Level Guards

- Plan 02 final gate: `bash -lc "! rg -n 'Color\\(0xFF|LinearGradient\\(|SnackBar\\(' lib/features/home/presentation/screens/home_screen.dart lib/features/home/presentation/widgets/home_header.dart lib/features/home/presentation/widgets/debt_home_kpi_card.dart lib/features/home/presentation/widgets/next_collection_card.dart lib/features/home/presentation/widgets/stats_cards.dart lib/features/home/presentation/widgets/action_required_section.dart lib/features/home/presentation/widgets/active_subscriptions_section.dart"`
- Plan 03 final gate: `bash -lc "! rg -n 'Color\\(0xFF|LinearGradient\\(|AlertDialog\\(' lib/features/subscriptions/presentation/screens/create_subscription_screen.dart lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart lib/features/subscriptions/presentation/widgets/billing_cycle_selector.dart lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart lib/features/subscriptions/presentation/widgets/service_template_sheet.dart lib/features/subscriptions/presentation/widgets/contacts_selection_sheet.dart lib/features/subscriptions/presentation/widgets/add_member_dialog.dart lib/features/subscriptions/presentation/widgets/quick_contact_form.dart lib/features/subscriptions/presentation/widgets/members_list_section.dart lib/features/subscriptions/presentation/widgets/billing_day_hint.dart lib/features/contacts/presentation/widgets/edit_contact_dialog.dart"`
- Plan 04 final gate: `bash -lc "! rg -n 'Color\\(0xFF|LinearGradient\\(|AlertDialog\\(|SnackBar\\(' lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart lib/features/subscriptions/presentation/widgets/payment_stats_card.dart lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart lib/features/subscriptions/presentation/widgets/analytics/overview_cards_section.dart lib/features/subscriptions/presentation/widgets/subscription_detail_summary_hero.dart lib/features/subscriptions/presentation/widgets/subscription_detail_sync_status_card.dart"`
- Release-gate source guard intent: `test/features/subscriptions/phase6_source_guards_test.dart` must enforce the same hardcoded-color/gradient plus local `SnackBar` / `AlertDialog` bans for scoped Phase 6 surfaces.
- Supplemental provider guards for Phase 6 Create flow: `flutter test test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_e2e_test.dart test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_split_test.dart test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_contacts_test.dart`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dark-theme hierarchy feels coherent across Home, Create, Catalog sheets/selectors, Split preview, and Detail | UX-01 | Visual consistency and hierarchy quality exceed what behavior tests can assert | Run app on phone-sized simulator, compare first fold and section rhythm across the five surfaces, verify they feel like one system with restrained accents |
| Focus states, text contrast, and tap targets remain usable after token refactor | UX-02 | Requires human accessibility review in rendered UI | Navigate key CTAs/inputs/sheets with keyboard/screen focus where possible, validate visible focus and readable text on dark surfaces |
| Bottom-sheet/searchable selector ergonomics remain compact but understandable | UX-01 | Depends on interaction feel, sheet height, and search affordances | Open service template and contact selection sheets, verify selection/search/close flow remains fast and visually consistent |
| Golden baselines match intended hierarchy rather than stale local styling | UX-01,UX-02 | Goldens catch drift but still need a human-approved first snapshot | Review generated goldens before approval and confirm summary-first/detail and compact-form/create states represent the intended system |
| Shared shell, dialog, snackbar, field, and sheet primitives stay visually coherent after screen adoption | UX-02 | Core primitive regressions may not break a single screen assertion immediately | Spot-check `AppScreenScaffold`, `AppOperationalSnackbar`, `AppConfirmationDialog`, `AppSheetContainer`, and `AppStickySubmitBar` in the adopted screens before approving the phase |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 150s (Wave 1 quick run target).
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** ready for execute-phase verification
