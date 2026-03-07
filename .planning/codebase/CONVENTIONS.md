# CONVENTIONS

## Scope
This document captures conventions observed in the current Flutter codebase, based on implementation in `lib/` and project tooling configs.

## Language, Lints, and Tooling Baseline
- Project is Dart + Flutter with SDK constraint in `pubspec.yaml` (`>=3.4.0 <4.0.0`).
- Lint baseline extends `flutter_lints` in `analysis_options.yaml`.
- Lint policy is strict and explicit in `analysis_options.yaml` (for example: `always_use_package_imports`, `always_declare_return_types`, `prefer_single_quotes`, `file_names`, `curly_braces_in_flow_control_structures`, `unawaited_futures`).
- Analyzer excludes generated code (`**/*.g.dart`, `**/*.freezed.dart`) and upgrades selected analyzer issues to errors (`missing_return`, `missing_required_param`, `invalid_annotation_target`).
- Code generation is part of the workflow via `build.yaml` (`riverpod_generator`, `freezed`, `hive_generator`).

## Architecture and Module Boundaries
- Primary structure follows feature-based Clean Architecture under `lib/features/<feature>/{data,domain,presentation}`.
- Cross-cutting code sits in `lib/core/` (DI, storage, config, sync, theming, shared widgets).
- App entrypoints and composition are centralized in `lib/main.dart`, `lib/core/di/injection.dart`, and `lib/routing/app_router.dart`.
- Repositories generally expose domain contracts in `domain/repositories` and implementations in `data/repositories` (for example `lib/features/subscriptions/domain/repositories/subscription_repository.dart` + `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`).
- Data models map between domain entities and transport/storage representations using `fromEntity`/`toEntity` and JSON methods (for example `lib/features/subscriptions/data/models/subscription_model.dart`).

## Naming and File Organization
- File names use `snake_case` per lint policy (`file_names`) and observed file naming across `lib/`.
- Types use `UpperCamelCase`; members use `lowerCamelCase`; constants commonly use `static const`.
- Generated artifacts are colocated with source and referenced through `part` directives (for example `part 'settings_provider.g.dart';`, `part 'user.freezed.dart';`).
- Provider naming follows behavior-oriented patterns: query providers (`monthlyStatsProvider`), mutation notifiers (`paymentActionProvider`), and feature form providers (`createGroupSubscriptionFormProvider`).

## State Management Patterns
- Riverpod is the main state model, with mixed but intentional usage:
- `@riverpod`/`@Riverpod` codegen providers for most async/domain-facing flows (examples: `lib/features/subscriptions/presentation/providers/subscriptions_provider.dart`, `lib/features/settings/presentation/providers/settings_provider.dart`).
- Manual `StateNotifierProvider` remains in auth (`lib/features/auth/presentation/providers/auth_provider.dart`).
- `keepAlive: true` is used for long-lived providers that require pre-initialized instances from `main.dart` overrides (for example local datasources in `lib/core/di/injection.dart`).
- UI observes `AsyncValue` using `.when(...)` and invalidates dependent providers after mutations (`ref.invalidate(...)`), seen in `payment_provider.dart` and form providers.

## Error Handling Conventions
- Domain/repository contract style is primarily functional: `Future<Either<Failure, T>>` (`dartz`) across use cases and repositories.
- Failure types are modeled as sealed unions with Freezed in several features (for example `lib/features/subscriptions/domain/failures/subscription_failure.dart`, `lib/features/contacts/domain/failures/contact_failure.dart`, `lib/features/settings/domain/failures/settings_failure.dart`).
- Auth feature is an exception: it uses class-based failures in `lib/features/auth/domain/repositories/auth_repository.dart`.
- Data layer catches backend/storage exceptions and maps them into domain failures; subscriptions and contacts include offline/cache fallbacks in repository implementations.
- Presentation providers convert failures into `AsyncValue` errors or explicit state unions, then surface UI feedback (SnackBars, retry states).

## Offline-First and Persistence Conventions
- Local persistence uses Hive (`lib/core/storage/hive_service.dart`) and feature local datasources.
- Remote integration uses Supabase (`lib/core/supabase/supabase_service.dart`, feature remote datasources).
- Subscriptions repository uses optimistic local updates + remote sync fallback queue (`lib/core/sync/payment_sync_queue.dart`, `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`).
- App startup enforces ordered initialization: env, Supabase, Hive, datasource instances, then `ProviderScope` overrides (`lib/main.dart`).

## UI and Presentation Style Tendencies
- Current visual style is heavily custom dark-theme with explicit colors and gradients in widgets/screens (`lib/features/home/presentation/widgets/active_subscriptions_section.dart`, `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`).
- Presentation code frequently includes descriptive debug logs and UX-focused inline comments.
- `withValues(alpha: ...)` is used instead of deprecated opacity patterns in updated code.

## Notable Inconsistencies to Keep in Mind
- Riverpod style is mixed between generated notifiers and manual `StateNotifier` (auth).
- Integration-test docs assume semantic keys, but current production widgets largely do not expose those keys (for example `subscription_detail_screen.dart`, `payment_status_toggle.dart`, `payment_action_buttons.dart`).
- Some TODO placeholders remain in presentation/repository flows (delete subscription action, analytics sections, export services).
