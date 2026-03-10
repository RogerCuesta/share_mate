---
phase: 04-payment-tracking-debt-home
plan: "03"
subsystem: ui
tags: [flutter, riverpod, home-dashboard, debt-priority, widget-tests]
requires:
  - phase: 04-01
    provides: "Canonical debt aggregation via debtHomeSnapshotProvider."
provides:
  - "Debt-first Home hierarchy with dedicated KPI and next-collection cards."
  - "Explicit debt-free state (`Todo al dia`) with zero debt and no misleading urgency."
  - "Screen and widget tests that lock ordering and debt-priority rendering."
affects: [04-payment-tracking-debt-home, 05-billing-automation-cycle]
tech-stack:
  added: []
  patterns:
    - "Provider-driven debt snapshot rendering for Home primary metrics."
    - "Widget/screen tests with Riverpod overrides for deterministic Home assertions."
key-files:
  created:
    - lib/features/home/presentation/widgets/debt_home_kpi_card.dart
    - lib/features/home/presentation/widgets/next_collection_card.dart
    - test/features/home/presentation/widgets/debt_home_kpi_card_test.dart
    - test/features/home/presentation/widgets/next_collection_card_test.dart
    - test/features/home/presentation/screens/home_screen_debt_priority_test.dart
  modified:
    - lib/features/home/presentation/screens/home_screen.dart
    - lib/features/home/presentation/widgets/stats_cards.dart
    - lib/features/home/presentation/widgets/action_required_section.dart

key-decisions:
  - "Placed debt KPI + next-collection directly below Home header; legacy stats and action-required remain secondary."
  - "Screen-level debt-priority verification uses provider overrides instead of backend/DI integration for deterministic assertions."

patterns-established:
  - "Home financial-priority pattern: debt KPI and next collection always render before secondary sections."
  - "Debt-free pattern: show `Todo al dia` + `$0.00` and suppress overdue urgency copy."

requirements-completed: [DASH-01, PAYM-02]
duration: 7min
completed: 2026-03-10
---

# Phase 04 Plan 03: Home Debt Priority Summary

**Debt-first Home rendering now surfaces total debt and next collection urgency immediately using canonical snapshot data with locked ordering tests.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-10T22:15:12Z
- **Completed:** 2026-03-10T22:21:58Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added dedicated Home widgets for `Deuda total a favor` and `Proximo cobro` with urgency and debt-free copy.
- Refactored Home sliver hierarchy so debt-priority blocks render above secondary stats/actions.
- Added screen-level test coverage for ordering, candidate visibility, and `Todo al dia` no-overdue behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build dedicated Home widgets for debt KPI and next-collection candidate** - `8db87be` (feat)
2. **Task 2: Integrate debt-priority section into Home screen hierarchy** - `663ce21` (feat)
3. **Task 3: Add screen-level tests for debt-priority ordering and zero-debt state** - `2eb94b0` (test)

**Plan metadata:** Pending final docs commit

## Files Created/Modified
- `lib/features/home/presentation/widgets/debt_home_kpi_card.dart` - Primary KPI card for total pending debt and `Todo al dia` state.
- `lib/features/home/presentation/widgets/next_collection_card.dart` - Next collection card with overdue/today/in-days urgency copy.
- `lib/features/home/presentation/screens/home_screen.dart` - Debt-priority section integrated above secondary Home blocks.
- `lib/features/home/presentation/widgets/stats_cards.dart` - Added stable section key for hierarchy assertions.
- `lib/features/home/presentation/widgets/action_required_section.dart` - Added stable section key for ordering verification.
- `test/features/home/presentation/widgets/debt_home_kpi_card_test.dart` - Widget tests for KPI copy and debt-free rendering.
- `test/features/home/presentation/widgets/next_collection_card_test.dart` - Widget tests for urgency copy and no-candidate state.
- `test/features/home/presentation/screens/home_screen_debt_priority_test.dart` - Screen tests for order, candidate rendering, and zero-debt behavior.

## Decisions Made
- Prioritized debt information above existing stats and action-required content while preserving current visual language and component structure.
- Kept verification focused on provider-driven Home composition to ensure PAYM-02 responsiveness remains tied to canonical provider updates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolved analyzer lint blockers during Task 2 verification**
- **Found during:** Task 2 (Integrate debt-priority section into Home screen hierarchy)
- **Issue:** `flutter analyze` returned non-zero due lint blockers (`prefer_const_constructors`, `use_raw_strings`) in modified files.
- **Fix:** Updated const usage in Home loading widget and converted escaped currency literal to raw string.
- **Files modified:** `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/presentation/widgets/next_collection_card.dart`
- **Verification:** Re-ran Task 2 analyze command; no issues found.
- **Committed in:** `663ce21` (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification blockers were resolved without scope expansion; functional scope remained aligned to 04-03.

## Issues Encountered
- Initial screen test could not find `action-required-section` in the first viewport due sliver rendering boundaries. Resolved by using a larger test viewport and conditional `scrollUntilVisible` before order assertions.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Home now exposes debt-first KPI and next collection urgency with automated coverage for priority ordering and empty-state behavior.
- Phase 4 remaining plans can build on this structure for broader payment/sync/cycle readiness checks.

## Self-Check: PASSED
- Verified required files exist on disk.
- Verified task commit hashes `8db87be`, `663ce21`, and `2eb94b0` exist in git history.

---
*Phase: 04-payment-tracking-debt-home*
*Completed: 2026-03-10*
