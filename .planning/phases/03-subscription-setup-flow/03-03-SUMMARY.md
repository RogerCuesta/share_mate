---
phase: 03-subscription-setup-flow
plan: "03"
subsystem: ui
tags: [contacts, subscriptions, flutter, riverpod, supabase]

requires:
  - phase: 03-subscription-setup-flow
    provides: Nullable contact/subscription-member email contracts from prior phase work
  - phase: 03-subscription-setup-flow
    provides: Catalog sheet + form autofill baseline from 03-02
provides:
  - In-flow contact selection/quick-create/edit/delete inside subscription setup
  - Deterministic `subscription_members.user_email = null` for no-email contacts
  - Duplicate exact-name warning with reuse-or-continue flow in quick-create
affects: [phase-03-subscription-setup-flow, phase-04-payment-tracking-debt-home, contacts, split-preview]

tech-stack:
  added: []
  patterns:
    - Sheet-driven contact CRUD orchestration from screen callbacks into form provider state
    - Contact/member identity reconciliation by contact/user ID (not email key)

key-files:
  created:
    - lib/features/subscriptions/presentation/widgets/contacts_selection_sheet.dart
    - lib/features/subscriptions/presentation/widgets/quick_contact_form.dart
    - test/features/contacts/data/datasources/contact_remote_datasource_test.dart
    - test/features/subscriptions/data/repositories/subscription_repository_member_email_contract_test.dart
    - test/features/subscriptions/presentation/widgets/contacts_selection_sheet_test.dart
    - test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_contacts_test.dart
  modified:
    - lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart
    - lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart
    - lib/features/subscriptions/presentation/widgets/members_list_section.dart
    - lib/features/contacts/data/datasources/contact_remote_datasource.dart
    - lib/features/subscriptions/data/models/subscription_member_model.dart
    - lib/features/subscriptions/data/repositories/subscription_repository_impl.dart
    - lib/features/subscriptions/domain/repositories/subscription_repository.dart

key-decisions:
  - "Selected members are now keyed by contact/user id so contact email edits do not break selection diffing."
  - "Quick-create duplicate-name UX defaults to reuse suggestion, with explicit 'Create Anyway' continuation."
  - "Blank/whitespace member emails are normalized to null before persistence."

patterns-established:
  - "Create/edit subscription flow owns contact CRUD orchestration without leaving the screen."
  - "Contact UI surfaces tolerate nullable email across dialogs, list rendering, and search."

requirements-completed: [CNTC-01, CNTC-02]
duration: 15 min
completed: 2026-03-08
---

# Phase 03 Plan 03: Contacts Setup Integration Summary

**Embedded contacts management (select + quick create + edit/delete) in the subscription setup flow with null-email-safe persistence contracts**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-08T22:55:36Z
- **Completed:** 2026-03-08T23:11:33Z
- **Tasks:** 3
- **Files modified:** 20

## Accomplishments
- Aligned contacts/subscription persistence with nullable email semantics and added contract tests for no-email members.
- Built a tabbed contacts sheet with quick-create form, optional email, color selection, and duplicate exact-name decision flow.
- Replaced manual add-member dialog flow with sheet-driven contact selection/edit/delete wired directly into live form member state.

## Task Commits

Each task was committed atomically:

1. **Task 1: Align contacts + subscription member persistence with optional-email contract** - `ec5f6c9` (fix)
2. **Task 2: Build tabbed contacts sheet (Select + Quick Create) with duplicate warning UX** - `a6a169c` (feat)
3. **Task 3: Wire in-flow select/edit/delete contact actions into form orchestration** - `634ddfc` (feat)

Additional task-scope auto-fix commit:
- `16373b9` (fix) to resolve strict analyzer gates triggered by Task 3 callback/provider changes.

## Files Created/Modified
- `lib/features/subscriptions/presentation/widgets/contacts_selection_sheet.dart` - New Select + Quick Create modal sheet with duplicate handling.
- `lib/features/subscriptions/presentation/widgets/quick_contact_form.dart` - Quick-create form model/UI with optional email and avatar color.
- `lib/features/subscriptions/presentation/widgets/members_list_section.dart` - Updated to sheet-based contact management entrypoint.
- `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart` - Contact-to-member sync methods, ID-based reconciliation, split amount pass-through for add-member persistence.
- `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart` - CRUD orchestration between sheet callbacks, contacts use cases, and form state.
- `lib/features/contacts/data/datasources/contact_remote_datasource.dart` - Payload builders now preserve null-email semantics and contact color writes.
- `lib/features/subscriptions/data/models/subscription_member_model.dart` - Normalizes blank `user_email` values to null for JSON/entity mapping.
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart` - Normalizes optional member email and supports explicit amount override on add-member.
- `test/features/subscriptions/presentation/widgets/contacts_selection_sheet_test.dart` - Covers tabs, selection, duplicate reuse, and create-anyway path.
- `test/features/subscriptions/presentation/providers/create_group_subscription_form_provider_contacts_test.dart` - Covers contact selection/update/dedup/delete synchronization.

## Decisions Made
- Member identity reconciliation in edit mode was switched to ID-only keys, avoiding false add/remove cycles when contact emails change.
- Add-member repository API accepted optional explicit `amountToPay` to keep persisted member amounts coherent with form split math.
- Contacts provider entrypoint was moved to `Ref` signature and sheet selection callback changed to named bool for lint-clean analyzer runs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Nullable-email rendering and search regressions in contacts UI**
- **Found during:** Task 1
- **Issue:** Contacts list/search/dialogs assumed email was always non-null, conflicting with no-email contact contract.
- **Fix:** Updated contacts UI search, list tiles, and add/edit dialogs to tolerate optional email and keep validation optional.
- **Files modified:** `lib/features/contacts/presentation/screens/contacts_screen.dart`, `lib/features/contacts/presentation/widgets/contact_list_item.dart`, `lib/features/contacts/presentation/widgets/add_contact_dialog.dart`, `lib/features/contacts/presentation/widgets/edit_contact_dialog.dart`
- **Verification:** `flutter analyze lib/features/contacts ...`
- **Committed in:** `ec5f6c9`

**2. [Rule 3 - Blocking] Strict analyzer gate failures after sheet wiring**
- **Found during:** Post-task verification
- **Issue:** Fatal infos (`deprecated_member_use_from_same_package`, positional bool callback lint) blocked required analyze command.
- **Fix:** Updated contacts provider signature to `Ref` and migrated sheet callback contract to named bool parameter.
- **Files modified:** `lib/features/contacts/presentation/providers/contacts_provider.dart`, `lib/features/subscriptions/presentation/widgets/contacts_selection_sheet.dart`, `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`, `test/features/subscriptions/presentation/widgets/contacts_selection_sheet_test.dart`
- **Verification:** Required plan analyze command passed with no issues.
- **Committed in:** `16373b9`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** All deviations were directly required to keep nullable-email contract and mandatory verification gates green; no scope creep beyond CNTC requirements.

## Issues Encountered
- Compilation error in `contacts_selection_sheet.dart` due duplicate `_` separatorBuilder args; fixed to `(_, __)` during Task 2 verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 03 now has in-flow contact CRUD and null-email-safe member persistence wired for subscription setup.
- Ready for next plan in phase 03 (`03-04-PLAN.md`) with no blockers recorded.

---
*Phase: 03-subscription-setup-flow*
*Completed: 2026-03-08*

## Self-Check: PASSED
- Verified summary file exists on disk.
- Verified task commit hashes exist in git history: `ec5f6c9`, `a6a169c`, `634ddfc`, `16373b9`.
