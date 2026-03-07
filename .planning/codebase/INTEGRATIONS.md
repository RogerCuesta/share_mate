# INTEGRATIONS

## Overview
- Primary external platform is Supabase, wired through `supabase_flutter` and initialized in `lib/core/supabase/supabase_service.dart`.
- Integration boot order is explicit in `lib/main.dart`: `EnvConfig.load()` -> `SupabaseService.init()` -> local storage init.

## External APIs And Services

### Supabase Auth
- User registration/login/logout via Supabase Auth in `lib/features/auth/data/datasources/auth_remote_datasource.dart`.
- Account management via Supabase Auth in `lib/features/settings/data/datasources/account_remote_datasource.dart`:
- password updates (`auth.updateUser`)
- email verification resend (`auth.resend`)
- account deletion (`auth.admin.deleteUser`)
- Required credentials are read from env keys in `lib/core/config/env_config.dart` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`; service role key also supported).

### Supabase Postgres (Tables Used By App Code)
- `contacts` table CRUD from `lib/features/contacts/data/datasources/contact_remote_datasource.dart`.
- `profiles` table read/update from `lib/features/settings/data/datasources/profile_remote_datasource.dart`.
- `subscriptions`, `subscription_members`, `payment_history` from `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`.
- Schema and RLS rules are versioned in `supabase/migrations/*.sql`.

### Supabase RPC Functions
- Atomic payment mark RPC: `mark_payment_as_paid_atomic` used in `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`.
- Atomic payment unmark RPC: `unmark_payment_atomic` used in `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`.
- Payment stats RPC: `get_payment_history_stats` used in `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`.
- Related SQL definitions live in `supabase/migrations/20251225_payment_history_enhancements.sql` (and other migration files).

### Supabase Storage
- Avatar upload/delete/public URL generation through Supabase Storage bucket `avatars` in `lib/features/settings/data/datasources/profile_remote_datasource.dart`.
- Bucket + storage RLS policy setup is defined in `supabase/migrations/20251228_profiles_and_avatars.sql`.

## Databases And Persistence

### Remote Database
- Supabase Postgres is the remote DB system, with app-facing table access from data sources in `lib/features/**/data/datasources/*remote*.dart`.

### Local Database/Cache
- Hive CE is used for local persistence in `lib/core/storage/hive_service.dart`.
- Encrypted Hive boxes are used for auth, contacts, settings, and profiles in:
- `lib/features/auth/data/datasources/user_local_datasource.dart`
- `lib/features/contacts/data/datasources/contact_local_datasource.dart`
- `lib/features/settings/data/datasources/profile_local_datasource.dart`
- `lib/features/settings/data/datasources/settings_local_datasource.dart`
- Hive type IDs are centrally managed in `lib/core/storage/hive_type_ids.dart`.

## Auth Providers
- Active provider: Supabase email/password auth (`signUp`, `signInWithPassword`) in `lib/features/auth/data/datasources/auth_remote_datasource.dart`.
- No Google/Apple/Firebase auth provider implementation is present in `lib/`.

## Secure Storage And Secrets Handling
- `flutter_secure_storage` stores auth session payload (`auth_session`) in `lib/features/auth/data/datasources/auth_local_datasource.dart`.
- `flutter_secure_storage` also stores Hive AES key (`hive_master_encryption_key`) in `lib/core/storage/hive_service.dart`.
- Secrets are configured in `.env` and excluded from VCS by `.gitignore`.

## Third-Party SDKs And Platform Plugins
- URL launching integration in `lib/features/settings/presentation/screens/settings_screen.dart` using `url_launcher`.
- App metadata integration in `lib/features/settings/presentation/screens/settings_screen.dart` using `package_info_plus`.
- Charting SDK `fl_chart` used in `lib/features/subscriptions/presentation/widgets/analytics/spending_distribution_chart.dart`.
- Image processing via `package:image` in `lib/features/settings/data/repositories/profile_repository_impl.dart`.
- Registered platform plugins are visible in generated files (`ios/Runner/GeneratedPluginRegistrant.m`, `.flutter-plugins-dependencies`), including `app_links`, `flutter_secure_storage`, `url_launcher`, `package_info_plus`, `image_picker`, `sqflite`, `shared_preferences`.

## Declared But Not Yet Wired In App Layer
- `dio` is declared in `pubspec.yaml` but no imports/usages were found under `lib/`.
- `image_picker` and `cached_network_image` are declared in `pubspec.yaml`, but no direct imports were found under `lib/` at this snapshot.
- Firebase SDK integration files are not present (no `google-services.json` / `GoogleService-Info.plist` checked in; only ignore rules in `.gitignore`).
