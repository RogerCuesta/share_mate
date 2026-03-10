# Phase 5 Research: Billing Automation Cycle

**Phase:** 05-billing-automation-cycle  
**Date:** 2026-03-11  
**Status:** Ready for planning  
**Primary requirements:** BILL-01, BILL-02, BILL-03

## Inputs Reviewed

- `.planning/phases/05-billing-automation-cycle/05-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- AGENTS instructions from prompt (`/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/AGENTS.md` is not present in workspace)
- `lib/main.dart`
- `lib/core/di/injection.dart`
- `lib/core/sync/payment_sync_orchestrator.dart`
- `lib/core/sync/payment_sync_conflict_resolver.dart`
- `lib/core/sync/payment_sync_queue.dart`
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
- `lib/features/subscriptions/presentation/providers/sync_status_provider.dart`
- `lib/features/subscriptions/presentation/providers/payment_reconciliation_provider.dart`
- `lib/features/settings/domain/entities/app_settings.dart`
- `lib/features/settings/presentation/providers/settings_provider.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/home/presentation/widgets/home_header.dart`
- `lib/routing/app_router.dart`
- `supabase/migrations/20260308_phase2_sync_conflict_reconciliation.sql`
- `supabase/migrations/20260309_phase3_subscription_setup_foundation.sql`
- `supabase/migrations/20260310_phase4_bulk_payment_atomic.sql`

## Requirement Mapping Snapshot

| Requirement | Implementation target |
|---|---|
| `BILL-01` Local T-24h per active subscription | Add deterministic local reminder scheduler keyed by `subscriptionId + cycleDueDate` with per-subscription notification IDs and tap deep-link to subscription detail. |
| `BILL-02` Re-schedule on reopen/migration without critical duplicates | Run billing automation orchestrator on app start/resume + subscription mutations; rebuild schedule from canonical data and idempotent registry; clean stale notification IDs immediately. |
| `BILL-03` Backend monthly-cycle reset + client reconciliation | Add backend cycle reset function + scheduler (cron or fallback trigger), advancing due dates and resetting member payment state atomically; client re-fetch + existing sync conflict logic reconciles stale local intent. |

## Architecture Options

### Option A (recommended): Deterministic client scheduler + backend cycle-reset function

**Client side**
- New module: `lib/features/billing_automation/*`.
- Components:
  - `BillingReminderScheduler` (platform notification adapter + schedule/cancel APIs).
  - `BillingReminderRegistry` (Hive box storing `subscriptionId`, `cycleDueDate`, `notificationId`, `scheduledAt`, `timezoneId`).
  - `BillingAutomationOrchestrator` with `run(reason)` that computes desired schedule and applies diff (`toCreate`, `toKeep`, `toCancel`).
- Trigger points:
  - `app_start` and `app_resume` in `main.dart`.
  - After subscription create/update/delete and status changes (`active/paused/cancelled`).
  - After settings toggle `paymentRemindersEnabled` changes.
- Dedupe contract:
  - One reminder per `(subscriptionId, cycleDueDate)`.
  - Deterministic notification id (stable hash) OR persisted ID in registry.

**Backend side**
- New migration for cycle reset RPC:
  - reset all due active subscriptions whose cycle boundary has passed.
  - update `subscriptions.due_date` to next cycle date (using `billing_cycle` + `billing_anchor_day`).
  - reset related `subscription_members` to `has_paid=false`, `last_payment_date=null`, and aligned new `due_date`.
  - write reset audit row (`billing_cycle_resets`) for observability/reconciliation.
- Schedule execution:
  - Primary: `pg_cron` hourly job invoking RPC.
  - Fallback if `pg_cron` unavailable: scheduled Edge Function/invoker calling same RPC.

**Why recommended**
- Aligns with current architecture (offline-first + backend canonical).
- Uses existing sync conflict resolver (`cycleDueDate` preflight) to prevent stale queued operations from overriding a new cycle.
- Directly satisfies all three BILL requirements with bounded new surface.

### Option B: Client-only reset simulation + local reminders

- Keep all reset logic in app foreground logic, avoid backend scheduler.
- Rejected for Phase 5 because it breaks `BILL-03` (backend-driven reset) and is unreliable under long inactivity/multi-device scenarios.

## Integration Points (Planner-Ready)

### BILL-01

- `lib/features/settings/domain/entities/app_settings.dart`
  - Reuse `paymentRemindersEnabled` as feature gate.
- `lib/features/subscriptions/presentation/providers/subscriptions_provider.dart`
  - Use active subscriptions + `dueDate` as source for schedule computation.
- `lib/routing/app_router.dart`
  - Notification tap route target: existing `subscription-detail` (`/subscription/:id`).
- New files:
  - `lib/features/billing_automation/domain/models/billing_reminder_plan.dart`
  - `lib/features/billing_automation/data/local/billing_reminder_registry.dart`
  - `lib/features/billing_automation/data/platform/local_notification_adapter.dart`
  - `lib/features/billing_automation/domain/services/billing_reminder_scheduler.dart`

### BILL-02

- `lib/main.dart`
  - After sync orchestrator start/resume, invoke billing automation orchestrator (`app_start`, `app_resume`).
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
  - Trigger billing re-schedule after create/update/delete (same pattern as `_triggerSyncAfterRemoteWrite`).
- `lib/features/settings/presentation/providers/settings_provider.dart`
  - On reminder toggle update, trigger full re-schedule or full cancel.
- Registry logic
  - On every run, cancel unknown/stale IDs and keep only desired entries.
  - Persist last known timezone id; on change, recalculate all future reminder times.

### BILL-03

- `supabase/migrations/*phase5*_billing_cycle_reset.sql`
  - Add atomic reset function + audit table + grants.
  - Add scheduler registration (cron/fallback strategy).
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
  - Add read endpoint/RPC for reset audit checkpoint if needed for explicit client reconciliation messaging.
- Existing reuse:
  - `lib/core/sync/payment_sync_conflict_resolver.dart` already terminalizes stale-cycle queue ops.
  - `lib/features/subscriptions/presentation/providers/sync_status_provider.dart` + `payment_reconciliation_provider.dart` can surface non-blocking correction feedback.

## Risks and Mitigations

| Risk | Impact | Mitigation | Req |
|---|---|---|---|
| Duplicate reminders from repeated triggers (`start/resume/mutations`) | User trust loss | Diff-based scheduler + stable key `(subscriptionId, cycleDueDate)` + cancel stale IDs each run | BILL-01, BILL-02 |
| Timezone/DST drift schedules wrong T-24h | Late/early reminder | Store timezone in registry and force full re-schedule when timezone changes | BILL-01, BILL-02 |
| Notification permission denied | Silent failure | Non-blocking Settings/Home banner + CTA to enable permissions; keep scheduler state explicit | BILL-01 |
| Backend reset partial updates | Inconsistent cycle state | Single SQL transaction for subscription/member updates + audit insertion | BILL-03 |
| Backend scheduler unavailable (`pg_cron`) | Missed resets | Fallback invoker (Edge/CI scheduler) calling same RPC | BILL-03 |
| Offline stale local state after backend reset | Wrong pending totals until refresh | Reuse existing canonical sync + reconciliation snackbars; invalidate debt/subscription providers on signal | BILL-03 |

## Testing Strategy

### Unit Tests

- `test/features/billing_automation/domain/billing_reminder_scheduler_test.dart`
  - T-24h computation for monthly/yearly cycles, month overflow, past-due filtering.
- `test/features/billing_automation/data/billing_reminder_registry_test.dart`
  - Idempotent diff behavior: create/keep/cancel with no duplicates.
- `test/features/billing_automation/domain/billing_automation_orchestrator_test.dart`
  - `app_start`, `app_resume`, timezone change, permissions disabled.

### Provider/Widget Tests

- `test/features/settings/presentation/providers/settings_provider_test.dart`
  - Reminder toggle triggers orchestrator behavior.
- `test/features/home/presentation/widgets/home_header_*` (extend)
  - Automation status signal shown non-blocking when permissions denied / schedule degraded.

### Sync + Reconciliation Tests

- Extend existing sync suites:
  - `test/core/sync/payment_sync_orchestrator_test.dart`
  - `test/core/sync/conflict_resolution_test.dart`
- Add cycle-reset case: queued op from old cycle becomes `cycle_conflict_noop` and UI receives reconciliation signal.

### SQL Contract Tests (via migration assertions)

- Add test migration checks for:
  - reset function exists + executable by `authenticated`/service role as designed.
  - reset updates `subscriptions` and `subscription_members` atomically.
  - audit rows inserted for each reset batch.

### Requirement Traceability Guard

- Add `test/features/subscriptions/phase5_requirements_traceability_test.dart` mirroring Phase 4 pattern for `BILL-01/02/03` evidence files.

## Validation Architecture

### Validation Layers

1. **Pre-merge static validation**
- Requirement traceability test must pass for `BILL-01/02/03`.
- New scheduler/reconciliation tests must pass in CI.

2. **Deterministic runtime invariants**
- At most one scheduled reminder per `(subscriptionId, cycleDueDate)` in registry.
- Scheduled reminder timestamp equals `dueDate - 24h` in device local timezone.
- After reset, member rows in new cycle always `has_paid=false`.

3. **Operational health checks**
- Settings sync/automation section exposes:
  - last automation run,
  - scheduled reminder count,
  - permission status,
  - last backend reset checkpoint (if exposed).

4. **UAT acceptance script**
- `BILL-01`: create active monthly + yearly subscriptions and verify one local T-24h notification each.
- `BILL-02`: reopen app and simulate device migration (fresh install + sync) then verify no critical duplicate reminders.
- `BILL-03`: force backend cycle reset window, reopen app, verify pending states and debt totals reconcile with non-blocking feedback.

## Recommended Planning Slices

1. **Slice 1 (BILL-01):** local scheduler + registry + notification permission UX + tap deep-link.
2. **Slice 2 (BILL-02):** orchestration triggers (`app_start/resume`, settings toggle, subscription mutations) + dedupe/timezone handling.
3. **Slice 3 (BILL-03):** backend reset migration + scheduler + client reconciliation signal wiring.
4. **Slice 4:** end-to-end verification + traceability closure.
