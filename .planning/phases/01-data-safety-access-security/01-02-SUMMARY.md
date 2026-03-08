---
phase: 01-data-safety-access-security
plan: "02"
subsystem: security
tags: [flutter, supabase, edge-functions, riverpod, account-deletion]
requires:
  - phase: 01-data-safety-access-security
    provides: existing settings/account management flow
provides:
  - Backend-authorized account deletion via Supabase Edge Function
  - Flutter delete-account contract scoped to current authenticated user only
  - Regression tests and static guard against client-side admin delete usage
affects: [settings, auth, supabase-functions, security-boundaries]
tech-stack:
  added: [Supabase Edge Function delete-account]
  patterns: [backend-only sensitive account operations, static security guard tests]
key-files:
  created:
    - supabase/functions/delete-account/index.ts
    - supabase/functions/delete-account/deno.json
    - test/features/settings/data/datasources/account_remote_datasource_test.dart
    - test/features/settings/presentation/providers/account_actions_provider_test.dart
  modified:
    - lib/features/settings/data/datasources/account_remote_datasource.dart
    - lib/features/settings/data/repositories/account_repository_impl.dart
    - lib/features/settings/domain/repositories/account_repository.dart
    - lib/features/settings/domain/usecases/delete_account.dart
    - lib/features/settings/presentation/providers/account_actions_provider.dart
    - lib/features/settings/presentation/providers/settings_provider.dart
    - lib/features/settings/presentation/screens/settings_screen.dart
key-decisions:
  - "Delete-account flow now targets the current JWT user and never accepts arbitrary userId input from Flutter."
  - "Sensitive account deletion moved to a Supabase Edge Function that derives actor identity from Authorization JWT."
  - "A static source guard test blocks regressions that reintroduce auth.admin.deleteUser in Flutter client code."
patterns-established:
  - "Sensitive account actions use backend endpoints instead of client-side admin APIs."
  - "Security-critical client constraints are enforced with regression tests plus static source assertions."
requirements-completed: [SECU-02]
duration: 5 min
completed: 2026-03-08
---

# Phase 01 Plan 02: Account Deletion Security Boundary Summary

**Account deletion now executes through an authenticated Supabase Edge Function, with Flutter contract changes that remove arbitrary user targeting and enforce backend-only privileged execution.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-08T12:10:29Z
- **Completed:** 2026-03-08T12:15:42Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Refactored settings/domain/data delete-account interfaces to remove `userId` input and align semantics with "delete current authenticated account."
- Implemented `supabase/functions/delete-account` to authorize via JWT context, delete via service-role admin client, and return structured result codes.
- Added regression coverage for datasource/provider delete-account behavior and a static security guard preventing client admin-delete API reintroduction.

## Task Commits

Each task was committed atomically:

1. **Task 1: Refactor delete-account contract to current-auth-user semantics** - `fb841ca` (feat)
2. **Task 2: Implement backend-authorized delete-account endpoint and client invocation** - `a0341f5` (feat)
3. **Task 3: Add regression tests and static security guard** - `3a08ac2` (test)

Additional blocking-fix commit:

4. **Verification unblock: analyzer compliance fixes** - `eaeca82` (fix)

## Files Created/Modified
- `lib/features/settings/data/datasources/account_remote_datasource.dart` - Switched delete-account to `functions.invoke('delete-account')` with structured error parsing.
- `lib/features/settings/domain/repositories/account_repository.dart` - Removed `userId` from delete-account contract.
- `lib/features/settings/presentation/providers/account_actions_provider.dart` - Updated delete-account action to no-argument flow and analyzer-compatible ref type.
- `lib/features/settings/presentation/screens/settings_screen.dart` - Updated delete-account dialog flow to call provider without userId and retain logout-after-success behavior.
- `supabase/functions/delete-account/index.ts` - Added JWT-authorized backend account deletion endpoint using service-role admin delete.
- `test/features/settings/data/datasources/account_remote_datasource_test.dart` - Added success/error propagation tests and static security guard scan.
- `test/features/settings/presentation/providers/account_actions_provider_test.dart` - Added provider state transition tests for delete-account success/failure.

## Decisions Made
- Enforced backend boundary for account deletion even when caller is authenticated in client.
- Made delete-account use case non-parametric to eliminate arbitrary target user input.
- Added static source assertion to fail tests if `auth.admin.deleteUser` returns in Flutter code.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Analyzer verification gate failed on existing settings lints**
- **Found during:** Final verification block
- **Issue:** `flutter analyze lib/features/settings/data lib/features/settings/domain lib/features/settings/presentation` failed due lint gates in settings providers/screen.
- **Fix:** Updated provider ref typing, converted positional bool params to named params, and typed profile `AsyncValue` usage in settings screen.
- **Files modified:** `lib/features/settings/presentation/providers/account_actions_provider.dart`, `lib/features/settings/presentation/providers/settings_provider.dart`, `lib/features/settings/presentation/screens/settings_screen.dart`
- **Verification:** `flutter analyze ...` passes with no issues.
- **Committed in:** `eaeca82`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification now passes fully; no security scope expansion beyond plan intent.

## Issues Encountered
- Pre-staged unrelated files were present in git index before Task 2 commit and were included in `a0341f5`. This did not affect SECU-02 behavior, but commit purity for Task 2 was impacted.

## Authentication Gates
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SECU-02 backend boundary is enforced and validated by tests/static scan.
- Phase 1 still has remaining plans without summaries (`01-01`, `01-03`), but this plan is complete and ready to hand off.

---
*Phase: 01-data-safety-access-security*
*Completed: 2026-03-08*

## Self-Check: PASSED
