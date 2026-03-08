# Phase 2 Research: Offline Sync Reliability Core

**Phase:** 02-offline-sync-reliability-core  
**Date:** 2026-03-08  
**Status:** Ready for planning  
**Primary requirements:** SYNC-01, SYNC-02, SYNC-03

## Inputs Reviewed

- `.planning/phases/02-offline-sync-reliability-core/02-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `lib/core/sync/payment_sync_queue.dart`
- `lib/main.dart`
- `lib/core/di/injection.dart`
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
- `lib/features/subscriptions/data/datasources/subscription_local_datasource.dart`
- `lib/features/subscriptions/presentation/providers/payment_provider.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/home_header.dart`
- `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `supabase/migrations/20251225_payment_history_enhancements.sql`
- `supabase/migrations/20260308_phase1_rls_hardening.sql`
- `test/security/rls_policy_audit_test.dart`

## Current State vs SYNC Requirements

| Requirement | Current state | Gap |
|---|---|---|
| `SYNC-01` queue with retry/backoff/terminal handling | Queue persists operations and tracks `retryCount`. Repository enqueues when remote mutation fails. | No worker/drain loop, no scheduling/backoff/jitter, no retry ceiling, no terminal/dead-letter path, no manual retry/clear actions. |
| `SYNC-02` deterministic conflict resolution (local optimistic vs monthly reset) | Optimistic local writes are implemented for mark/unmark operations. | Queue operation lacks cycle metadata (`due_date` snapshot). No reconciliation algorithm. No deterministic no-op/audit path for closed cycle. |
| `SYNC-03` sync state visible + privacy-safe logs | Some `debugPrint` traces exist; queue count exists internally. | No user-facing sync status in Home/Detail/Settings. Logs currently expose sensitive values (amounts, member IDs, notes context). No privacy logging policy enforcement. |

## Standard Stack

- Keep Riverpod for orchestration and UI status projection.
- Keep Hive encrypted storage for local queue state (already migrated in v2 encryption migration).
- Keep Supabase RPC boundary for atomic payment mutations.
- Add a dedicated sync orchestration layer in `lib/core/sync/*` rather than embedding queue-drain logic in widgets/providers.

## Architecture Patterns

1. **Outbox pattern (client-side)**
- Treat `payment_sync_queue` as persistent outbox with deterministic ordering by `createdAt`.
- Persist operation metadata needed for retries, conflict checks, and observability.

2. **Single-flight sync worker**
- One orchestrator controls draining (prevents concurrent processors).
- Triggers: app resume, foreground periodic tick, and after successful remote payment writes.

3. **Deterministic reconciliation by cycle boundary**
- Store cycle anchor at enqueue time (`dueDate` snapshot / derived cycle key).
- Before replay, compare local queued cycle to authoritative backend cycle context.
- If cycle closed, mark as conflict terminal no-op + audit metadata.

4. **Classified failures**
- Retryable: network, timeouts, 5xx, explicit transient codes.
- Terminal: non-retryable 4xx (except explicit transient), auth mismatch, invariant violations.

5. **Status projection layer**
- Aggregate queue + terminal state into user-facing sync status model:
  - `Synced`
  - `Pending`
  - `Requires action`
- Expose `lastSuccessfulSyncAt`, `pendingCount`, `terminalCount`.

## Implementation Options

### Option A: Minimal patch in repository (not recommended)

Implement retries and drain directly in `SubscriptionRepositoryImpl`.

**Pros**
- Lowest immediate code delta.
- Fast to start.

**Cons**
- Business mutations and sync engine become tightly coupled.
- Harder to guarantee single-flight processing and lifecycle triggers.
- Poor testability for retry scheduling/conflict cases.

### Option B: Dedicated `SyncOrchestrator` + enriched queue (recommended)

Introduce a core sync module with queue state, scheduler, classifier, and status projection.

**Pros**
- Clear separation of concerns.
- Deterministic processing and easier invariants.
- Strong testability and reusable sync status APIs for UI.

**Cons**
- More initial files and coordination.
- Requires migration of queue model fields.

### Option C: Backend-heavy queue via new server-side outbox (defer)

Move most retry/conflict logic to Supabase tables/functions, client becomes thin.

**Pros**
- Strong cross-device consistency model.
- Easier server-side observability.

**Cons**
- Larger backend scope and migration risk for this phase.
- Slower to deliver vs current architecture and roadmap sequencing.

## Recommended Approach

Adopt **Option B** now, with minimal backend augmentation for deterministic conflict checks.

### 1) Evolve queue schema (client)

Extend `PaymentSyncOperation` with fields needed for deterministic replay and observability:

- `status`: `pending | processing | terminal`
- `nextAttemptAt`: DateTime
- `lastAttemptAt`: DateTime?
- `lastErrorClass`: string?
- `lastErrorCode`: string?
- `terminalReason`: string?
- `cycleDueDate`: DateTime (snapshot used as cycle anchor)
- `idempotencyKey`: string (default to op id)

Keep data encrypted in existing `payment_sync_queue` Hive box.

### 2) Add sync engine in core

Create `lib/core/sync/payment_sync_orchestrator.dart` with responsibilities:

- `start()`/`stop()` lifecycle hooks.
- `triggerSync(reason)` entrypoint.
- Single-flight lock to avoid concurrent drains.
- Drain loop ordered by `createdAt` with per-operation processing.
- Retry scheduling: 5 attempts, exponential backoff + jitter.
- Terminal transition after retry budget exhausted.

Suggested timing defaults:
- base delay: 2s
- max delay: 60s
- jitter: 0..400ms
- max retries: 5

### 3) Deterministic conflict handling (`SYNC-02`)

Before applying queued operation:

1. Fetch authoritative member/subscription snapshot from backend.
2. Compute current backend cycle anchor (using `due_date` contract from phase context).
3. Compare with operation `cycleDueDate`.
4. If mismatch (cycle closed/advanced):
- Do not mutate remote state.
- Mark operation `terminal` with reason `cycle_conflict_noop`.
- Persist conflict audit metadata (non-PII).
5. If same cycle:
- Apply `paid/unpaid` RPC.
- If remote already equals desired state, treat as idempotent success.

This keeps convergence deterministic and prevents stale local intent from overriding a newer cycle.

### 4) Failure classification + dead-letter behavior (`SYNC-01`)

Implement `sync_error_classifier.dart` that maps exceptions to:

- `retryable`
- `terminal`
- `conflict`

Rules aligned with phase context:
- Retryable: network failures, 5xx, timeout/transient.
- Terminal: 4xx non-transient, auth/ownership errors, data invariant failures.
- Conflict: cycle mismatch detected by reconciliation logic.

Dead-letter can be modeled as `status=terminal` in same box (recommended for simplicity) with filtered queries:
- `getPending()`
- `getTerminal()`
- `retryTerminal()`
- `clearTerminalOnly()`

### 5) Sync status and privacy (`SYNC-03`)

Add `sync_status_provider.dart` that aggregates queue state and last successful sync timestamp.

UI surfaces:
- Home: global badge (Pending / Requires action).
- Subscription detail: contextual status for current subscription operations.
- Settings: detailed sync health + actions:
  - `Retry all`
  - `Clear terminal only`

Logging policy:
- Add `sync_logger.dart` wrapper.
- Never log PII or amounts/notes.
- Allow only technical metadata: operation id/hash, action, retry count, error class/code, timestamps.

### 6) Trigger points

- App bootstrap: initialize orchestrator and status store.
- App resume: trigger reconciliation + queue drain.
- After successful remote payment mutation: trigger opportunistic drain.
- Optional short foreground interval (throttled) for pending queue.

## Don’t Hand-Roll

- Do not build custom networking reachability stack first; rely on operation-attempt outcomes and retry classifier.
- Do not duplicate queue persistence across multiple boxes unless required; use one source with status partitioning.
- Do not expose raw exception payloads directly to logs/UI.

## Common Pitfalls

- Replaying queue without single-flight lock causes duplicate RPC calls.
- Missing cycle anchor in queued operation makes conflict resolution nondeterministic.
- Treating every 4xx as retryable creates infinite loops.
- Clearing full queue from UI can silently lose actionable failures.
- Logging payment amounts/member identifiers violates privacy requirement.

## File-Level Change Map

| File | Change | Requirements |
|---|---|---|
| `lib/core/sync/payment_sync_queue.dart` | Extend operation fields, add filtered queries and terminal actions. | SYNC-01, SYNC-03 |
| `lib/core/sync/payment_sync_orchestrator.dart` (new) | Implement drain loop, retry/backoff, trigger handling, lifecycle hooks. | SYNC-01 |
| `lib/core/sync/sync_error_classifier.dart` (new) | Typed retryable/terminal/conflict mapping. | SYNC-01, SYNC-02 |
| `lib/core/sync/sync_logger.dart` (new) | Privacy-safe structured logging wrapper. | SYNC-03 |
| `lib/core/sync/sync_status.dart` (new) | Domain model for UI-visible sync state. | SYNC-03 |
| `lib/main.dart` | Initialize orchestrator and app lifecycle trigger on resume. | SYNC-01, SYNC-02 |
| `lib/core/di/injection.dart` | Wire providers for orchestrator/status dependencies. | SYNC-01, SYNC-03 |
| `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart` | Enqueue cycle metadata/idempotency key; trigger sync after successful remotes. | SYNC-01, SYNC-02 |
| `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart` | Add fetch-for-reconcile helpers / conflict-aware apply path (or RPC wrapper). | SYNC-02 |
| `lib/features/home/presentation/widgets/home_header.dart` or `home_screen.dart` | Add global sync badge. | SYNC-03 |
| `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart` | Add per-subscription sync status chip/card. | SYNC-03 |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Add sync health section with manual actions. | SYNC-01, SYNC-03 |
| `supabase/migrations/*phase2*` (new, if needed) | Optional RPC/helper for cycle reconciliation and audit persistence. | SYNC-02 |

## Test Mapping

| Test file (planned) | Purpose | Requirements |
|---|---|---|
| `test/core/sync/payment_sync_queue_service_test.dart` | Queue transitions: pending -> retry -> terminal, terminal filtering/clear. | SYNC-01 |
| `test/core/sync/payment_sync_orchestrator_test.dart` | Retry schedule with jitter bounds, max attempts=5, single-flight drain. | SYNC-01 |
| `test/core/sync/sync_error_classifier_test.dart` | Exception mapping to retryable/terminal/conflict classes. | SYNC-01, SYNC-02 |
| `test/features/subscriptions/data/repositories/subscription_repository_impl_sync_test.dart` | Enqueue includes cycle metadata; optimistic write + queue fallback behavior. | SYNC-01, SYNC-02 |
| `test/core/sync/conflict_resolution_test.dart` | Closed-cycle queued op becomes deterministic no-op terminal conflict. | SYNC-02 |
| `test/features/subscriptions/presentation/providers/sync_status_provider_test.dart` | Aggregated status mapping (`Synced/Pending/Requires action`). | SYNC-03 |
| `test/features/home/presentation/widgets/home_header_sync_badge_test.dart` | Global sync badge rendering rules. | SYNC-03 |
| `test/features/settings/presentation/screens/settings_sync_section_test.dart` | `Retry all` and `Clear terminal only` wiring. | SYNC-01, SYNC-03 |

## Validation Architecture

This phase should ship only if all validation layers pass.

### Layer 1: Static and contract guards

- Ensure no sensitive payload logging in sync paths.
- Ensure sync queue exposes terminal-state APIs.

Executable checks:

```bash
rg -n "debugPrint\(.*(amount|memberName|userEmail|notes)" lib/core/sync lib/features/subscriptions/data/repositories/subscription_repository_impl.dart
rg -n "class PaymentSyncOperation|status|nextAttemptAt|retryCount" lib/core/sync/payment_sync_queue.dart
```

### Layer 2: Deterministic retry/backoff behavior

- Verify retry budget is capped at 5.
- Verify backoff increases monotonically and respects max cap.
- Verify single-flight prevents concurrent drains.

Executable checks:

```bash
flutter test test/core/sync/payment_sync_orchestrator_test.dart
flutter test test/core/sync/payment_sync_queue_service_test.dart
```

### Layer 3: Conflict resolution correctness

- Given queued operation from prior cycle and backend cycle advanced, result is `terminal conflict no-op`.
- Given same-cycle replay, operation applies or resolves idempotently.

Executable checks:

```bash
flutter test test/core/sync/conflict_resolution_test.dart
flutter test test/core/sync/sync_error_classifier_test.dart
```

### Layer 4: UI sync-status observability

- Home shows global sync state badge.
- Detail shows subscription-context sync state.
- Settings exposes sync health + manual recovery actions.

Executable checks:

```bash
flutter test test/features/subscriptions/presentation/providers/sync_status_provider_test.dart
flutter test test/features/home/presentation/widgets/home_header_sync_badge_test.dart
flutter test test/features/settings/presentation/screens/settings_sync_section_test.dart
```

### Layer 5: End-to-end operational scenario

- Simulate offline mark/unmark -> queued.
- Restore connectivity -> automatic drain on resume.
- Inject transient failures -> eventual success within retry budget.
- Inject terminal failure/conflict -> `Requires action` + dead-letter retained.

Executable checks (phase-level gate):

```bash
flutter test test/core/sync test/features/subscriptions/data/repositories/subscription_repository_impl_sync_test.dart
```

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Queue model migration breaks old entries | Lost pending ops after upgrade | Backward-compatible adapter defaults + migration test seeding legacy entries. |
| Duplicate processing under rapid triggers | Double writes / inconsistent state | Single-flight lock + per-op processing token/idempotency key. |
| Misclassified errors | Retry storms or premature terminal failures | Central classifier tests with explicit fixtures per error class. |
| Conflict logic disagrees with future billing-reset implementation | Non-deterministic convergence | Keep cycle-derivation helper isolated and shared with Phase 5 reset contract. |
| UI exposes technical jargon | Poor user comprehension | Restrict status copy to `Synced`, `Pending`, `Requires action` + clear action labels. |
| Privacy leakage in logs | Security/privacy non-compliance | Dedicated sync logger + static grep guard in CI. |

## Recommended Planning Sequence

1. Queue schema and migration-safe adapters.
2. Sync orchestrator + error classifier + terminal flow.
3. Deterministic conflict reconciliation path.
4. Sync status provider and UI surfaces.
5. Full validation gates and phase UAT scenarios.
