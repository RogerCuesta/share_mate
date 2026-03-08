---
phase: 1
slug: data-safety-access-security
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 240 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | SAFE-01 | integration + unit | `flutter test` | ✅ | ⬜ pending |
| 01-01-02 | 01 | 1 | SAFE-02 | unit | `flutter test` | ✅ | ⬜ pending |
| 01-02-01 | 02 | 1 | SECU-01 | unit + smoke | `flutter test` | ✅ | ⬜ pending |
| 01-03-01 | 03 | 2 | SECU-02 | integration | `flutter test` | ✅ | ⬜ pending |
| 01-03-02 | 03 | 2 | SECU-03 | integration + policy checks | `flutter test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add tests for non-destructive migration runner behavior (`SAFE-01`, `SAFE-02`)
- [ ] Add tests for encrypted box open/migration behavior (`SECU-01`)
- [ ] Add tests for account delete backend-only path (`SECU-02`)
- [ ] Add tests/assertions for RLS isolation and RPC authorization (`SECU-03`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Existing user data survives app restart after migration | SAFE-01 | Requires realistic local dataset and restart lifecycle | Populate local data, relaunch app, verify intact subscriptions/members/payments/contacts |
| Key-failure recovery screen blocks unsafe writes | SECU-01 | Failure injection + UX validation | Simulate key retrieval failure, verify safe-mode flow and no plaintext fallback |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 240s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
