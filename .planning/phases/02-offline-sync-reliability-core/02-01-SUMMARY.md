---
phase: 02-offline-sync-reliability-core
plan: "01"
subsystem: sync
tags: [offline-sync, hive, retry, orchestrator, riverpod]
requires:
  - phase: 01-data-safety-access-security
    provides: encrypted local storage and migration-safe queue persistence
provides:
  - Bounded offline payment retry engine with terminal partition handling
  - Single-flight queue orchestrator with lifecycle and foreground triggers
  - Sync error classifier and reliability tests for queue/orchestrator behavior
affects: [offline-sync-reliability-core, payment-tracking-and-home, billing-automation-cycle]
tech-stack:
  added: []
  patterns: [single-flight outbox draining, bounded exponential retry with jitter, terminal dead-letter partition]
key-files:
  created:
    - lib/core/sync/payment_sync_orchestrator.dart
    - lib/core/sync/sync_error_classifier.dart
    - test/core/sync/payment_sync_orchestrator_test.dart
    - test/core/sync/payment_sync_queue_service_test.dart
    - test/core/sync/sync_error_classifier_test.dart
  modified:
    - lib/core/sync/payment_sync_queue.dart
    - lib/core/di/injection.dart
    - lib/main.dart
    - lib/features/subscriptions/data/repositories/subscription_repository_impl.dart
key-decisions:
  - "Queue rows now preserve terminal failures for manual recovery instead of deleting failed operations."
  - "Foreground reconciliation runs on a 45-second interval with anti-overlap guard plus orchestrator single-flight."
  - "Only foreground interval triggers are throttled; app resume and post-remote-write triggers bypass throttle."
patterns-established:
  - "Sync orchestration pattern: PaymentSyncOrchestrator.start + triggerSync(reason) as the shared entrypoint."
  - "Queue retry metadata pattern: status/nextAttemptAt/lastAttemptAt/error class+code persisted per operation."
requirements-completed: [SYNC-01]
duration: 12 min
completed: 2026-03-08
---

# Phase 02 Plan 01: Sync Engine Foundation Summary

**Offline payment outbox now drains via a single-flight worker with 5-attempt exponential retry+jitter, terminal partition retention, and lifecycle-triggered reconciliation.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-08T17:34:01Z
- **Completed:** 2026-03-08T17:46:44Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Upgraded `PaymentSyncOperation` persistence with retry scheduling fields, terminal metadata, and terminal-only recovery APIs.
- Added `PaymentSyncOrchestrator` + `SyncErrorClassifier` implementing deterministic single-flight draining and bounded retry/terminal flow.
- Wired app bootstrap/lifecycle/repository mutation flow to trigger the same orchestrator path without blocking UI responsiveness.

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade queue state model for retry scheduling and terminal partitioning** - `df781ae` (feat)
2. **Task 2: Implement single-flight orchestrator with bounded retry/backoff policy** - `3ab7c22` (feat)
3. **Task 3: Wire sync orchestration to app bootstrap and payment mutation flow** - `8340d04` (feat)

**Plan metadata:** pending

## Files Created/Modified
- `lib/core/sync/payment_sync_queue.dart` - Added queue status model, retry scheduling, terminal transitions, and recovery APIs.
- `lib/core/sync/payment_sync_orchestrator.dart` - Implemented deterministic single-flight queue draining with exponential backoff + jitter.
- `lib/core/sync/sync_error_classifier.dart` - Added retryable vs terminal classification with error code extraction.
- `lib/core/di/injection.dart` - Registered orchestrator/queue/classifier providers and injected orchestrator into subscriptions repository.
- `lib/main.dart` - Started orchestrator at app startup and added resume + foreground interval sync triggers.
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart` - Triggered sync after successful remote writes and enriched queued fallback metadata.
- `test/core/sync/payment_sync_queue_service_test.dart` - Added queue lifecycle and terminal recovery coverage.
- `test/core/sync/payment_sync_orchestrator_test.dart` - Added deterministic order, max-attempt, retry scheduling, and single-flight guard tests.
- `test/core/sync/sync_error_classifier_test.dart` - Added retryable/terminal classification tests.

## Decisions Made
- Persisting terminal operations in the same encrypted queue box gives recoverability (`retryTerminal`) without adding a new storage surface.
- Orchestrator retries are capped with `currentAttempt < maxAttempts` so the 5th failed attempt transitions terminal immediately.
- Post-remote-write sync triggering remains non-blocking by using fire-and-forget `triggerSync` calls from repository success paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected false retry classification for PostgreSQL permission code `42501`**
- **Found during:** Task 2 (orchestrator + classifier tests)
- **Issue:** Initial classifier logic treated status-like fragment `425` as retryable, causing non-retryable permission failures to requeue.
- **Fix:** Replaced loose fragment matching with explicit HTTP status extraction (`408/429/5xx`) plus retry keyword checks.
- **Files modified:** `lib/core/sync/sync_error_classifier.dart`, `test/core/sync/sync_error_classifier_test.dart`
- **Verification:** `flutter test test/core/sync/payment_sync_orchestrator_test.dart test/core/sync/sync_error_classifier_test.dart`
- **Committed in:** `3ab7c22`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Auto-fix was required to enforce bounded retries and correct terminal classification behavior.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Queue reliability core for `SYNC-01` is now in place and verified by targeted sync tests.
- Ready for `02-02-PLAN.md` to implement deterministic conflict reconciliation (`SYNC-02`) on top of this orchestrator foundation.

---
*Phase: 02-offline-sync-reliability-core*
*Completed: 2026-03-08*

## Self-Check: PASSED
