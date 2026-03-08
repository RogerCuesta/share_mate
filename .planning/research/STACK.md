# STACK - MVP R1 Recommendations (Brownfield Flutter)

## 1) Recommended stack (current + changes)

### Keep as core (already aligned with codebase)
- Flutter + Dart (current app foundation in `lib/` and `pubspec.yaml`).
- Riverpod + `riverpod_annotation` for DI/state orchestration across features.
- Clean Architecture feature modules (`data/domain/presentation`) as the delivery boundary.
- Supabase (Auth, Postgres, RLS, RPC) as backend source of truth.
- Hive CE for offline cache and fast local reads.
- GoRouter for auth-aware navigation and shell routing.
- Freezed + build_runner for immutable models and safer refactors.

### Add now (required to finish R1 scope safely)
- `flutter_local_notifications`: local reminders T-24h per subscription cycle.
- `timezone`: deterministic local scheduling and DST-safe triggers.
- `permission_handler`: explicit notification permission flow on Android/iOS.
- Supabase scheduled reset path:
- Use Postgres function + scheduled job (`pg_cron` on DB or Supabase Scheduler) to reset `has_paid` monthly.
- Keep reset logic server-side; client must only reflect/reset state from backend sync.

### Change implementation focus (no platform rewrite)
- Keep offline-first pattern, but add a queue processor lifecycle (foreground + startup drain).
- Gate destructive Hive migrations by version flag (do not clear boxes unconditionally on boot).
- Encrypt subscriptions/payment Hive boxes to match existing secure-storage intent.
- Normalize app naming and package identity (`flutter_project_agents` -> Share Mate naming cleanup) before release builds.

## 2) Libraries/tools with rationale

- `flutter_riverpod` + `riverpod_annotation`: already pervasive, low migration risk, strong testability with providers.
- `supabase_flutter`: already integrated for auth/data, avoids adding another backend SDK.
- RPC-first for multi-step writes (already used in payment atomic functions): reduces client race conditions.
- Hive CE + `flutter_secure_storage`: best fit for current offline model; secure key material separated from cached data.
- `flutter_local_notifications` + `timezone`: minimum viable stack for reliable monthly reminders and T-24h scheduling.
- `permission_handler`: avoids ad-hoc platform-channel code for runtime permissions.
- `build_runner` + Freezed + generated providers: keep generation pipeline as-is to avoid manual boilerplate drift.
- Patrol (existing dev dependency): keep for 1-2 critical E2E paths only (payment status + debt summary refresh).
- `flutter_launcher_icons` and `flutter_native_splash` (dev tools, optional but recommended): speed up production polish without custom scripts.

## 3) Version strategy

- Freeze MVP R1 on a single validated Flutter/Dart toolchain across team machines.
- Add FVM pinning (`.fvmrc`) and enforce `fvm flutter pub get/test/analyze` in docs.
- Dependency policy for R1 closeout:
- Allow patch updates automatically (`x.y.Z`) after smoke test pass.
- Batch minor updates into one weekly window with regression suite.
- No major upgrades until after R1 release cut unless security-critical.
- Keep `pubspec.lock` committed for deterministic CI/dev parity.
- Add a lightweight release branch rule:
- `main`: ongoing R1 work.
- `release/r1`: only bugfixes, dependency freeze except critical fixes.
- Supabase migrations:
- Forward-only SQL migrations; never edit applied migration files.
- For reset/notification schema changes, create additive migrations and backfill scripts.

## 4) What not to use now

- Do not introduce BLoC/Provider/GetX alongside Riverpod (state-management fragmentation risk).
- Do not add Firebase services in parallel with Supabase for MVP R1 (duplicated auth/data complexity).
- Do not add heavy background frameworks (`workmanager`, custom isolate schedulers) unless local notifications fail requirements.
- Do not build custom local notification platform channels; use maintained plugin stack first.
- Do not adopt friend/invite real-time collaboration now (already out of R1 scope in PROJECT.md).
- Do not add payment gateways (Stripe/Bizum) before debt-tracking core loop is stable.
- Do not attempt multi-currency/domain expansion before single-locale debt UX is complete.
- Do not run broad dependency modernization across all packages during R1 stabilization.

## 5) Confidence levels

- Keep current core stack (Flutter/Riverpod/Supabase/Hive/Clean Architecture): **High (0.92)**.
- Add notifications stack (`flutter_local_notifications` + `timezone` + permission flow): **High (0.88)**.
- Server-side monthly reset via Supabase scheduled job + SQL function: **High (0.90)**.
- Queue processor + migration gating + Hive encryption hardening during R1: **Medium-High (0.81)** (known debt, moderate implementation effort).
- FVM pinning + lockfile + staged dependency updates: **High (0.91)**.
- Defer broader platform additions (payments, real-time collaboration, multi-currency): **High (0.95)** for R1 scope discipline.

## Immediate execution checklist (next 1-2 sprints)

- Add notification dependencies and implement one end-to-end T-24h schedule path.
- Create Supabase migration for monthly reset function + scheduler; validate on staging data.
- Implement startup-safe migration guard (remove unconditional local data wipe).
- Encrypt subscription/payment Hive boxes and provide one-time migration.
- Add/repair 2 Patrol scenarios tied to R1 success metrics (mark paid, debt total refresh).
- Pin toolchain with FVM and document release dependency policy in repo docs.
