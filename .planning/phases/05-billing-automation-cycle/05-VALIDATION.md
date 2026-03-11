---
phase: 05
slug: billing-automation-cycle
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-11
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (package:test + widget/integration) |
| **Config file** | `analysis_options.yaml` |
| **Quick run command** | `flutter test test/features/subscriptions/phase5_requirements_traceability_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~210 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/subscriptions/phase5_requirements_traceability_test.dart`
- **After every plan wave:** Run focused phase suite, then `flutter test` before final close
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | BILL-01 | unit | `flutter test test/features/billing_automation/domain/billing_reminder_scheduler_test.dart` | ✅ | ✅ green |
| 05-01-02 | 01 | 1 | BILL-01 | unit | `flutter test test/features/billing_automation/data/billing_reminder_registry_test.dart` | ✅ | ✅ green |
| 05-02-01 | 02 | 2 | BILL-02 | unit | `flutter test test/features/billing_automation/domain/billing_automation_orchestrator_test.dart` | ✅ | ✅ green |
| 05-02-02 | 02 | 2 | BILL-02 | widget | `flutter test test/features/settings/presentation/providers/settings_provider_test.dart test/features/settings/presentation/screens/settings_sync_section_test.dart test/features/home/presentation/widgets/home_header_sync_badge_test.dart` | ✅ | ✅ green |
| 05-03-01 | 03 | 3 | BILL-03 | unit | `flutter test test/core/sync/payment_sync_orchestrator_test.dart test/core/sync/conflict_resolution_test.dart` | ✅ | ✅ green |
| 05-03-02 | 03 | 3 | BILL-03 | widget | `flutter test test/features/subscriptions/presentation/providers/payment_reconciliation_provider_test.dart test/features/subscriptions/presentation/providers/sync_status_provider_test.dart test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart` | ✅ | ✅ green |
| 05-04-01 | 04 | 4 | BILL-01,BILL-02,BILL-03 | traceability | `flutter test test/features/subscriptions/phase5_requirements_traceability_test.dart` | ✅ | ✅ green |
| 05-04-02 | 04 | 4 | BILL-01,BILL-02,BILL-03 | integration | `flutter test integration_test/billing_automation_cycle_uat_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/features/billing_automation/domain/billing_reminder_scheduler_test.dart` — scheduler contracts BILL-01
- [x] `test/features/billing_automation/domain/billing_automation_orchestrator_test.dart` — reprogramming and dedupe contracts BILL-02
- [x] `test/features/billing_automation/data/billing_reminder_registry_test.dart` — idempotent registry behavior BILL-02
- [x] `test/features/subscriptions/phase5_requirements_traceability_test.dart` — phase-level guard BILL-01/02/03

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Device notification delivery and tap deep-link to subscription detail | BILL-01 | Requires OS notification runtime and user interaction | Create active subscription due in <24h test window, trigger scheduler, validate push appears and opens detail route |
| Permission denied banner + CTA flow | BILL-01,BILL-02 | Depends on OS-level permission state transitions | Deny notification permission in device settings, reopen app, verify non-blocking banner and CTA behavior |
| Migration/reinstall reprogramming without duplicate pushes | BILL-02 | Needs install lifecycle and notification center persistence | Schedule reminders, reinstall/simulate migration, reopen app, verify one reminder per `(subscriptionId, cycleDueDate)` |
| Backend cycle reset propagation to client with non-blocking reconciliation message | BILL-03 | Requires backend scheduler/RPC execution + client sync window | Force `run_billing_cycle_resets()` on backend, reopen app, validate member states reset to pending and snackbar reconciliation feedback |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s (quick run target)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execute-phase verification
