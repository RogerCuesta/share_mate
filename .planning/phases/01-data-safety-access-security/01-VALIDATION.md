---
phase: 1
slug: data-safety-access-security
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-08
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + integration_test |
| **Config file** | `pubspec.yaml`, `analysis_options.yaml` |
| **Quick run command** | `task-local <automated> command` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local `<automated>` command (target <30s)
- **After every plan wave:** Run `flutter test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | SAFE-02 | unit | `flutter test test/core/storage/local_migration_runner_test.dart` | ✅ | ⬜ pending |
| 01-01-02 | 01 | 1 | SAFE-01, SECU-01 | static + analyze | `flutter analyze lib/main.dart lib/core/sync/payment_sync_queue.dart lib/features/contacts/data/datasources/contact_local_datasource.dart` | ✅ | ⬜ pending |
| 01-01-03 | 01 | 1 | SAFE-01, SAFE-02, SECU-01 | unit + regression | `flutter test test/core/storage/local_migration_runner_test.dart test/core/storage/encrypted_bootstrap_test.dart` | ✅ | ⬜ pending |
| 01-02-01 | 02 | 1 | SECU-02 | static + analyze | `flutter analyze lib/features/settings/data lib/features/settings/domain lib/features/settings/presentation` | ✅ | ⬜ pending |
| 01-02-02 | 02 | 1 | SECU-02 | static scan | `rg -n "functions\.invoke\('delete-account'\)|auth\.admin\.deleteUser" lib/features/settings/data/datasources/account_remote_datasource.dart` | ✅ | ⬜ pending |
| 01-02-03 | 02 | 1 | SECU-02 | unit | `flutter test test/features/settings/data/datasources/account_remote_datasource_test.dart test/features/settings/presentation/providers/account_actions_provider_test.dart` | ✅ | ⬜ pending |
| 01-03-01 | 03 | 2 | SECU-03 | sql policy lint | `rg -n "ALTER TABLE (subscriptions|subscription_members|payment_history|contacts) ENABLE ROW LEVEL SECURITY|CREATE POLICY" supabase/migrations/20260308_phase1_rls_hardening.sql` | ✅ | ⬜ pending |
| 01-03-02 | 03 | 2 | SECU-03 | sql function guard | `rg -n "SECURITY DEFINER|SET search_path|auth\.uid\(\)" supabase/migrations/20251225_payment_history_enhancements.sql supabase/migrations/20260308_phase1_rls_hardening.sql` | ✅ | ⬜ pending |
| 01-03-03 | 03 | 2 | SECU-03 | integration + audit | `bash scripts/security/run_rls_policy_audit.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Sampling Continuity Check

| Consecutive Window | Automated Checks in Window | Pass |
|--------------------|----------------------------|------|
| 01-01-01 → 01-01-03 | 3/3 | ✅ |
| 01-01-02 → 01-02-01 | 3/3 | ✅ |
| 01-01-03 → 01-02-02 | 3/3 | ✅ |
| 01-02-01 → 01-02-03 | 3/3 | ✅ |
| 01-02-02 → 01-03-01 | 3/3 | ✅ |
| 01-02-03 → 01-03-02 | 3/3 | ✅ |
| 01-03-01 → 01-03-03 | 3/3 | ✅ |

---

## Wave 0 Requirements

- [x] Add tests for non-destructive migration runner behavior (`SAFE-01`, `SAFE-02`)
- [x] Add tests for encrypted box open/migration behavior (`SECU-01`)
- [x] Add tests for account delete backend-only path (`SECU-02`)
- [x] Add tests/assertions for RLS isolation and RPC authorization (`SECU-03`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Existing user data survives app restart after migration | SAFE-01 | Requires realistic local dataset and restart lifecycle | Populate local data, relaunch app, verify intact subscriptions/members/payments/contacts |
| Key-failure recovery blocks writes and guides user recovery without plaintext fallback | SECU-01 | Failure injection + UX validation | Simulate key retrieval failure, verify safe-mode route blocks write operations, displays guided recovery steps, and does not open plaintext boxes |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers SAFE-01, SAFE-02, SECU-01, SECU-02, SECU-03
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready
