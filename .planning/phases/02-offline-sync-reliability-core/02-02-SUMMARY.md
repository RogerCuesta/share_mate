---
phase: 02-offline-sync-reliability-core
plan: "02"
subsystem: sync
tags: [offline-sync, conflict-resolution, supabase-rpc, hive, idempotency]
requires:
  - phase: 02-01
    provides: single-flight queue orchestration and retry/terminal queue lifecycle
provides:
  - Deterministic cycle-conflict preflight that converts stale-cycle replays into terminal business no-op outcomes
  - Queue-enqueued cycle anchors and idempotency keys for paid/unpaid/bulk fallback operations
  - Non-PII conflict audit migration and idempotency-aware payment RPC contracts
affects: [offline-sync-reliability-core, payment-tracking-and-home, billing-automation-cycle]
tech-stack:
  added: []
  patterns: [cycle-anchor preflight before replay mutation, terminal conflict no-op with audit metadata, idempotency-key propagation from enqueue to replay]
key-files:
  created:
    - lib/core/sync/payment_sync_conflict_resolver.dart
    - test/core/sync/conflict_resolution_test.dart
    - test/features/subscriptions/data/repositories/subscription_repository_impl_sync_test.dart
    - supabase/migrations/20260308_phase2_sync_conflict_reconciliation.sql
    - .planning/phases/02-offline-sync-reliability-core/deferred-items.md
  modified:
    - lib/core/sync/payment_sync_queue.dart
    - lib/core/sync/payment_sync_orchestrator.dart
    - lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart
    - lib/features/subscriptions/data/repositories/subscription_repository_impl.dart
    - test/core/sync/payment_sync_orchestrator_test.dart
key-decisions:
  - "Conflict preflight runs before replay mutation; cycle mismatch is terminalized as `cycle_conflict_noop` instead of retried."
  - "Same-cycle operations that are already applied remotely are treated as idempotent success and removed from queue."
  - "Conflict audit payload is constrained to technical metadata (operation/action/cycle/retry/idempotency), excluding amounts and notes."
patterns-established:
  - "Queue metadata pattern: every queued operation persists `cycleDueDate` and `idempotencyKey` for deterministic reconciliation."
  - "Replay safety pattern: preflight -> (terminal conflict | already-applied success | mutation) as a strict decision chain."
requirements-completed: [SYNC-02]
duration: 17 min
completed: 2026-03-08
---

# Phase 02 Plan 02: Deterministic Cycle Conflict Reconciliation Summary

**Offline replay now converges deterministically by cycle anchor: stale-cycle operations are terminal no-op conflicts with audit metadata, while same-cycle operations apply idempotently.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-03-08T17:50:00Z
- **Completed:** 2026-03-08T18:07:07Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Extended queued payment operation contracts with `cycleDueDate` and `idempotencyKey`, sourced at enqueue time for paid/unpaid/bulk fallback paths.
- Added `PaymentSyncConflictResolver` and integrated orchestrator preflight to enforce deterministic replay decisions (`apply`, `already-applied`, `cycle_conflict_noop`).
- Added migration-backed conflict audit plumbing and regression tests proving stale-cycle operations never hit paid/unpaid mutation RPC paths.

## Task Commits

Each task was committed atomically:

1. **Task 1: Persist deterministic cycle anchors in queued payment operations** - `f0c63f6` (feat)
2. **Task 2: Add conflict preflight resolver in orchestrator replay pipeline** - `3c7cd61` (feat)
3. **Task 3: Add optional backend reconciliation audit plumbing and regression coverage** - `26dad26` (feat)

**Plan metadata:** pending

## Files Created/Modified
- `lib/core/sync/payment_sync_queue.dart` - Added persistent `cycleDueDate`/`idempotencyKey` metadata with backward-compatible defaults.
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart` - Enqueue fallback paths now attach deterministic cycle anchors and idempotency keys.
- `lib/core/sync/payment_sync_conflict_resolver.dart` - Added preflight resolver that compares queued vs backend cycle context and detects already-applied state.
- `lib/core/sync/payment_sync_orchestrator.dart` - Added preflight gate, terminal no-op conflict handling, and audit hook dispatch before replay mutation.
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart` - Added sync preflight context + conflict audit contracts and idempotency-key RPC parameter plumbing.
- `supabase/migrations/20260308_phase2_sync_conflict_reconciliation.sql` - Added non-PII conflict audit table/function and idempotency-aware payment RPC signatures.
- `test/features/subscriptions/data/repositories/subscription_repository_impl_sync_test.dart` - Added queue metadata coverage for paid/unpaid/bulk fallback enqueue flows.
- `test/core/sync/conflict_resolution_test.dart` - Added stale-cycle and already-applied reconciliation tests, including audit contract assertions.

## Decisions Made
- Conflict resolution is executed as a preflight step before moving operations into replay mutation, which prevents stale intent writes from reaching business RPCs.
- Terminal cycle conflicts are treated as business no-op outcomes (`cycle_conflict_noop`) and are audited through metadata-only records.
- A scoped deferred-items log was added for pre-existing analyzer infos in unrelated legacy sections of `subscription_remote_datasource.dart`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Regression] Updated legacy orchestrator tests for new preflight/idempotency contract**
- **Found during:** Task 2 (conflict resolver + orchestrator integration)
- **Issue:** Existing `payment_sync_orchestrator_test.dart` stubs no longer matched remote call signatures/preflight behavior.
- **Fix:** Added cycle-context and conflict-audit mock stubs plus idempotency-key arguments in verification calls.
- **Files modified:** `test/core/sync/payment_sync_orchestrator_test.dart`
- **Verification:** `flutter test test/core/sync/payment_sync_orchestrator_test.dart`
- **Committed in:** `3c7cd61`

### Scope-Limited Deferrals

- `flutter analyze` on the plan target files still reports 11 pre-existing info-level lints in legacy sections of `subscription_remote_datasource.dart`.
- Logged to `.planning/phases/02-offline-sync-reliability-core/deferred-items.md` per scope-boundary rules.

---

**Total deviations:** 1 auto-fixed (1 regression) + 1 deferred out-of-scope lint bucket
**Impact on plan:** No behavior scope creep; deterministic conflict reconciliation goals were completed as planned.

## Issues Encountered
- Plan-level `flutter analyze` remains non-zero due pre-existing info lints in untouched legacy blocks; these were documented and deferred instead of broadening scope.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `SYNC-02` deterministic convergence rules are in place with test coverage for stale-cycle and already-applied paths.
- Ready for `02-03-PLAN.md` sync-status UX work to surface pending/terminal outcomes to Home/Detail/Settings.

---
*Phase: 02-offline-sync-reliability-core*
*Completed: 2026-03-08*

## Self-Check: PASSED
