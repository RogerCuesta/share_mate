# TESTING

## Scope
This document summarizes the current testing setup and patterns verified from `test/`, `integration_test/`, and actual local test command execution.

## Frameworks and Test Dependencies
- Unit/widget tests use Flutter test tooling via `flutter_test` (declared in `pubspec.yaml`).
- Mocking is done with `mocktail` (`pubspec.yaml`, `test/helpers/mocks.dart`).
- Functional result assertions commonly use `dartz` `Either` in domain/data tests.
- Integration/E2E strategy is based on Patrol (`patrol` in `dev_dependencies`, docs under `integration_test/`).

## Test Directory Structure
- Unit and widget tests live under `test/features/...` with architecture-aligned placement:
- Data layer tests: `test/features/auth/data/...`
- Domain tests: `test/features/auth/domain/...`, `test/features/subscriptions/domain/...`
- Presentation tests: `test/features/subscriptions/presentation/...`
- Shared mocks/helpers: `test/helpers/mocks.dart`
- Integration tests and setup docs: `integration_test/mark_payment_as_paid_test.dart` plus `integration_test/README.md`, `integration_test/QUICK_START.md`, `integration_test/PATROL_TEST_SETUP.md`.

## Current Executed Status (Local Verification)
- `flutter test` executed successfully in this repo.
- Result: 108/108 tests passing.
- `flutter test --coverage` executed successfully and generated `coverage/lcov.info`.
- Current line coverage from `coverage/lcov.info`: 8.73% (355 hit / 4065 tracked lines).
- Patrol CLI is not installed in this environment (`patrol --version` -> command not found), so Patrol tests were not executed here.

## Observed Test Composition
- Total discovered cases in repo: 121 (`test` + `integration_test`):
- `test(...)`: 96
- `testWidgets(...)`: 12
- `patrolTest(...)`: 8
- Coverage concentration is mostly auth and selected subscriptions use cases/widgets.
- Settings, core infrastructure, and most presentation flows are lightly or not directly covered by current executable unit/widget suite.

## Unit Test Patterns
- AAA style is used consistently (Arrange/Act/Assert), with group-based organization.
- Repositories and use cases are tested with mocked dependencies (examples: `test/features/auth/data/repositories/auth_repository_impl_test.dart`, `test/features/subscriptions/domain/usecases/create_subscription_test.dart`).
- Domain entity tests focus on invariants and computed properties (example: `test/features/auth/domain/entities/user_test.dart`).
- Mocktail fallback registrations are used where needed (`registerFallbackValue` in auth tests).

## Widget Test Patterns
- Widget tests wrap widgets in `MaterialApp` and use user-interaction flows (`pumpWidget`, `tap`, `enterText`, `pumpAndSettle`).
- Good example: `test/features/subscriptions/presentation/widgets/add_member_dialog_test.dart` validates form errors, cancellation, data normalization, and dialog return values.

## Integration Test Setup (Patrol)
- Main integration scenario file: `integration_test/mark_payment_as_paid_test.dart`.
- Includes 8 end-to-end flows for payment operations, undo behavior, navigation, and stat recalculation.
- Test harness performs full app setup (`EnvConfig`, `SupabaseService`, `HiveService`, provider overrides) before pumping test app.
- Integration docs require semantic keys in production widgets, but many referenced keys are currently absent from real UI files (for example `subscription_detail_screen.dart`, `payment_status_toggle.dart`, `payment_action_buttons.dart`, `home_screen.dart`, `active_subscriptions_section.dart`), creating a likely execution gap.

## Canonical Commands
- Run unit/widget suite: `flutter test`
- Run with coverage output: `flutter test --coverage`
- Generate HTML coverage report (if `genhtml` is installed): `genhtml coverage/lcov.info -o coverage/html`
- Build generated code before tests that rely on generated files: `flutter pub run build_runner build --delete-conflicting-outputs`
- Patrol setup command (required before E2E): `dart pub global activate patrol_cli`
- Patrol run command (documented): `patrol test integration_test/mark_payment_as_paid_test.dart`

## Practical Gaps to Track
- Raise overall coverage from current 8.73%, especially in `lib/core/`, settings presentation/data, and subscriptions presentation async flows.
- Add/restore semantic keys required by Patrol docs, or update integration tests to match current widget tree.
- Add CI automation for both `flutter test` and Patrol execution once CLI/toolchain is available in runner environment.
