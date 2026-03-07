# STACK

## Snapshot
- Project root analyzed: `/Users/rogerpersonal/Documents/Proyectos Personales/share_mate`
- Primary app target: Flutter mobile app (`android/`, `ios/`) with feature modules under `lib/features/`.

## Languages And Runtime
- Dart is the main application language (`lib/`), constrained by `environment.sdk: ">=3.4.0 <4.0.0"` in `pubspec.yaml`.
- SQL is used for backend schema/migrations in `supabase/migrations/*.sql`.
- Kotlin DSL is used for Android build configuration in `android/build.gradle.kts`, `android/app/build.gradle.kts`, `android/settings.gradle.kts`.
- Swift is used for iOS app entrypoint in `ios/Runner/AppDelegate.swift`.
- Ruby (CocoaPods) is used in `ios/Podfile`.
- Flutter runtime/bootstrap is in `lib/main.dart` with `WidgetsFlutterBinding.ensureInitialized()`.

## Frameworks And Architectural Style
- Flutter UI framework + Material 3 theme setup in `lib/core/theme/app_theme.dart` and `lib/main.dart`.
- Clean Architecture-style feature separation (`data/domain/presentation`) under `lib/features/auth/`, `lib/features/subscriptions/`, `lib/features/contacts/`, `lib/features/settings/`.
- Riverpod + code generation for DI/state (`lib/core/di/injection.dart`, generated `lib/core/di/injection.g.dart`).
- GoRouter for navigation and routing in `lib/routing/app_router.dart`.
- Immutable/value models via Freezed (`*.freezed.dart` across `lib/features/**/domain/entities/`).

## Dependency Stack (pubspec)
- Core dependencies declared in `pubspec.yaml`:
- `flutter_riverpod`, `riverpod_annotation` (state management + DI)
- `freezed_annotation`, `dartz` (immutability + functional error handling)
- `hive_ce`, `hive_ce_flutter`, `flutter_secure_storage` (local persistence/security)
- `supabase_flutter` (backend/auth/database/storage client)
- `go_router` (navigation)
- `intl` (formatting/i18n utilities)
- `fl_chart` (analytics charts)
- `package_info_plus`, `url_launcher` (platform metadata + external links)
- `crypto`, `uuid`, `image` (hashing, IDs, image processing)
- Also declared but currently not imported in `lib/`: `dio`, `image_picker`, `cached_network_image`.

## Configuration And Environment
- Runtime environment variables are loaded from `.env` via `flutter_dotenv` in `lib/core/config/env_config.dart`.
- Required keys validated at startup: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (`lib/core/config/env_config.dart`).
- `.env` is bundled as a Flutter asset (`pubspec.yaml`) and ignored by Git (`.gitignore`).
- Static analysis/lint policy is configured in `analysis_options.yaml` (very strict lint set + generated-file excludes).
- Build/codegen behavior is configured in `build.yaml`:
- `riverpod_generator` with `auto_dispose: true`
- `freezed` with `union_key: type`
- `hive_generator` enabled

## Code Generation And Artifacts
- Build runner pipeline is expected (`README.md`, `QUICKSTART.md`).
- Generated artifacts present and committed in `lib/**` (examples: `lib/hive_registrar.g.dart`, `lib/features/**.g.dart`, `lib/features/**.freezed.dart`).
- DevTools extension config exists in `devtools_options.yaml`.

## Build Toolchain
- Android build uses AGP `8.7.0` and Kotlin plugin `1.8.22` in `android/settings.gradle.kts`.
- Android Java/Kotlin target is 11 in `android/app/build.gradle.kts`.
- Android SDK versions are inherited from Flutter (`compileSdk`, `minSdk`, `targetSdk`) in `android/app/build.gradle.kts`.
- iOS build uses CocoaPods + Flutter pod helper in `ios/Podfile`.
- Plugin registration is via generated files (`ios/Runner/GeneratedPluginRegistrant.m`, `android` embedding v2 in `android/app/src/main/AndroidManifest.xml`).

## Test And Quality Tooling
- Unit/widget tests are under `test/` (many auth/subscriptions tests).
- Integration/E2E tests use Patrol under `integration_test/` (e.g., `integration_test/mark_payment_as_paid_test.dart`).
- Documented commands in `README.md` and `QUICKSTART.md`:
- `flutter analyze`
- `flutter test` / `flutter test --coverage`
- `patrol test integration_test/mark_payment_as_paid_test.dart`
- No CI workflow files are currently present under `.github/workflows`.
