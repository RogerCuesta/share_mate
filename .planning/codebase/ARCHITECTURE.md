# Architecture

## Overview
- The app follows a feature-oriented Clean Architecture style under `lib/features/*` with `data`, `domain`, and `presentation` layers.
- Global cross-cutting concerns live in `lib/core/*` (configuration, storage, DI, theming, shared widgets, sync utilities).
- Runtime composition is done with Riverpod providers in `lib/core/di/injection.dart` and feature providers in `lib/features/*/presentation/providers/*`.
- Navigation is centralized in `lib/routing/app_router.dart` using GoRouter and auth-aware redirects.

## Entry Points
- App bootstrap: `lib/main.dart`
- Router composition and route guards: `lib/routing/app_router.dart`
- Dependency graph and use-case providers: `lib/core/di/injection.dart`
- App shell + primary tabbed container: `lib/core/presentation/app_shell.dart`
- Native platform entry wrappers: `android/`, `ios/`

## Layering Pattern
- Presentation layer:
  - Screens/widgets: `lib/features/*/presentation/screens/*`, `lib/features/*/presentation/widgets/*`
  - State and async orchestration: `lib/features/*/presentation/providers/*`
- Domain layer:
  - Business entities and rules: `lib/features/*/domain/entities/*`
  - Failure models: `lib/features/*/domain/failures/*`
  - Use-case API: `lib/features/*/domain/usecases/*`
  - Repository contracts: `lib/features/*/domain/repositories/*`
- Data layer:
  - Repository implementations: `lib/features/*/data/repositories/*_impl.dart`
  - Remote/local datasources: `lib/features/*/data/datasources/*`
  - DTO/model conversion: `lib/features/*/data/models/*`

## Data Flow
- Startup flow:
  - `lib/main.dart` initializes `.env` via `lib/core/config/env_config.dart`, Supabase via `lib/core/supabase/supabase_service.dart`, and Hive via `lib/core/storage/hive_service.dart`.
  - Initialized singleton datasources are injected via `ProviderScope` overrides in `lib/main.dart`.
- Auth flow:
  - UI/provider (`lib/features/auth/presentation/providers/auth_provider.dart`) -> use cases (`lib/features/auth/domain/usecases/*`) -> repository (`lib/features/auth/data/repositories/auth_repository_impl.dart`) -> remote/local datasources.
  - Router guard in `lib/routing/app_router.dart` reads `authProvider` state to redirect between `/`, `/login`, `/register`, and `/app`.
- Subscription flow (offline-first):
  - Providers in `lib/features/subscriptions/presentation/providers/*` call use cases from `lib/core/di/injection.dart`.
  - Repository `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart` prefers remote (`subscription_remote_datasource.dart`) and falls back to local cache (`subscription_local_datasource.dart`).
  - Payment sync queue models/services live in `lib/core/sync/payment_sync_queue.dart`.

## Boundaries
- UI boundary:
  - Only presentation providers/screens should touch Flutter widgets directly (`lib/features/*/presentation/*`).
- Domain boundary:
  - Domain layer depends on abstractions and entities, not concrete storage/transport.
- Infrastructure boundary:
  - Supabase client access is centralized through `lib/core/supabase/supabase_service.dart` and exposed by providers in `lib/core/di/injection.dart`.
  - Local persistence (Hive + secure storage) is centralized in `lib/core/storage/hive_service.dart` and feature local datasources.
- Generated code boundary:
  - Riverpod/Freezed/Hive generated artifacts (`*.g.dart`, `*.freezed.dart`) are companions to handwritten sources and excluded from analyzer config in `analysis_options.yaml`.

## Architectural Characteristics
- State management: Riverpod (`flutter_riverpod`, `riverpod_annotation`) with mixed `StateNotifier` and generated `@riverpod` patterns.
- Error model: functional `Either` from `dartz` in repositories/use cases plus typed failure unions in domain.
- Offline behavior: auth and subscriptions include explicit network-fallback logic in repository implementations.
- Multi-feature shell: `lib/core/presentation/app_shell.dart` hosts Home, Contacts, Analytics, and Settings tabs backed by feature providers.

## External Systems
- Backend/API and auth: Supabase (`supabase_flutter`) configured from `.env`.
- Local persistence: Hive CE boxes and adapters (`lib/core/storage/hive_service.dart`, `lib/core/storage/hive_type_ids.dart`).
- Secure secrets/session storage: `flutter_secure_storage` used by auth/local storage services.
- Database schema evolution: SQL migrations in `supabase/migrations/*`.

## Verification Surfaces
- Unit/widget tests: `test/features/*`
- Integration test harness/docs: `integration_test/*`
- One concrete end-to-end scenario: `integration_test/mark_payment_as_paid_test.dart`
