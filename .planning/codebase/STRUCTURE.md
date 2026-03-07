# Structure

## Repository Layout
- Application code: `lib/`
- Unit/widget tests: `test/`
- Integration tests and guides: `integration_test/`
- Supabase SQL migrations: `supabase/migrations/`
- Project docs and reports: `docs/`, `README.md`, `SECURITY.md`, `SUPABASE_SETUP.md`
- Flutter platform hosts: `android/`, `ios/`
- Planning output workspace: `.planning/codebase/`

## `lib/` Directory Map
- `lib/main.dart`: startup orchestration and dependency override wiring.
- `lib/routing/app_router.dart`: route constants, GoRouter setup, auth redirects, splash/login/register/app flows.
- `lib/core/`:
  - `config/`: env access (`lib/core/config/env_config.dart`)
  - `di/`: app-wide provider graph (`lib/core/di/injection.dart`)
  - `presentation/`: shared app shell (`lib/core/presentation/app_shell.dart`)
  - `storage/`: Hive setup and type IDs (`lib/core/storage/hive_service.dart`, `lib/core/storage/hive_type_ids.dart`)
  - `supabase/`: client bootstrap (`lib/core/supabase/supabase_service.dart`)
  - `sync/`: queued sync operations (`lib/core/sync/payment_sync_queue.dart`)
  - `theme/`: theme tokens/extensions/styles (`lib/core/theme/*`)
  - `widgets/`: reusable UI components (`lib/core/widgets/custom_bottom_nav_bar.dart`)
- `lib/features/`:
  - `auth/`
  - `subscriptions/`
  - `contacts/`
  - `settings/`
  - `home/` (presentation-focused composition over subscriptions data)

## Feature Module Skeleton
- Canonical module layout (implemented in `auth`, `subscriptions`, `contacts`, `settings`):
  - `data/datasources/`
  - `data/models/`
  - `data/repositories/`
  - `domain/entities/`
  - `domain/repositories/`
  - `domain/usecases/`
  - `domain/failures/` (present in most features except some auth pieces)
  - `presentation/providers/`
  - `presentation/screens/`
  - `presentation/widgets/`

## Key Locations by Concern
- Auth state and session lifecycle: `lib/features/auth/presentation/providers/auth_provider.dart`
- Subscription business orchestration: `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- Contacts CRUD flow: `lib/features/contacts/presentation/providers/contacts_provider.dart`
- Settings/theme persistence: `lib/features/settings/presentation/providers/settings_provider.dart`, `lib/features/settings/presentation/providers/theme_provider.dart`
- Bottom-nav tab selection state: `lib/features/subscriptions/presentation/providers/subscriptions_provider.dart`

## Naming Conventions
- Dart files use snake_case (for example `subscription_remote_datasource.dart`).
- Clean-architecture contract/implementation pairing:
  - contract: `.../domain/repositories/*_repository.dart`
  - implementation: `.../data/repositories/*_repository_impl.dart`
- Provider naming:
  - handwritten providers: `*_provider.dart`
  - generated counterparts: `*.g.dart`
- Immutable unions/entities:
  - source: `*.dart` with Freezed annotations
  - generated: `*.freezed.dart`
- Hive adapters:
  - model source in `data/models/*.dart`
  - generated adapters in `data/models/*.g.dart`

## Generated and Tooling Files
- Build config for generators: `build.yaml`
- Analyzer/lint policy: `analysis_options.yaml`
- Generated files are present next to sources in `lib/**` (`*.g.dart`, `*.freezed.dart`) and intentionally excluded from strict analyzer checks in `analysis_options.yaml`.

## Module Map (Responsibility View)
- Core runtime and infra:
  - `lib/main.dart`, `lib/core/config/*`, `lib/core/di/*`, `lib/core/storage/*`, `lib/core/supabase/*`
- Navigation and shell:
  - `lib/routing/app_router.dart`, `lib/core/presentation/app_shell.dart`, `lib/core/widgets/custom_bottom_nav_bar.dart`
- Domain-heavy features:
  - `lib/features/subscriptions/*`, `lib/features/settings/*`, `lib/features/contacts/*`, `lib/features/auth/*`
- Composition feature:
  - `lib/features/home/*` (renders dashboard sections from subscriptions providers)
- Database/migration layer outside Flutter:
  - `supabase/migrations/*`
- Test coverage surface:
  - `test/features/auth/*`, `test/features/subscriptions/*`, `integration_test/mark_payment_as_paid_test.dart`
