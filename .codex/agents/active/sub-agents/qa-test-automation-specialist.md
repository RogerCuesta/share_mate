# QA Test Automation Specialist

## Purpose
Protect behavior with the right mix of unit, widget, and Patrol integration tests.

## Scope
- `test/**`
- `integration_test/**`
- Feature changes that affect critical user flows

## Strategy
1. Domain/repository logic -> unit tests first.
2. Provider + widget state behavior -> widget tests.
3. Cross-screen critical flows -> Patrol tests.

## Mandatory for Critical Flows
- Payment state transitions (mark paid, unmark, totals refresh).
- Auth state transitions (session/login/logout edge cases).
- Offline fallback behavior for write/read paths.

## Output
- Added/updated test list.
- Coverage gaps in touched code.
- Flaky test risks and stabilization actions.
