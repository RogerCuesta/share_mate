---
phase: 03-subscription-setup-flow
plan: "04"
subsystem: subscriptions
tags: [flutter, subscriptions, split-calculator, billing-anchor-day, riverpod]

requires:
  - phase: 03-subscription-setup-flow
    provides: Catalog + contacts setup flows from plans 03-01/02/03
provides:
  - Deterministic shared split calculator with owner remainder assignment
  - Split persistence parity between preview math and repository writes
  - Billing anchor-day normalization with overflow-month UI hint
affects: [phase-03-subscription-setup-flow, phase-04-payment-tracking-debt-home, subscriptions, billing-cycle]

tech-stack:
  added: []
  patterns:
    - Currency split calculations are cents-based in a shared domain service
    - Form submit payloads persist billing anchor day and normalized local date-only due date

key-files:
  created:
    - lib/features/subscriptions/domain/services/split_calculator.dart
    - lib/features/subscriptions/domain/services/billing_date_normalizer.dart
    - lib/features/subscriptions/presentation/widgets/billing_day_hint.dart
    - test/features/subscriptions/domain/services/split_calculator_test.dart
    - test/features/subscriptions/domain/services/billing_date_normalizer_test.dart
    - test/features/subscriptions/data/repositories/subscription_repository_split_persistence_test.dart
    - test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_split_test.dart
  modified:
    - lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart
    - lib/features/subscriptions/data/repositories/subscription_repository_impl.dart
    - lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart
    - lib/features/subscriptions/data/models/subscription_member_model.dart
    - lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart
    - lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart

key-decisions:
  - "All split outputs (preview + persistence) now come from SplitCalculator using integer-cents math."
  - "Repository add-member fallback computes default amount from current member rows + pending member, never from stale sharedWith/costPerPerson."
  - "Create/edit flows persist billingAnchorDay and dueDate normalized via local date-only month normalization."

patterns-established:
  - "Owner remainder policy is explicit and deterministic across UI and data layers."
  - "Billing overflow guidance is surfaced as contextual hint when anchor day exceeds current month length."

requirements-completed: [SPLT-01, SPLT-02, SPLT-03]
duration: 11 min
completed: 2026-03-08
---

# Phase 03 Plan 04: Split & Billing Correctness Summary

**Deterministic split and billing-date setup pipeline using shared cents-based math, anchor-day normalization, and parity tests from preview through persistence**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-08T23:16:11Z
- **Completed:** 2026-03-08T23:27:34Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Added a shared `SplitCalculator` service and unit tests covering owner inclusion, cent remainder behavior, and rounding edge cases.
- Removed split drift paths by routing provider and repository split persistence through the same calculator outputs.
- Added `BillingDateNormalizer` with anchor-day overflow handling, persisted `billingAnchorDay` in setup flows, and exposed an in-form billing overflow hint.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create shared split calculator and cover rounding edge cases** - `8a00048` (feat)
2. **Task 2: Remove split drift by reusing shared calculator in form + repository persistence** - `f5fbeb1` (feat)
3. **Task 3: Add billing anchor normalization utility + form hint behavior** - `5d4958e` (feat)

## Files Created/Modified
- `lib/features/subscriptions/domain/services/split_calculator.dart` - Shared deterministic split engine with owner-remainder contract.
- `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart` - Unified split source + billing anchor/day normalization in create/edit submit paths.
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart` - Split-based fallback amount derivation for add-member persistence.
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart` - Update payload now persists `billing_anchor_day`; member amount updates are cents-normalized.
- `lib/features/subscriptions/presentation/widgets/billing_day_hint.dart` - Contextual overflow-month hint component for billing anchor behavior.
- `test/features/subscriptions/data/repositories/subscription_repository_split_persistence_test.dart` - Guards persistence parity for explicit and fallback split amounts.
- `test/features/subscriptions/domain/services/billing_date_normalizer_test.dart` - Guards month overflow normalization and local date-only semantics.

## Decisions Made
- Split logic moved fully into a pure domain service to eliminate arithmetic divergence between preview and persistence.
- Billing date handling now treats local date-only values as canonical in provider state to avoid UTC-driven off-by-one behavior.
- `billingAnchorDay` is explicitly preserved in both create and update payloads so month overflow normalization remains stable over time.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Wired billing overflow hint into the active setup screen render path**
- **Found during:** Task 3
- **Issue:** `BillingDayHint` would not surface in UI without connecting it from screen state into `SplitBillPreviewCard`.
- **Fix:** Passed `billingAnchorDay` and `renewalDate` from `create_group_subscription_screen.dart` into preview card and rendered hint contextually.
- **Files modified:** `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`, `lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart`
- **Verification:** `flutter analyze ...` plus full plan verification command set.
- **Committed in:** `5d4958e`

**2. [Rule 3 - Blocking] Cleared analyzer gate issues introduced during billing normalizer implementation**
- **Found during:** Task 3 verification
- **Issue:** Analyzer flagged constructor/order and redundant DateTime argument infos, blocking required verification gate.
- **Fix:** Moved helper function outside class constructor scope and simplified DateTime constructor usage in billing normalizer.
- **Files modified:** `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart`, `lib/features/subscriptions/domain/services/billing_date_normalizer.dart`
- **Verification:** `flutter analyze lib/features/subscriptions/domain/services lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart lib/features/subscriptions/presentation/widgets/billing_day_hint.dart`
- **Committed in:** `5d4958e`

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both deviations were necessary to satisfy SPLT-03 UX visibility and mandatory analyzer verification; no scope creep outside split/billing setup correctness.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- SPLT-01/02/03 are now covered by deterministic services and dedicated regression tests.
- Ready for the next plan in this phase: `03-05-PLAN.md`.

---
*Phase: 03-subscription-setup-flow*
*Completed: 2026-03-08*

## Self-Check: PASSED
- Verified summary file exists on disk.
- Verified task commit hashes exist in git history: `8a00048`, `f5fbeb1`, `5d4958e`.
