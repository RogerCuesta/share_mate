# .claude Agent Analysis and Optimization

## Goal
Analyze legacy `.claude/agents` deeply, preserve what was used, and create a tighter active system in `.codex/agents`.

## What was in `.claude/agents`
- Main agents: 2
  - `flutter-feature-architect.md`
  - `flutter-devops-quality-guardian.md`
- Sub-agents: 17 specialized files under `sub-agents/`

## Main Agent Intent (Deep Summary)
1. `flutter-feature-architect`
- Strength: clear orchestration for Clean Architecture feature delivery.
- Focus: domain -> data -> state -> UI -> tests, with offline-first + Supabase/Hive.
- Weakness: strictly "orchestrator only" (no direct execution), and part of the content is template-level.

2. `flutter-devops-quality-guardian`
- Strength: broad release-gate mindset with security/performance/testing coverage.
- Focus: quality checks before production.
- Weakness: overlap with several sub-agents; some checks assume tooling not consistently present in this repo.

## Project Reality (from current code)
- Core architecture and stack in active use align with the original intention:
  - Riverpod DI/generation, Hive CE, Supabase, GoRouter, Material 3.
- Business center of gravity is `subscriptions` with payment operations and analytics.
- App already includes offline patterns and a payment sync queue (`lib/core/sync/payment_sync_queue.dart`).
- There are integration tests with Patrol and multiple auth/subscription tests.

## Sub-Agent Review Matrix
Kept as active concept (possibly merged):
- Clean architecture validation
- Domain contract design
- Data layer + offline/sync + Hive/Supabase governance
- Riverpod + UI delivery
- Testing/Patrol/coverage
- Release quality/security/performance/dependency/build sanity

Merged/removed from active set due to overlap:
- `patrol-test-engineer` + `patrol-integration-specialist` + `test-coverage-enforcer` -> merged
- `code-quality-inspector` + `dependency-guardian` + `performance-auditor` + `security-auditor` + build/ci/crash concerns -> merged
- `data-layer-specialist` + `hive-database-auditor` + `supabase-integration-specialist` -> merged
- `ui-component-builder` + `riverpod-state-architect` -> merged

## Active Optimized Topology (new)
- Main:
  - `active/main/share-mate-principal-agent.md`
- Sub-agents:
  - `architecture-boundary-guardian.md`
  - `domain-contract-specialist.md`
  - `offline-first-data-sync-specialist.md`
  - `riverpod-ui-delivery-specialist.md`
  - `qa-test-automation-specialist.md`
  - `release-quality-guardian.md`

## Why this is better
1. Lower overlap and less context switching.
2. Better alignment with real repo constraints and file layout.
3. Keeps old agent set intact under `legacy-claude` for compatibility.
4. Easier to maintain as project evolves.
