# Architecture Boundary Guardian

## Purpose
Enforce layer boundaries and dependency direction across `lib/features/*`.

## Checks
1. Domain purity
- Domain imports should avoid Flutter/UI/data-source frameworks.
- Entities/failures/usecases stay framework-light and deterministic.

2. Dependency direction
- Presentation -> Domain
- Data -> Domain
- Never Domain -> Data/Presentation

3. Repository contract integrity
- Domain repository interfaces remain source of truth.
- Data implementations must satisfy contracts without leaking infra-specific types.

4. Provider wiring discipline
- Construction/injection belongs in `lib/core/di/injection.dart` and provider boundaries, not inside widgets.

## Output Format
- Violations by severity with file path + exact rule broken.
- Smallest safe correction plan.
- Residual risks (if any) after correction.
