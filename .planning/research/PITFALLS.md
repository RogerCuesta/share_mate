# PITFALLS - MVP R1 (Brownfield)

## Priority Scale
- `P0`: release-blocking risk for trust, data integrity, or security.
- `P1`: high risk to reliability, usability, or maintainability in MVP use.
- `P2`: medium risk that can degrade quality if ignored.

## Phase Map for R1 Finish
- `Phase 1 - Data Safety Baseline`: startup migration gating + local persistence integrity.
- `Phase 2 - Security Hardening`: local encryption, auth/account safety, route protection.
- `Phase 3 - Sync Reliability`: offline queue execution, conflict handling, error surfacing.
- `Phase 4 - Core R1 Flows`: templates, shadow contacts, split, payment status, Home debt summary.
- `Phase 5 - Billing Automation`: T-24h reminders + monthly reset cron consistency.
- `Phase 6 - Quality Gates`: UI consistency, observability, and regression coverage.

### 1) [P0] Startup migration wipes cached subscriptions on every launch
- Warning signs: users briefly see empty Home/subscriptions after reopening app; local boxes lose rows across cold starts; support reports "data disappeared until refresh".
- Prevention strategy: gate migration by schema version, persist migration state, add one-time migration tests for upgrade and rollback paths.
- Target phase: `Phase 1 - Data Safety Baseline`.

### 2) [P0] Subscription/payment Hive boxes remain unencrypted
- Warning signs: sensitive payer/member/payment fields readable directly from local device backup or file system; security review flags plaintext financial metadata.
- Prevention strategy: enable encrypted Hive boxes for all subscription/payment stores, define migration path from plaintext, verify read/write compatibility with existing users.
- Target phase: `Phase 2 - Security Hardening`.

### 3) [P0] Offline payment queue has enqueue path but no reliable worker
- Warning signs: payment toggles appear successful locally but remote never catches up; queue size grows indefinitely; cross-device state drifts for same account.
- Prevention strategy: implement queue runner on app foreground/background hooks, retries with backoff and max-attempt dead-lettering, and explicit sync status in UI.
- Target phase: `Phase 3 - Sync Reliability`.

### 4) [P0] Monthly reset cron can conflict with local optimistic updates
- Warning signs: paid->pending status flips unexpectedly around cycle boundaries; duplicate reset actions; debt totals oscillate after sync.
- Prevention strategy: define single source of truth for cycle transitions, idempotent reset operation keyed by cycle ID, and conflict resolution precedence rules.
- Target phase: `Phase 5 - Billing Automation`.

### 5) [P1] Client-side account deletion depends on admin capability
- Warning signs: deletion fails in production with anon credentials; risky pressure to expose privileged key; inconsistent deletion outcomes across environments.
- Prevention strategy: move deletion to secured backend/Edge Function with re-auth + audit log + cascade behavior tests.
- Target phase: `Phase 2 - Security Hardening`.

### 6) [P1] Email verification state is inconsistent between layers
- Warning signs: protected actions unlock for unverified users or block verified users; settings screen shows contradictory status.
- Prevention strategy: make Supabase auth state authoritative, remove hardcoded placeholders, add contract tests for verification-dependent flows.
- Target phase: `Phase 2 - Security Hardening`.

### 7) [P1] Silent-failure patterns hide production defects
- Warning signs: empty lists/stats with no actionable error; logs show exceptions but UI looks like "no data"; high support ambiguity.
- Prevention strategy: propagate typed failures to presentation layer, render explicit offline/error states, and capture telemetry per failure class.
- Target phase: `Phase 3 - Sync Reliability`.

### 8) [P1] Route guard is partial and may expose private screens
- Warning signs: deep links can reach authenticated paths while signed out; auth exceptions happen late in providers instead of routing layer.
- Prevention strategy: centralize route policy with explicit public allowlist, deny-by-default for private paths, test unauthenticated deep-link matrix.
- Target phase: `Phase 2 - Security Hardening`.

### 9) [P1] N+1 remote fetches will degrade Home and subscription detail latency
- Warning signs: dashboard load time increases with subscription count; repeated per-item queries in traces; higher Supabase read volume than expected.
- Prevention strategy: replace loops with joined query/RPC endpoints, add pagination boundaries, and define performance budget assertions.
- Target phase: `Phase 4 - Core R1 Flows`.

### 10) [P1] Service template dependency can break "quick add" onboarding
- Warning signs: create-subscription form stalls when `service_templates` unavailable; users abandon setup after first attempt.
- Prevention strategy: cache template catalog locally, provide offline fallback/manual entry, version templates and guard schema changes.
- Target phase: `Phase 4 - Core R1 Flows`.

### 11) [P1] Shadow-contact identity collisions create duplicate debt actors
- Warning signs: same person appears multiple times with slight name variants; debt summary splits across duplicates; edit flow cannot reconcile members.
- Prevention strategy: add deterministic local contact identity rules (normalized name/phone/email heuristics), merge UX, and duplicate detection at creation.
- Target phase: `Phase 4 - Core R1 Flows`.

### 12) [P1] Split-even math and rounding can desync totals vs member debts
- Warning signs: sum(member shares) != subscription total; one-cent drift accumulates across months; Home debt differs from subscription detail.
- Prevention strategy: implement deterministic rounding policy (largest-remainder or fixed assignment rule), persist computed shares, and add invariant tests.
- Target phase: `Phase 4 - Core R1 Flows`.

### 13) [P1] Partial success in group-member creation treated as full success
- Warning signs: toast says success but some members missing; debt summary undercounts expected payers; later edits fail due to incomplete links.
- Prevention strategy: return partial-success result type, block "success" state when member failures exist, add compensation/retry flow.
- Target phase: `Phase 4 - Core R1 Flows`.

### 14) [P2] T-24h notification scheduler can drift with timezone/DST changes
- Warning signs: reminders fire at wrong local hour after DST switch or travel; missed alerts around month-end.
- Prevention strategy: store scheduling in local timezone-aware format, reschedule on timezone/DST change events, include alarm reconciliation job.
- Target phase: `Phase 5 - Billing Automation`.

### 15) [P2] Design-system drift causes inconsistent MVP UX and slower delivery
- Warning signs: ad-hoc widget styles per screen; inconsistent spacing/typography/actions between Home, create flow, and detail pages.
- Prevention strategy: enforce tokenized theme/components, create screen-level UI checklist from `ui-ux-pro-max`, and block merges on visual inconsistency.
- Target phase: `Phase 6 - Quality Gates`.

### 16) [P2] Test coverage gaps around migration/sync/reset allow regressions
- Warning signs: fixes in startup, queue, or monthly reset repeatedly break in later PRs; production incidents not reproduced by CI.
- Prevention strategy: add integration tests for startup migration, queue drain/retry, cycle reset idempotency, and debt-summary consistency assertions.
- Target phase: `Phase 6 - Quality Gates`.

## Recommended Execution Order
1. Close all `P0` pitfalls before shipping any new R1 user-visible feature.
2. Complete `P1` pitfalls in Phases 2-4 in parallel streams (security, sync, core flow).
3. Use `P2` pitfalls as release hardening gates before MVP R1 sign-off.
