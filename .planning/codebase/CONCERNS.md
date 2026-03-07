# CONCERNS

## Scope
- Focus: technical debt, known issues, fragility, security, and performance concerns.
- Prioritization: `P0` (critical), `P1` (high), `P2` (medium), `P3` (low).

## Prioritized Concerns

### P0 - Startup migration deletes local subscription data on every launch
- Impact: cached subscriptions/members are wiped each app start, undermining offline-first behavior and risking perceived data loss until refetch completes.
- Evidence:
  - `lib/main.dart:35`
  - `lib/main.dart:36`
  - `lib/main.dart:86`
  - `lib/main.dart:91`
  - `lib/main.dart:92`
- Why fragile: migration is unconditional and not version-gated.
- Recommended direction: gate migrations by schema/app version and run once; persist migration state.

### P0 - Sensitive subscription/payment data is persisted without Hive encryption
- Impact: PII and financial activity data are stored locally in plaintext Hive boxes.
- Evidence:
  - `lib/main.dart:45`
  - `lib/main.dart:48`
  - `lib/main.dart:51`
  - `lib/core/sync/payment_sync_queue.dart:83`
  - `lib/features/subscriptions/data/models/subscription_member_model.dart:74`
  - `lib/features/subscriptions/data/models/payment_history_model.dart:75`
  - `lib/features/subscriptions/data/models/payment_history_model.dart:88`
- Why fragile: auth/settings/contact caches use encryption, but subscription/payment boxes do not.
- Recommended direction: open all subscription/payment boxes with `encrypted: true` and add data migration strategy.

### P1 - Local credential hashing is unsalted SHA-256
- Impact: offline credential database is vulnerable to fast dictionary/rainbow-table cracking if local storage is compromised.
- Evidence:
  - `lib/features/auth/data/datasources/user_local_datasource.dart:39`
  - `lib/features/auth/data/datasources/user_local_datasource.dart:132`
  - `lib/features/auth/data/datasources/user_local_datasource.dart:134`
- Why fragile: no per-user salt and no adaptive KDF (Argon2/bcrypt/scrypt/PBKDF2).
- Recommended direction: migrate to Argon2id/bcrypt with per-user salt and versioned hash metadata.

### P1 - Account deletion path depends on Supabase Admin API from client code
- Impact: likely broken with anon credentials; catastrophic if service-role capability is ever shipped client-side.
- Evidence:
  - `lib/features/settings/data/datasources/account_remote_datasource.dart:68`
  - `lib/features/settings/data/datasources/account_remote_datasource.dart:64`
  - `lib/core/config/env_config.dart:88`
- Why fragile: `auth.admin.deleteUser` is an admin operation and should not be callable from an untrusted client.
- Recommended direction: move deletion to a server-side endpoint/Edge Function with re-auth and authorization checks.

### P1 - Email verification state is inconsistent and effectively bypassable
- Impact: features that rely on verification cannot be trusted; security/business rules may drift.
- Evidence:
  - `lib/features/auth/domain/entities/user.dart:45`
  - `lib/features/settings/presentation/providers/account_actions_provider.dart:145`
  - `lib/features/settings/presentation/providers/account_actions_provider.dart:148`
- Why fragile: one source always returns `true`, another hardcodes `false`.
- Recommended direction: make verification status authoritative from Supabase auth user state and remove placeholders.

### P1 - Offline payment sync queue has no processing worker
- Impact: queued operations can accumulate indefinitely, leaving local optimistic state diverged from remote truth.
- Evidence:
  - `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart:637`
  - `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart:651`
  - `lib/core/sync/payment_sync_queue.dart:101`
  - `lib/core/sync/payment_sync_queue.dart:113`
  - `lib/core/sync/payment_sync_queue.dart:125`
- Why fragile: enqueue exists, but there is no observed consumer/orchestrator invoking dequeue-sync lifecycle.
- Recommended direction: add background/foreground sync runner with retry/backoff, max retries, and dead-letter handling.

### P2 - Route guard does not protect all authenticated routes
- Impact: unauthenticated users can navigate to non-public screens (then fail deeper in providers/use-cases).
- Evidence:
  - `lib/routing/app_router.dart:63`
  - `lib/routing/app_router.dart:99`
  - `lib/routing/app_router.dart:104`
  - `lib/routing/app_router.dart:109`
- Why fragile: redirect only blocks `/app` and `/`; other private routes are not centrally guarded.
- Recommended direction: enforce allowlist for public routes and redirect all others when unauthenticated.

### P2 - Silent failure patterns hide production issues
- Impact: users see empty states instead of errors; monitoring and debugging become harder.
- Evidence:
  - `lib/features/contacts/presentation/providers/contacts_provider.dart:29`
  - `lib/features/contacts/presentation/providers/contacts_provider.dart:31`
  - `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart:1009`
  - `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart:1011`
- Why fragile: failures are converted to empty collections/default stats without surfacing diagnostics upstream.
- Recommended direction: return typed failures and render explicit degraded/offline/error states.

### P2 - N+1 query pattern and unbounded reads in subscriptions remote datasource
- Impact: latency and backend load increase with subscription count; scalability risk.
- Evidence:
  - `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart:149`
  - `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart:155`
  - `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart:249`
  - `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart:261`
- Why fragile: per-subscription member query loop plus broad `select()` patterns.
- Recommended direction: replace with joined/RPC endpoints and paginate large datasets.

### P3 - Group subscription creation reports success even with member-creation failures
- Impact: partially-created groups can be treated as fully successful in UI.
- Evidence:
  - `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart:425`
  - `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart:441`
  - `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart:458`
  - `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart:460`
- Why fragile: `isSuccess` is set even when `failCount > 0`.
- Recommended direction: treat partial failures explicitly, add rollback/compensation or post-create recovery flow.

### P3 - Verbose logs expose identifiers and contact data
- Impact: privacy risk in shared logs or crash-report pipelines.
- Evidence:
  - `lib/routing/app_router.dart:29`
  - `lib/features/subscriptions/presentation/widgets/add_member_dialog.dart:52`
  - `lib/features/subscriptions/presentation/widgets/add_member_dialog.dart:53`
  - `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart:429`
- Why fragile: logging includes email, user IDs, subscription IDs, and operational details without `kDebugMode` gates.
- Recommended direction: gate logs behind debug flags and redact PII.

### P3 - Critical-flow test coverage remains thin relative to risk surface
- Impact: regressions in auth/offline-sync/data-migration paths may ship undetected.
- Evidence:
  - `test/features/auth/data/repositories/auth_repository_impl_test.dart`
  - `integration_test/mark_payment_as_paid_test.dart`
  - `lib/main.dart:35`
  - `lib/core/sync/payment_sync_queue.dart:75`
- Why fragile: high-risk startup migration and queue lifecycle paths have little end-to-end coverage.
- Recommended direction: add integration tests for migration gating, sync queue drain/retry, and account deletion flow.
