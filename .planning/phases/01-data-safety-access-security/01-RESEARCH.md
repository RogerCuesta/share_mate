# Phase 1 Research: Data Safety & Access Security

**Phase:** 01-data-safety-access-security  
**Date:** 2026-03-08  
**Status:** Ready for planning  
**Primary requirements:** SAFE-01, SAFE-02, SECU-01, SECU-02, SECU-03

## Inputs Reviewed

- `.planning/phases/01-data-safety-access-security/01-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `lib/main.dart`
- `lib/core/storage/hive_service.dart`
- `lib/features/settings/data/datasources/account_remote_datasource.dart`
- `lib/core/supabase/supabase_service.dart`
- Supporting evidence used to validate gaps:
- `lib/core/sync/payment_sync_queue.dart`
- `lib/features/subscriptions/data/datasources/subscription_local_datasource.dart`
- `supabase/migrations/20251225_payment_history_enhancements.sql`
- `supabase/migrations/20260108_contacts_refactor.sql`
- `docs/SUPABASE_SCHEMA.sql`

## 1) Current State and Gaps vs Requirements

### SAFE-01: No destructive deletion of existing local subscriptions/contacts on startup or migration

**Current state**
- `main.dart` calls `_migrateSubscriptionBoxes()` on every startup.
- `_migrateSubscriptionBoxes()` unconditionally deletes:
- `subscriptions` box.
- `subscription_members` box.
- Contacts are not deleted by this function.

**Gap**
- Requirement is violated for subscriptions and members.
- Startup behavior is destructive by design.
- No data-preserving fallback exists if migration fails.

**Conclusion**
- `SAFE-01` is currently **not met**.

### SAFE-02: Local migrations are idempotent, versioned, and run once per version

**Current state**
- No migration registry or `schema_version` state exists in current bootstrap path.
- Migration logic is hardcoded in `main.dart` and not version-gated.
- Same destructive logic executes every app launch.

**Gap**
- Not idempotent.
- Not versioned.
- Not “once per version”.

**Conclusion**
- `SAFE-02` is currently **not met**.

### SECU-01: Local subscriptions/payments/contacts data encrypted at rest

**Current state**
- `HiveService` supports AES encryption and key management via `FlutterSecureStorage`.
- Contacts local datasource already opens boxes with `encrypted: true`.
- Auth/settings/profile local datasources also use encrypted boxes.
- Subscription, member, payment history boxes in `main.dart` are opened without `encrypted: true`.
- Payment sync queue uses direct `Hive.openBox` without encryption in `payment_sync_queue.dart`.

**Gap**
- Critical R1 business data is partially in plaintext at rest.
- Encryption capability exists but is not consistently applied to all sensitive boxes.

**Conclusion**
- `SECU-01` is currently **partially met** (contacts/settings/auth encrypted; subscriptions/payments/sync queue not fully encrypted).

### SECU-02: Sensitive account operations run via authorized backend, not client admin API

**Current state**
- `AccountRemoteDataSourceImpl.deleteAccount(String userId)` calls `client.auth.admin.deleteUser(userId)` from client code.

**Gap**
- Admin operation is exposed in untrusted client path.
- Violates backend-only sensitive operation boundary.

**Conclusion**
- `SECU-02` is currently **not met**.

### SECU-03: Supabase RLS guarantees per-user isolation on business data

**Current state**
- Contacts migration (`20260108_contacts_refactor.sql`) includes RLS enable + CRUD policies tied to `auth.uid()`.
- Project includes documented SQL with RLS policies for subscriptions/members in `docs/SUPABASE_SCHEMA.sql`.
- Active migration set under `supabase/migrations/` does not clearly include base subscriptions/members creation + RLS policy migration in a canonical, replayable form.
- `20251225_payment_history_enhancements.sql` introduces `SECURITY DEFINER` functions and grants execute; ownership checks are not explicit inside each function body.

**Gap**
- RLS posture for all business tables is not validated from migration source-of-truth alone.
- `SECURITY DEFINER` RPCs can bypass expected row-level restrictions if authorization checks are incomplete.
- No explicit verification gate in phase workflow currently proves full isolation.

**Conclusion**
- `SECU-03` is **at risk / unproven** and must be hardened + validated as part of Phase 1.

## 2) Recommended Implementation Strategy

### A. Implement a Versioned Migration Runner (replace destructive startup migration)

**Goal**
- Replace `_migrateSubscriptionBoxes()` with deterministic, non-destructive, idempotent migrations.

**Design**
- Add migration state store (`migration_meta` Hive box) with:
- `storage_schema_version` (int).
- `last_successful_migration` (int).
- `in_progress` + `failed_migration` + `error_code`.
- `checksum/row_count` metadata for verification.
- Define `LocalMigration` contract:
- `int version`
- `String name`
- `Future<MigrationResult> up(MigrationContext ctx)`
- Build `LocalMigrationRunner`:
- Reads current version.
- Executes pending migrations sequentially.
- Persists step-level state before and after each migration.
- Fails safe (no destructive cleanup on failure).
- Add startup gate:
- If migration fails, app enters controlled safe mode for affected write paths.
- Show user-facing recovery path, no silent destructive fallback.

**Idempotency rule**
- Every migration must be re-runnable with no data loss and no duplicate records.
- Migrations must check existence/state before mutating.

### B. Encryption Migration for Sensitive Local Boxes

**Target boxes**
- `subscriptions`
- `subscription_members`
- `payment_history`
- `payment_sync_queue`
- `contacts`
- `my_contacts_cache` (already encrypted but include verification marker)

**Approach**
- Use migration step `v1 -> v2` (example naming) to encrypt legacy plaintext boxes.
- Per box algorithm:
- Open source data safely.
- Write snapshot to temporary backup box (`<name>__backup_v2`) for rollback.
- Recreate original box encrypted using `HiveService.openBox(..., encrypted: true)`.
- Copy data with deterministic key mapping.
- Validate: row count + deterministic checksum/hash.
- Mark box migration as complete in metadata.
- Keep backup until full migration success; cleanup in separate post-success migration step.

**Failure behavior**
- If encryption key retrieval/generation fails:
- Block writes to migrated domains.
- Preserve source + backup.
- Emit error telemetry without sensitive payloads.
- If copy/validate fails:
- Restore from backup.
- Mark migration failed and stop further writes for impacted box.

**Code-level implications**
- `main.dart`: remove destructive migration call, invoke migration runner before opening app data sources.
- `main.dart`: open subscription/payment boxes with `encrypted: true`.
- `payment_sync_queue.dart`: replace direct `Hive.openBox` with `HiveService.openBox(..., encrypted: true)`.

### C. Sensitive Account Operations via Backend (SECU-02)

**Recommended boundary**
- Client must never call admin APIs directly.
- Implement backend endpoint for account deletion:
- Preferred: Supabase Edge Function `delete-account`.
- Authenticated with user JWT.
- Function derives target user from JWT (`auth.uid()`), not client-provided `userId`.
- Performs delete via service role/admin context server-side.

**Client changes**
- `AccountRemoteDataSource.deleteAccount()` should call backend function/RPC.
- Remove any `auth.admin.*` usage from client layer.
- Keep function contract as “delete current authenticated account”.

**Hardening**
- Add rate limiting / abuse guard.
- Add structured audit event:
- `actor_user_id`
- `event_type=account_delete_requested|completed|failed`
- timestamp and correlation ID

### D. RLS Hardening and Proof (SECU-03)

**Migration source of truth**
- Ensure canonical migrations include:
- table creation (if missing in migration chain),
- `ENABLE ROW LEVEL SECURITY`,
- per-table CRUD policies for subscriptions, members, payment_history, contacts.

**Function safety**
- Review all `SECURITY DEFINER` functions.
- Add explicit authorization predicates inside function body where needed.
- Set fixed `search_path` in function definitions to reduce privilege abuse risk.

**Verification-first policy**
- Add repeatable SQL checks in CI/local scripts:
- RLS enabled on required tables.
- Required policies exist.
- Cross-user read/write attempts fail.

## 3) Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Corrupt or missing encryption key | Data unreadable after migration | Preflight key check, explicit error state, no destructive cleanup, recovery UX |
| Partial migration commit | Data inconsistency | Step-level checkpointing + snapshot + post-copy validation before commit |
| Memory pressure while copying large boxes | Startup crash or ANR | Chunked copy batches, streaming iteration, progress checkpoint |
| Re-running migration duplicates records | Logical corruption | Idempotent key-based upserts and completion markers per box |
| Backend delete endpoint abused | Unauthorized deletes | JWT-based identity, ignore client userId, server-side auth checks + rate limit |
| SECURITY DEFINER bypass of RLS assumptions | Cross-tenant exposure | Explicit `auth.uid()` checks in function body + restricted grants |
| Missing RLS policy in one table | Tenant isolation break | Automated policy audit query in CI and release checklist |
| Verbose logs leak sensitive data | Privacy incident | Redacted logging policy, no payload/value dumps for PII/payment data |

## 4) Validation Architecture (Required)

### Validation Layers

**Layer 1: Startup Invariants**
- Verify migration metadata is readable.
- Verify secure key availability before opening sensitive encrypted boxes.
- Fail closed for writes if invariants fail.

**Layer 2: Migration Correctness**
- For each migrated box:
- Pre/post record count equality.
- Deterministic checksum equality.
- Retry-safe re-execution check (no additional mutation on second run).

**Layer 3: Local Security Controls**
- Assert sensitive boxes are opened only with encryption in runtime paths.
- Static rule/check: no direct `Hive.openBox` for sensitive box names.

**Layer 4: Backend Boundary Enforcement**
- Contract test: client account deletion path uses backend function only.
- Negative test: direct admin path unavailable in client code.

**Layer 5: Data Isolation / RLS**
- Integration tests with two users:
- user A cannot read/update/delete user B business rows.
- `SECURITY DEFINER` functions reject unauthorized target rows.

### Validation Artifacts

- `migration_audit.log` with version transitions and outcomes.
- SQL policy audit output snapshot for required tables.
- Automated test report mapping pass/fail to `SAFE-*` and `SECU-*`.
- Release gate checklist that blocks ship on any failed requirement mapping.

## 5) Test Strategy and Acceptance Checks Mapped to Requirement IDs

### SAFE-01 Acceptance Checks

- Unit:
- Migration runner does not call delete-all behavior for existing boxes.
- Existing subscription/member/payment rows survive startup.
- Integration:
- Seed local subscription data, restart app, assert data unchanged.
- Failure path:
- Simulate migration exception, verify no data deletion and safe-mode behavior.

### SAFE-02 Acceptance Checks

- Unit:
- Migration version comparison logic runs only pending versions.
- Completed migration is skipped on next startup.
- Integration:
- First startup applies migration once.
- Second startup applies zero additional mutations.
- Regression:
- Re-running same migration yields identical checksums.

### SECU-01 Acceptance Checks

- Unit:
- Sensitive box open calls include `encrypted: true`.
- Key retrieval errors trigger safe failure state, not plaintext fallback.
- Integration:
- Legacy plaintext dataset migrates to encrypted boxes with row parity.
- Payment sync queue data persists encrypted path.
- Static scan:
- No direct `Hive.openBox` for sensitive boxes.

### SECU-02 Acceptance Checks

- Unit:
- `AccountRemoteDataSource.deleteAccount` calls backend endpoint abstraction.
- Integration:
- Authenticated user can delete own account through backend endpoint.
- Negative:
- Request with forged target user ID is ignored/rejected.
- Static scan:
- No `auth.admin.deleteUser` usage remains in Flutter client code.

### SECU-03 Acceptance Checks

- SQL/integration:
- RLS enabled on `subscriptions`, `subscription_members`, `payment_history`, `contacts` (and other business tables in scope).
- Policies exist for SELECT/INSERT/UPDATE/DELETE with ownership constraints.
- Cross-user isolation tests fail as expected for unauthorized access.
- Function tests:
- `SECURITY DEFINER` routines enforce caller ownership and reject cross-tenant access.

## Requirement-to-Test Matrix

| Requirement | Automated Tests | Manual/UAT | Release Gate |
|---|---|---|---|
| SAFE-01 | Startup preservation + failure safety tests | Restart app with existing data | Block on any data loss |
| SAFE-02 | Version/idempotency test suite | Reopen app twice, verify unchanged | Block on repeated mutation |
| SECU-01 | Encryption + migration + static scan | Inspect behavior on key failure | Block if any sensitive plaintext path |
| SECU-02 | Backend delete path + negative auth tests | Delete account from settings flow | Block if client admin API remains |
| SECU-03 | RLS policy audit + cross-user tests | Spot-check with 2 test users | Block if any isolation break |

## 6) Suggested Execution Order for Plan Tasks

1. Create migration architecture primitives (`LocalMigration`, `LocalMigrationRunner`, metadata store).
2. Remove destructive startup migration and wire runner into bootstrap.
3. Implement migration `v1`: non-destructive baseline/state initialization.
4. Implement migration `v2`: encryption migration for subscription/member/payment boxes.
5. Encrypt payment sync queue storage path and align with `HiveService`.
6. Add migration failure safe-mode handling and recovery UX hooks.
7. Refactor account deletion to backend function/RPC boundary.
8. Remove client admin delete API usage and add static guard.
9. Consolidate/author Supabase SQL migrations for business-table RLS guarantees.
10. Harden `SECURITY DEFINER` functions with explicit auth checks and fixed search path.
11. Add automated validation suite (local migration tests + backend boundary + RLS isolation).
12. Add requirement-mapped release checklist and CI gate.

## Planning Notes and Constraints

- Keep Phase 1 scope on safety/security foundations only; do not mix with feature expansion.
- Prioritize recoverability over startup speed for migration operations.
- Treat migration telemetry as sensitive: never log payload values, only metadata.
- Prefer additive migrations and explicit rollback snapshots over destructive resets.

## Definition of Ready for `01-PLAN.md`

- Gap analysis agreed for SAFE-01/02 and SECU-01/02/03.
- Migration runner strategy accepted.
- Encryption migration algorithm accepted.
- Backend-only sensitive account operation boundary accepted.
- Validation architecture accepted with release gating criteria.
- Execution order accepted and decomposable into implementation tasks.

