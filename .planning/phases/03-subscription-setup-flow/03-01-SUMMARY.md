---
phase: 03-subscription-setup-flow
plan: "01"
subsystem: database
tags: [supabase, flutter, hive, freezed, contracts, serialization]
requires:
  - phase: 01-data-safety-access-security
    provides: RLS baseline and secure table-access policies
  - phase: 02-offline-sync-reliability-core
    provides: stable offline-first model persistence contracts
provides:
  - Phase 3 migration for `service_templates`, nullable contact/member emails, and `billing_anchor_day`
  - Flutter domain/data contract alignment for service templates, contact optional email, and billing anchor persistence
  - Regression coverage for legacy payload compatibility and nullable-field round-trips
affects: [03-02, 03-03, 04-payment-tracking-debt-home, 05-billing-automation-cycle]
tech-stack:
  added: [supabase migration 20260309, model regression tests]
  patterns: [legacy-safe JSON fallback, nullable email contracts, explicit billing anchor persistence]
key-files:
  created:
    - supabase/migrations/20260309_phase3_subscription_setup_foundation.sql
    - lib/features/subscriptions/domain/entities/service_template.dart
    - lib/features/subscriptions/data/models/service_template_model.dart
    - test/features/subscriptions/data/models/subscription_model_test.dart
    - test/features/subscriptions/data/models/subscription_member_model_test.dart
    - test/features/contacts/data/models/contact_model_test.dart
  modified:
    - lib/features/subscriptions/domain/entities/subscription.dart
    - lib/features/subscriptions/data/models/subscription_model.dart
    - lib/features/subscriptions/domain/entities/subscription_member.dart
    - lib/features/subscriptions/data/models/subscription_member_model.dart
    - lib/features/contacts/domain/entities/contact.dart
    - lib/features/contacts/domain/entities/add_contact_input.dart
    - lib/features/contacts/domain/entities/update_contact_input.dart
    - lib/features/contacts/data/models/contact_model.dart
key-decisions:
  - "SubscriptionModel.fromJson falls back to due_date.day when billing_anchor_day is absent to preserve legacy compatibility."
  - "Contacts and subscription members now support nullable emails end-to-end in domain/data contracts."
  - "Catalog templates use explicit slug/name/logo/color/aliases/search_terms fields for 1:1 schema-model mapping."
patterns-established:
  - "Nullable contract propagation: schema -> model -> entity -> regression tests."
  - "Backfill-safe field rollout: add persisted field plus deserialize fallback for legacy rows."
requirements-completed: [CATA-01, CNTC-01, SPLT-03]
duration: 9 min
completed: 2026-03-08
---

# Phase 03 Plan 01: Subscription Setup Foundation Summary

**Service template SQL foundation, nullable local-contact/member email contracts, and billing-anchor persistence with legacy-safe model fallbacks**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-08T22:21:16Z
- **Completed:** 2026-03-08T22:30:22Z
- **Tasks:** 3
- **Files modified:** 16

## Accomplishments
- Added a single phase migration that introduces `service_templates`, relaxes contact/member email constraints, and persists `billing_anchor_day` with backfill.
- Updated Flutter subscription/contact contracts to reflect nullable email and billing anchor semantics while keeping legacy payload compatibility.
- Added regression tests proving nullable fields and backfilled defaults deserialize/serialize safely before UI/repository integration work.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add phase-3 SQL migration for templates, contact optional-email, and billing anchor day** - `045b090` (feat)
2. **Task 2: Update Flutter entities/models to reflect new canonical contracts** - `b95448f` (feat)
3. **Task 3: Add contract regression tests for optional fields and backfilled defaults** - `94c4ec3` (test)

## Files Created/Modified
- `supabase/migrations/20260309_phase3_subscription_setup_foundation.sql` - canonical schema contract for templates/contacts/subscriptions.
- `lib/features/subscriptions/domain/entities/service_template.dart` - new domain entity for catalog templates.
- `lib/features/subscriptions/data/models/service_template_model.dart` - model serialization for `service_templates`.
- `lib/features/subscriptions/domain/entities/subscription.dart` - added `billingAnchorDay` domain field.
- `lib/features/subscriptions/data/models/subscription_model.dart` - added `billing_anchor_day` JSON/Hive mapping with legacy fallback.
- `lib/features/subscriptions/domain/entities/subscription_member.dart` - nullable `userEmail` contract.
- `lib/features/subscriptions/data/models/subscription_member_model.dart` - nullable `user_email` serialization/deserialization.
- `lib/features/contacts/domain/entities/contact.dart` - optional email + color metadata on contacts.
- `lib/features/contacts/domain/entities/add_contact_input.dart` - optional-email validation flow with optional color validation.
- `lib/features/contacts/domain/entities/update_contact_input.dart` - optional-email validation flow with optional color validation.
- `lib/features/contacts/data/models/contact_model.dart` - nullable `contact_email` + `contact_color` mapping.
- `test/features/subscriptions/data/models/subscription_model_test.dart` - regression tests for `billingAnchorDay` fallback and serialization.
- `test/features/subscriptions/data/models/subscription_member_model_test.dart` - regression tests for nullable member emails.
- `test/features/contacts/data/models/contact_model_test.dart` - regression tests for nullable contact emails and color metadata.

## Decisions Made
- Persisted `billingAnchorDay` at model level while defaulting to `dueDate.day` for legacy payloads missing `billing_anchor_day`.
- Chose nullable email contracts for contacts and subscription members instead of placeholder email synthesis.
- Added service template domain/model contracts immediately with schema rollout to keep Phase 3 data contracts 1:1 from day one.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Propagated nullable member email into subscription member domain entity**
- **Found during:** Task 2
- **Issue:** `SubscriptionMemberModel` needed nullable `userEmail`, but `SubscriptionMember` domain contract still required non-null email.
- **Fix:** Updated `subscription_member.dart` to make `userEmail` nullable and regenerated dependent contracts.
- **Files modified:** `lib/features/subscriptions/domain/entities/subscription_member.dart`
- **Verification:** `flutter analyze ...` passed with nullable mapping intact.
- **Committed in:** `b95448f`

**2. [Rule 3 - Blocking] Updated subscription member input + model lint blockers to satisfy fatal-info analyze gate**
- **Found during:** Task 2 verification
- **Issue:** `subscription_member_input.dart` still required non-null email (type error), and fatal-info lint blockers prevented required analyze command completion.
- **Fix:** Made member-input email optional with format-only-if-provided validation and removed redundant null defaultValue annotations causing fatal infos.
- **Files modified:** `lib/features/subscriptions/domain/entities/subscription_member_input.dart`, `lib/features/subscriptions/data/models/payment_history_model.dart`
- **Verification:** `flutter analyze lib/features/subscriptions/domain/entities lib/features/subscriptions/data/models lib/features/contacts/domain/entities lib/features/contacts/data/models`
- **Committed in:** `b95448f`

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both fixes were required to keep schema/model nullable-email contracts coherent and pass the mandatory verification gate.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Phase 3 foundations are in place for catalog retrieval/caching, in-flow local-contact UX, and split/date logic implementation in follow-up plans.
Ready for `03-02-PLAN.md`.

---
*Phase: 03-subscription-setup-flow*
*Completed: 2026-03-08*

## Self-Check: PASSED
