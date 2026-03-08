# MVP R1 Integration Architecture Research

## Scope and Intent
This document proposes an implementation-oriented architecture for integrating MVP R1 into the current Flutter Clean Architecture stack.
Inputs used: `.planning/PROJECT.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`.
Target capabilities: service catalog, contact-backed split setup, payment status pipeline, debt-focused home dashboard, and T-24h reminders.

## 1) Proposed Component Boundaries

### A. Keep existing layer boundaries per feature
- `presentation`: screens/widgets/providers only orchestrate UI state.
- `domain`: entities/use cases/repository contracts only.
- `data`: repository implementations + local/remote datasources.
- `core/*`: cross-cutting services (storage, sync, DI, notifications, migrations).

### B. New or expanded bounded components
- `lib/features/catalog/*` (new, read-only):
  - Owns `service_templates` retrieval/caching.
  - Exposes `GetServiceTemplates` use case for create-subscription flows.
  - No write operations from mobile app.
- `lib/features/contacts/*` (existing, expanded usage):
  - Remains source of truth for local "shadow users" (name/email/avatar/notes).
  - Adds selection adapters for subscription member draft creation.
- `lib/features/subscriptions/*` (existing, expanded domain):
  - Owns split calculation, member state transitions, payment status changes.
  - Owns payment history creation and local-remote consistency rules.
- `lib/features/home/*` (existing, refocused read model):
  - Uses an aggregated `DebtDashboard` read model from subscription domain data.
  - Must not implement business math in widgets.
- `lib/features/reminders/*` (new orchestration feature):
  - Owns reminder scheduling intent, next-run calculation, and re-scheduling policy.
  - Delegates OS scheduling to `core/notifications` implementation.
- `lib/core/migrations/*` (new utility package):
  - Versioned one-time migration runner to replace unconditional box deletion.
- `lib/core/sync/*` (existing, expanded):
  - Add queue worker lifecycle (startup + foreground resume + retry/backoff).

### C. Contract boundaries (important)
- `SubscriptionRepository` stays the write boundary for payment/split/member changes.
- `CatalogRepository` is read-only and cannot depend on presentation.
- `ReminderRepository` is schedule-state boundary; it does not compute financial data.
- `Home` reads via use cases/providers only; no direct datasource access.

## 2) Data Flow by Capability

### A. Catalog flow (`service_templates`)
1. `CreateSubscription` provider requests templates through `GetServiceTemplates`.
2. `CatalogRepositoryImpl` reads local cache first for instant paint.
3. Repository refreshes from Supabase `service_templates` (ordered by popularity/name).
4. Remote response updates cache with `updated_at` watermark.
5. Provider emits `CatalogItem` list; selected template hydrates form defaults (name/icon/color/typical amount).

### B. Split flow (equal split with contacts/shadow users)
1. User picks contacts in create-group screen.
2. Contacts are mapped to `SubscriptionMemberInput` drafts (stable email key + local contact reference).
3. `CalculateEqualSplit` domain service computes deterministic cents distribution:
4. Members get floor amount; remainder assigned to owner by explicit rule.
5. `CreateSubscription` persists subscription first, then member rows with due date + amount.
6. Repository writes local cache atomically, then remote; rollback/compensation path for partial failures.

### C. Payment status flow (paid/pending lifecycle)
1. UI toggle triggers `MarkPaymentAsPaid` or `UnmarkPayment` use case.
2. Repository performs optimistic local update on member + stats.
3. Operation is queued into `PaymentSyncQueueService` before remote call.
4. Remote datasource executes atomic RPC (`mark_payment_as_paid_atomic` / `unmark_payment_atomic`).
5. On success: queue item removed, payment history persisted, affected providers invalidated.
6. On failure: queue kept with retry metadata; UI shows sync-pending indicator, not silent success.

### D. Debt dashboard flow (Home)
1. `DebtDashboardProvider` composes:
   - `GetMonthlyStats(userId)`
   - `GetPendingPayments(userId)`
   - next due subscription query
2. Domain mapper returns `DebtDashboard`:
   - `totalDebtToCollect`
   - `pendingMembersCount`
   - `overdueMembersCount`
   - `nextCollectionDate`
3. Home widgets render this read model only.
4. After payment mutations, provider invalidation refreshes dashboard immediately.

### E. Reminder flow (T-24h + cycle reset)
1. On subscription create/update, `ScheduleSubscriptionReminders` recalculates next reminder (`dueDate - 24h`).
2. Settings change (`paymentRemindersEnabled`) triggers reschedule/cancel all.
3. Reminder intents stored locally (Hive encrypted box) for recovery after app restart.
4. OS notifications scheduled via local notification adapter.
5. Supabase monthly reset job sets new cycle payment state to pending.
6. On app foreground sync, reset deltas are pulled and reminders are recalculated.

## 3) Build Order with Dependencies

1. **Foundation hardening (blocker)**
- Implement versioned migration runner in `core/migrations`.
- Encrypt subscription/payment/reminder Hive boxes.
- Dependency: none. Required before feature rollout.

2. **Sync worker lifecycle (blocker)**
- Add queue processor for `payment_sync_queue` with retry/backoff/dead-letter threshold.
- Trigger on app startup and connectivity/foreground resume.
- Dependency: Step 1 (safe storage + migration).

3. **Catalog feature slice**
- Add `catalog` domain/data/presentation provider set.
- Add Supabase table migration for `service_templates` if absent.
- Dependency: Step 1.

4. **Contacts-to-members integration**
- Wire create-group flow to select existing contacts and create member drafts.
- Add contact quick-create in modal for missing person.
- Dependency: Step 3 optional; can run with static fallback list.

5. **Split engine extraction**
- Move split arithmetic into dedicated domain service/use case with unit tests.
- Replace duplicated math in form providers/detail provider.
- Dependency: Step 4.

6. **Payment status consistency pass**
- Route all paid/unpaid mutations through queued + atomic path.
- Add explicit sync state surfacing in UI/provider state.
- Dependency: Steps 2 and 5.

7. **Debt dashboard read model**
- Add `DebtDashboard` aggregator use case and provider.
- Refactor home widgets to consume single read model.
- Dependency: Step 6.

8. **Reminder subsystem + monthly reset integration**
- Introduce reminders feature and local scheduler adapter.
- Add Supabase reset function/cron and sync hook for post-reset refresh.
- Dependency: Steps 2 and 7.

9. **Stabilization gates**
- Integration tests for migration safety, queue drain, payment-toggle consistency, reminder scheduling.
- Dependency: all previous steps.

## 4) Risk Containment Strategy (P0/P1)

### P0: Startup migration wipes subscription data
- Containment:
  - Replace unconditional `_migrateSubscriptionBoxes()` with version-gated migrations.
  - Persist `last_migrated_schema_version` in secure settings box.
  - Add migration smoke test that runs app restart twice and asserts no second wipe.
- Release gate: block feature launch until idempotency test passes.

### P0: Plaintext Hive storage for subscription/payment data
- Containment:
  - Open subscription/member/payment/reminder boxes with `encrypted: true`.
  - Add one-time re-encryption migration path old-box -> encrypted-box.
  - Fail closed: if re-encryption fails, keep read-only mode and show recovery prompt.
- Release gate: verify encrypted box headers in integration test.

### P1: Offline sync queue has no worker
- Containment:
  - Implement queue runner with max retry, exponential backoff, and dead-letter logging.
  - Add observable `syncHealth` provider for UI and debugging.
- Release gate: offline payment toggle test proves eventual remote consistency.

### P1: Unsalted SHA-256 local credential hashing
- Containment:
  - Move to Argon2id (or PBKDF2 if platform constraints), per-user salt, hash versioning.
  - Lazy migration on login to avoid forced logout.
- Release gate: forbid new unsalted hashes via unit tests.

### P1: Account deletion using admin API from client
- Containment:
  - Replace direct admin call with Supabase Edge Function using re-auth token.
  - Client calls edge endpoint only; no admin capability in app binary.
- Release gate: security review of deletion path and env keys.

### P1: Email verification state inconsistency
- Containment:
  - Make verification source authoritative from Supabase auth user metadata.
  - Remove hardcoded placeholders and expose one normalized provider.
- Release gate: auth flow test for verified/unverified transitions.

## Practical Rollout Notes
- Deliver in thin vertical slices behind feature flags where possible.
- Prefer additive schema changes and backwards-compatible repository contracts.
- Keep provider invalidation explicit after any member/payment mutation to avoid stale debt dashboard state.
