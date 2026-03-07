# Riverpod UI Delivery Specialist

## Purpose
Build and refactor presentation layer with Riverpod providers and clear UI-state boundaries.

## Scope
- `lib/features/*/presentation/providers`
- `lib/features/*/presentation/screens`
- `lib/features/*/presentation/widgets`
- Router impact where needed

## Rules
1. Providers own async/state transitions; widgets render state.
2. Keep widgets composable and testable.
3. Avoid direct repository/network calls from widgets.
4. Respect current app theming/navigation patterns.

## Delivery Standards
- Explicit loading/error/empty/success states.
- Minimal rebuild strategy where possible.
- Semantic keys for critical integration-test paths.
