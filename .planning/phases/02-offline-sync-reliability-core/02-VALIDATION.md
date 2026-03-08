---
phase: 02
slug: offline-sync-reliability-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test |
| **Config file** | `pubspec.yaml` + `analysis_options.yaml` |
| **Quick run command** | `flutter test test/core/sync` |
| **Full suite command** | `flutter test test/core/sync test/features/subscriptions test/features/home test/features/settings` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/core/sync`
- **After every plan wave:** Run `flutter test test/core/sync test/features/subscriptions test/features/home test/features/settings`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SYNC-01 | unit | `flutter test test/core/sync/payment_sync_queue_service_test.dart test/core/sync/payment_sync_orchestrator_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | SYNC-02 | unit/integration | `flutter test test/core/sync/conflict_resolution_test.dart test/core/sync/sync_error_classifier_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | SYNC-03 | widget/provider | `flutter test test/features/subscriptions/presentation/providers/sync_status_provider_test.dart test/features/home/presentation/widgets/home_header_sync_badge_test.dart test/features/settings/presentation/screens/settings_sync_section_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/sync/payment_sync_queue_service_test.dart` — queue lifecycle tests
- [ ] `test/core/sync/payment_sync_orchestrator_test.dart` — drain/backoff/single-flight tests
- [ ] `test/core/sync/conflict_resolution_test.dart` — deterministic cycle conflict tests
- [ ] `test/core/sync/sync_error_classifier_test.dart` — retryable vs terminal mapping
- [ ] `test/features/subscriptions/presentation/providers/sync_status_provider_test.dart` — sync status projection tests
- [ ] `test/features/home/presentation/widgets/home_header_sync_badge_test.dart` — home sync badge
- [ ] `test/features/settings/presentation/screens/settings_sync_section_test.dart` — settings manual actions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Foreground lifecycle drain behavior after resume with real connectivity changes | SYNC-01 | Device lifecycle timing and OS scheduling are hard to model with confidence in pure unit tests | 1) Queue ops offline 2) Resume app online 3) Confirm auto-drain and status transitions |
| User-facing copy clarity for `Requires action` state | SYNC-03 | Product wording quality is subjective and must be validated in UI context | 1) Force terminal operation 2) Review Home/Detail/Settings copy and CTA comprehension |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

