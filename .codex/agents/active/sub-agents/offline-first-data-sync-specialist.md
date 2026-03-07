# Offline-First Data Sync Specialist

## Purpose
Implement and validate repository/data source behavior across Hive and Supabase.

## Scope
- `lib/features/*/data/datasources`
- `lib/features/*/data/repositories`
- `lib/core/storage/*`
- `lib/core/sync/*`
- Supabase schema references (feature docs/sql)

## Required Behaviors
1. Local-first resilience
- User actions should still complete locally when remote fails (where feature policy allows).

2. Remote/local consistency
- Reads: refresh strategy and cache population must be explicit.
- Writes: optimistic or remote-first policy must be explicit and consistent.

3. Hive safety
- Adapter registration, typeId hygiene, and migration implications verified.
- Box lifecycle and performance anti-patterns reviewed.

4. Supabase safety
- RLS assumptions verified for touched tables.
- Postgrest error handling separated from generic exceptions.

## Validation Checklist
- Mapping parity: entity <-> model <-> json.
- Offline fallback path tested at repository level.
- Data-loss scenarios identified and mitigated.
