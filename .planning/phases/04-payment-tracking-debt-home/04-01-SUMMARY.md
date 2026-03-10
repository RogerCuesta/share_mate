---
phase: 04-payment-tracking-debt-home
plan: "01"
subsystem: home
tags: [riverpod, debt-dashboard, payments, deterministic-selection]
requires:
  - phase: 02-offline-sync-reliability-core
    provides: canonical pending/sync behavior for payment state convergence
  - phase: 03-subscription-setup-flow
    provides: active subscription and member-share data consumed by Home
provides:
  - DebtHomeSnapshot + NextCollectionCandidate read models for Home debt state
  - deterministic next-collection selector policy (overdue, nearest date, amount, stable id)
  - composed debtHomeSnapshotProvider built from subscriptions providers
affects: [04-02, 04-03, 04-04, home-dashboard, payment-toggle-flow]
tech-stack:
  added: []
  patterns:
    - provider-level debt aggregation from existing pending/subscription providers
    - deterministic selector helpers isolated from widgets and covered by unit tests
key-files:
  created:
    - lib/features/home/presentation/models/debt_home_snapshot.dart
    - test/features/home/presentation/providers/debt_home_provider_test.dart
  modified:
    - lib/features/home/presentation/providers/debt_home_provider.dart
    - lib/features/subscriptions/presentation/providers/subscriptions_provider.dart
    - test/features/home/presentation/providers/debt_next_collection_selector_test.dart
key-decisions:
  - "Use subscription-level dueDate as the canonical urgency signal while preserving member-level pending sums for total debt."
  - "Model debt-free explicitly as snapshot total=0 and nextCollection=null so UI can render `Todo al dia` without ad-hoc conditions."
  - "Keep policy helpers pure and provider-agnostic, then compose them in a single Riverpod FutureProvider for Home reuse."
patterns-established:
  - "Debt Home read-model pattern: pure selector helpers + provider composition over existing feature providers."
  - "Deterministic tie-break contract encoded once and reused through dedicated tests."
requirements-completed: [DASH-01, DASH-02]
duration: 5 min
completed: 2026-03-10
---

# Phase 04 Plan 01: Debt Read Foundation Summary

**Canonical Home debt snapshot with deterministic next-collection selection built on top of existing payment/subscription providers**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-10T21:12:18Z
- **Completed:** 2026-03-10T21:18:13Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added a new Home read model (`DebtHomeSnapshot`, `NextCollectionCandidate`) to represent debt and urgency consistently.
- Implemented pure selector helpers that enforce policy order: overdue first, then nearest due date, then highest pending amount, then stable subscription id.
- Composed `debtHomeSnapshotProvider` from `pendingPaymentsProvider` and `activeSubscriptionsProvider` so Home can consume one canonical snapshot.
- Locked behavior with provider/selector tests, including debt-free and equal-date mixed-amount regression cases.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add debt snapshot domain model + deterministic selector helpers** - `12cd9e1` (feat)
2. **Task 2: Compose debt snapshot provider from existing subscriptions providers** - `a609087` (feat)
3. **Task 3: Add provider tests covering debt-free, overdue, and tie-break scenarios** - `f0ce086` (test)

## Files Created/Modified
- `lib/features/home/presentation/models/debt_home_snapshot.dart` - Debt snapshot and next-collection candidate model contracts for Home.
- `lib/features/home/presentation/providers/debt_home_provider.dart` - Pure policy helpers and composed `debtHomeSnapshotProvider`.
- `lib/features/subscriptions/presentation/providers/subscriptions_provider.dart` - Added `activeSubscriptionsByIdProvider` and analyzer-safe provider cleanup.
- `test/features/home/presentation/providers/debt_home_provider_test.dart` - Provider-level tests for debt-free and composed snapshot outcomes.
- `test/features/home/presentation/providers/debt_next_collection_selector_test.dart` - Selector policy tests for overdue/nearest/amount/stable ordering.

## Decisions Made
- Canonical urgency uses subscription-level `dueDate` to avoid mixed member-date drift in Home candidate ranking.
- Debt totals always aggregate member-level pending amounts so payment split precision is preserved.
- `debtHomeSnapshotProvider` is the single read entry point for Home debt surfaces to reduce per-widget aggregation drift.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing selector test file required by Task 1 verification**
- **Found during:** Task 1
- **Issue:** `flutter test test/features/home/presentation/providers/debt_next_collection_selector_test.dart` could not run because the file did not exist yet.
- **Fix:** Added selector test suite during Task 1 to unblock required verification.
- **Files modified:** `test/features/home/presentation/providers/debt_next_collection_selector_test.dart`
- **Verification:** Task 1 selector test command passed.
- **Committed in:** `12cd9e1`

**2. [Rule 3 - Blocking] Analyzer gate failed on subscriptions provider lint/errors**
- **Found during:** Task 2
- **Issue:** `flutter analyze` on required files failed under fatal-info policy.
- **Fix:** Kept generated Riverpod ref types, converted failure throws to `StateError`, and added focused lint handling needed for gate compliance.
- **Files modified:** `lib/features/subscriptions/presentation/providers/subscriptions_provider.dart`
- **Verification:** Required Task 2 analyze command passed with no issues.
- **Committed in:** `a609087`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were verification blockers and kept scope aligned with debt foundation objectives.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Debt aggregation and next-collection policy are now centralized and test-locked.
Ready for `04-02` to wire Home UI surfaces and payment toggle flows to the canonical snapshot provider.

---
*Phase: 04-payment-tracking-debt-home*
*Completed: 2026-03-10*

## Self-Check: PASSED

- Found summary and all listed key files on disk.
- Verified task commits `12cd9e1`, `a609087`, and `f0ce086` exist in git history.
