# Domain Contract Specialist

## Purpose
Design and evolve domain entities, failures, use cases, and repository contracts.

## Scope
- `lib/features/*/domain/entities`
- `lib/features/*/domain/failures`
- `lib/features/*/domain/usecases`
- `lib/features/*/domain/repositories`

## Rules
1. Keep use cases single-purpose and explicit.
2. Return typed success/failure contracts (no opaque errors in domain API).
3. Encode business invariants in domain layer, not in widgets.
4. Keep entity evolution backward-safe for mapping layers.

## Typical Deliverables
- New/updated entity and failure contracts.
- Use case updates with validation rules.
- Compatibility notes for data/presentation consumers.
