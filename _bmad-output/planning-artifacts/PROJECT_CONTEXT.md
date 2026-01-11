# SubMate - Subscription Management App

## Vision
Mobile-first subscription tracking application with personal and group subscription management, built with offline-first architecture using Flutter and Clean Architecture.

## Tech Stack
- **Frontend:** Flutter 3.x with Material 3
- **Architecture:** Clean Architecture (Presentation/Domain/Data)
- **State Management:** Riverpod 2.0+ with Code Generation (@riverpod)
- **Local DB:** Hive (offline-first storage)
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **Navigation:** GoRouter with type-safe routes
- **Immutability:** Freezed for all domain models and DTOs
- **Testing:** Patrol for integration/E2E tests

## Core Features
1. ✅ Authentication (Email/Password + OAuth via Supabase)
2. ✅ Personal Subscriptions CRUD
3. ✅ Group Subscriptions with dynamic member management
4. ✅ Automatic split bill calculations
5. ✅ Dashboard with analytics and statistics
6. ✅ Subscriptiow
7. 🚧 Edit Subscription (In Progress)
8. 📋 Delete Subscription (Planned)
9. 📋 Notification System (Planned)

## Architecture Principles
- Strict layer separation (Presentation → Domain ← Data)
- Repository pattern for data access
- Use Cases for business logic encapsulation
- Immutable state with Freezed
- Type-safe error handling (Either<Failure, Success>)
- Offline-first: Hive as primary source, Supabase for sync

## Quality Standards
- 80%+ test coverage (unit, widget, integration)
- Zero `dynamic` types
- Automated QA reports via Claude Code
- Performance monitoring (60fps, <16ms frame render)
- RLS policies on all Supabase tables
- Hive encryption for sensitive data

## Development Workflow
1. Design feature with Flutter Feature Architect agent
2. Implement offline-first with Hive (LocalDataSource + TypeAdapters)
3. Add Supabase integration for sync (RemoteDataSource)
4. Create Riverpod providers with code generation
5. Build Material 3 UI with composition
6. Write Patrol tests (unit + in
7. Run QA audits with DevOps Guardian agent
8. Update BMAD context files

## Project Structure
```
lib/
├── core/
│   ├── di/              # Dependency injection (Riverpod providers)
│   ├── storage/         # Hive initialization and encryption
│   ├── network/         # Supabase client setup
│   └── utils/           # Shared utilities
├── features/
│   ├── auth/
│   │   ├── domain/      # Entities, use cases, repository interfaces
│   │   ├── data/        # Repository impl, data sources, models
│   │   └── presentation/# Screens, widgets, providers
│   ├── subscriptions/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   └── home/
│       ├── domain/
│       ├── data/
│       └── presentation/
└── main.dart
```

## Active Development Agents
- **Flutter Feature Architect** - Coordinates feature development across layers
- **Flutter DevO - data-layer-specialist
  - riverpod-state-architect
  - ui-component-builder
  - hive-database-auditor
  - supabase-integration-specialist
  - patrol-test-engineer
  - performance-auditor
  - clean-architecture-validator
  - security-auditor
  - And more...

## External Resources
- **GitHub:** Private repository
- **Supabase Project:** Production database
- **Design System:** Material 3 dark theme
- **Documentation:** `.claude/agents/` for agent specifications

## Development Environment
- **IDE:** VSCode / Android Studio
- **Flutter SDK:** Latest stable channel
- **Dart SDK:** Latest stable
- **Platforms:** iOS (13.0+) and Android (23+)

## Key Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  supabase_flutter: ^2.5.6
  freezed_annotation: ^2.4.1
  dartz: ^0.10.1
  go_router: ^14.0.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.8
  freezed: ^2.4.7
  hive_generator: ^2.0.1
  patrol: ^3.6.1
```
