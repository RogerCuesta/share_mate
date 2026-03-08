# Project Research Summary

**Project:** Share Mate  
**Domain:** Offline-first single-player shared-subscription debt tracking (Flutter mobile)  
**Researched:** 2026-03-08  
**Confidence:** HIGH

## Executive Summary

Share Mate is a focused debt-control product for one payer managing shared subscriptions without requiring collaborators to join the app. The research converges on a pragmatic brownfield strategy: keep the current Flutter + Riverpod + Supabase + Hive foundation, close reliability/security gaps first, then ship the R1 feature loop (catalog -> shadow contacts -> split -> payment toggle -> home debt refresh -> reminders/reset). Experts build this class of product by prioritizing deterministic financial state transitions and fast local UX over breadth features.

The recommended approach is to avoid platform or architecture rewrites and instead harden the existing stack with versioned migrations, encrypted local stores, and a real offline sync worker. Feature work should be delivered in thin vertical slices grouped by dependency: creation funnel foundations first, then payment consistency, then debt dashboard, then billing automation. Monthly reset must remain backend-authoritative (Supabase scheduled function) while the client reconciles and reflects state.

The biggest risks are data loss on startup migration, plaintext local financial metadata, sync drift from missing queue execution, and billing-cycle conflicts between optimistic updates and cron resets. Mitigation is clear: release-block on P0 fixes, enforce idempotent cycle semantics, expose sync health in UI/state, and gate sign-off with migration/sync/reset integration tests.

## Key Findings

### Recommended Stack

R1 should stay on the current codebase-aligned stack and add only minimal, high-leverage dependencies for reminders and permissions. The strongest recommendation is execution discipline rather than tech churn: pin toolchain with FVM, keep lockfile deterministic, use forward-only Supabase migrations, and avoid introducing parallel state-management/backend systems.

**Core technologies:**
- Flutter + Dart: existing app foundation and fastest path to R1 completion with low migration risk.
- Riverpod + `riverpod_annotation`: existing dependency injection/state orchestration with testable providers.
- Clean Architecture by feature (`data/domain/presentation`): preserves boundaries and keeps business logic out of UI.
- Supabase (`auth`, Postgres, RLS, RPC): backend source of truth for auth/data and atomic payment operations.
- Hive CE + `flutter_secure_storage`: offline-first local persistence with secure key material management.
- GoRouter: auth-aware routing and shell navigation already integrated.
- Freezed + build_runner: immutable models/codegen consistency for safer refactors.
- `flutter_local_notifications` + `timezone` + `permission_handler`: minimal required set for reliable T-24h reminders.

### Expected Features

R1 table stakes are the complete debt loop for the owner: quick service-based creation, contact-backed split setup, reliable paid/pending tracking, and immediate Home debt visibility with monthly cadence support.

**Must have (table stakes):**
- Service catalog (`service_templates`) integrated in create flow with local cache fallback.
- Shadow contacts creation/selection integrated into subscription setup.
- Equal split calculation with deterministic rounding behavior.
- Per-contact payment toggle (`pending`/`paid`) with optimistic UX and sync-safe persistence.
- Home debt dashboard with total outstanding debt and nearest upcoming charge.
- T-24h local reminders per subscription plus monthly pending reset across cycles.
- Offline-first operation across CRUD/toggles with robust convergence after reconnect.
- Strong user isolation via RLS on all relevant reads/writes.

**Should have (competitive):**
- No-invite operating model as core differentiation.
- Two-tap settle-up ritual (notification -> mark paid -> immediate Home refresh).
- Catalog-first onboarding to reduce first-subscription friction.
- Debt-first Home prioritizing action speed over analytics depth.

**Defer (v2+):**
- Multi-user collaboration/invitations.
- Integrated payment rails (Bizum/Stripe/etc.).
- Monetization/paywall mechanics.
- Open banking/reconciliation and multi-currency support.
- Advanced long-horizon analytics and debtor web companion.

### Architecture Approach

The architecture recommendation is additive: keep current boundaries, introduce `catalog` and `reminders` slices, and harden `core/migrations` + `core/sync`. Data flow should remain repository/use-case centered with explicit optimistic-write + queue + atomic-RPC completion for payment state. Home must consume an aggregated `DebtDashboard` read model, not compute debt math in widgets.

**Major components:**
1. `features/catalog`: read-only service template retrieval/caching for creation UX.
2. `features/contacts` + `features/subscriptions`: contact-to-member mapping, split engine, payment lifecycle.
3. `features/home`: aggregated debt dashboard read model and refresh orchestration.
4. `features/reminders` + `core/notifications`: schedule intent, recovery, and local OS notification execution.
5. `core/migrations` + `core/sync`: versioned data safety and resilient offline queue processing.

### Critical Pitfalls

1. **Startup migration wipes cached subscriptions** — replace unconditional migration with schema-version gating and idempotency tests.
2. **Unencrypted local subscription/payment data** — encrypt Hive boxes, migrate plaintext data once, and fail closed on migration issues.
3. **Offline queue without reliable worker** — implement lifecycle-triggered queue runner with backoff/dead-letter and visible sync state.
4. **Cron reset conflicts with local optimistic updates** — enforce idempotent cycle reset keyed by billing cycle and clear precedence rules.
5. **Silent failures hide real defects** — propagate typed failures to UI states and collect telemetry by failure class.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Safety Baseline
**Rationale:** P0 data-loss risk blocks trustworthy feature delivery.  
**Delivers:** Versioned migration runner, startup idempotency guarantees, safe local persistence foundation.  
**Addresses:** Table-stake offline reliability prerequisites.  
**Avoids:** Startup wipe pitfall and regression loops in later phases.

### Phase 2: Security Hardening
**Rationale:** Privacy/security defects are release-critical and must be solved before broader rollout.  
**Delivers:** Encrypted Hive financial stores, account-deletion backend path, authoritative verification state, stronger route protection.  
**Uses:** Existing Supabase + secure storage stack; no backend platform switch.  
**Implements:** `core` security boundaries and auth policy enforcement.  
**Avoids:** Plaintext data exposure and privileged-client deletion risk.

### Phase 3: Sync Reliability Core
**Rationale:** Payment trust depends on eventual consistency; enqueue-only behavior is unacceptable.  
**Delivers:** Queue worker lifecycle, retry/backoff/dead-letter strategy, sync health surfacing, conflict handling rules.  
**Addresses:** Payment toggle correctness and offline-first convergence requirements.  
**Avoids:** Local/remote drift and silent stale debt summaries.

### Phase 4: Core R1 User Flows
**Rationale:** With safety/security/sync foundations in place, user-facing R1 loop can ship reliably.  
**Delivers:** Service catalog + shadow contacts + split engine + payment status pipeline + debt dashboard read model.  
**Addresses:** Main table stakes (RF1-RF5) and differentiation (no-invite + debt-first action flow).  
**Avoids:** N+1 latency, identity collisions, rounding desync, and partial-success data corruption.

### Phase 5: Billing Automation
**Rationale:** Reminder value is only credible after core debt state is reliable.  
**Delivers:** T-24h scheduling, reminder rehydration/reconciliation, backend monthly reset integration with cycle-id idempotency.  
**Addresses:** RF6 plus monthly cadence behavior.  
**Avoids:** DST/timezone drift and reset race conditions.

### Phase 6: Quality Gates & UX Consistency
**Rationale:** Final release quality requires consistency + observability + regression protection.  
**Delivers:** UI consistency pass, integration/e2e coverage for migration/sync/reset/debt invariants, release hardening checks.  
**Addresses:** RNF quality expectations and retention-critical UX polish.  
**Avoids:** Late regressions and design-system drift.

### Phase Ordering Rationale

- Sequence follows dependency and risk: P0/P1 technical hazards first, then feature breadth.
- Grouping mirrors architecture boundaries (`core` hardening -> feature slices -> cross-cutting quality).
- Ordering minimizes expensive rework: reminders/reset are intentionally later to prevent automating unstable payment state.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Security Hardening):** credential hashing migration strategy and secure account deletion edge-function contract.
- **Phase 3 (Sync Reliability Core):** conflict-resolution precedence and queue retry semantics under intermittent connectivity.
- **Phase 5 (Billing Automation):** timezone/DST-safe recurrence behavior and cron/client reconciliation edge cases.

Phases with standard patterns (can usually skip `research-phase`):
- **Phase 1 (Data Safety Baseline):** versioned migrations and idempotency testing are established patterns.
- **Phase 4 (Core R1 User Flows):** catalog/form/split/dashboard composition is well-defined from existing architecture.
- **Phase 6 (Quality Gates & UX Consistency):** test gating and design-token consistency workflows are standard.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strong alignment with current codebase and explicit R1-safe additions; low migration risk. |
| Features | HIGH | Table stakes and dependencies are clear and consistent with PROJECT.md active requirements. |
| Architecture | MEDIUM | Integration direction is coherent, but some contracts (queue conflict precedence) still require implementation-level validation. |
| Pitfalls | HIGH | Risks are concrete, severity-ranked, and mapped to preventive controls/phases. |

**Overall confidence:** HIGH

### Gaps to Address

- **Cycle boundary authority details:** finalize exact precedence rules between cron reset and client optimistic updates during planning.
- **Reminder reliability matrix:** validate DST/timezone/travel/reinstall scenarios with explicit acceptance tests before release.
- **Security migration execution:** choose and test credential-hash upgrade path with minimal user friction.
- **Performance budgets:** define measurable latency/query limits for Home and detail views to prevent unnoticed N+1 regressions.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — stack recommendations, dependency strategy, release controls.
- `.planning/research/FEATURES.md` — table stakes, differentiators, anti-features, dependency graph.
- `.planning/research/ARCHITECTURE.md` — component boundaries, capability data flows, build order.
- `.planning/research/PITFALLS.md` — prioritized risks, prevention strategies, phase mapping.
- `.planning/PROJECT.md` — project scope, active requirements, constraints, decisions.

### Secondary (MEDIUM confidence)
- `.planning/codebase/ARCHITECTURE.md` and `.planning/codebase/CONCERNS.md` (referenced by ARCHITECTURE research) — implementation context and known debt.

### Tertiary (LOW confidence)
- No additional tertiary external sources were required for this synthesis.

---
*Research completed: 2026-03-08*  
*Ready for roadmap: yes*
