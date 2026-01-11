# Architectural Decisions Log (ADRs)

## Purpose
This document records all significant architectural and technical decisions made during SubMate development. Each ADR documents the context, decision, and consequences to help future developers understand **why** choices were made.

---

## Format
Each decision follows this structure:
- **ADR-XXX:** Title
- **Date:** YYYY-MM-DD
- **Status:** Proposed | Accepted | Rejected | Superseded
- **Context:** Why we faced this decision
- **Decision:** What we decided
- **Consequences:** Trade-offs and implications

---

## ADR-001: Clean Architecture Adoption
**Date:** 2024-12-15
**Status:** Accepted

**Context:**
SubMate will grow with many features (subscriptions, notifications, analytics, budgeting). We need a scalable architecture that:
- Separates business logic from UI
- Makes the app testable
- Allows swapping data sources (Hive → SQLite, Supabase → Firebase)
- Maintains long-termntainability

**Decision:**
Implement Clean Architecture with strict three-layer separation:
1. **Presentation Layer:** UI widgets, Riverpod providers, screens
   - Depends on Domain layer only
   - No business logic in widgets
2. **Domain Layer:** Pure Dart entities, use cases, repository interfaces
   - Zero dependencies on external frameworks
   - Only uses Freezed for immutability, Dartz for Either types
3. **Data Layer:** Repository implementations, data sources, DTOs, API clients
   - Implements domain repository interfaces
   - Handles Hive, Supabase, HTTP, etc.

**Consequences:**
✅ **Testability:** Business logic can be unit tested in isolation
✅ **Maintainability:** Clear boundaries prevent spaghetti code
✅ **Flexibility:** Easy to swap Hive for SQLite or Supabase for Firebase
✅ **Team collaboration:** Developers can work on layers independently
⚠️ **Boilerplate:** More files and interfaces compared to simple architecture
⚠️ **Learning curve:** Team must understand dependency invers **Initial slowdown:** Takes longer to set up initially

---

## ADR-002: Riverpod 2.0+ with Code Generation
**Date:** 2024-12-16
**Status:** Accepted

**Context:**
Need state management solution for SubMate that:
- Provides compile-time safety
- Handles async operations elegantly
- Supports dependency injection
- Has minimal boilerplate
- Integrates well with Clean Architecture

Alternatives considered:
- Provider (legacy, verbose)
- Bloc (too much boilerplate)
- GetX (anti-patterns, global state)
- MobX (less type-safe)

**Decision:**
Use Riverpod 2.0+ with `@riverpod` annotation for code generation instead of legacy providers (StateProvider, FutureProvider, etc.).

Key patterns:
- `@riverpod` for async data fetching
- `@riverpod` class-based for complex state (form management)
- Code generation for providers instead of manual creation
- AsyncValue for handling loading/data/error states

**Consequences:**
✅ **Type-safety:** Compile-time checks for provider usage (no runtime errors)
✅ **Auto-dispose:**viders automatically dispose when unused (no memory leaks)
✅ **Less boilerplate:** No manual provider creation, no .family/.autoDispose suffixes
✅ **Better DevTools:** Improved debugging experience with Riverpod Inspector
✅ **Testability:** Easy to mock providers in tests
⚠️ **Build runner dependency:** Requires `flutter pub run build_runner build`
⚠️ **Code generation time:** Adds ~5-10 seconds to build process
⚠️ **Migration cost:** Cannot easily switch to other state management later

**References:**
- Official Riverpod docs: https://riverpod.dev/
- Code generation guide: https://riverpod.dev/docs/concepts/about_code_generation

---

## ADR-003: Offline-First with Hive → Supabase Sync
**Date:** 2024-12-17
**Status:** Accepted

**Context:**
Users need SubMate to work without internet connection. Subscription data must:
- Be instantly accessible (no waiting for network)
- Persist locally for offline access
- Sync to cloud when online for backup and multi-device access
- Handle conflictstives considered:
- **Supabase-only:** Requires internet, slow on poor connections
- **Hive-only:** No backup, no multi-device sync
- **SQLite + Supabase:** More complex, similar to Hive
- **Firebase Firestore:** Offline support but vendor lock-in

**Decision:**
Implement offline-first architecture with Hive as primary storage and Supabase for sync:

**Read Strategy:**
1. Try to fetch from Supabase (ensures fresh data)
2. Cache response in Hive
3. On network error: fallback to Hive cache
4. Return data to UI immediately

**Write Strategy (Optimistic Updates):**
1. Save to Hive immediately (instant UI update)
2. Sync to Supabase in background
3. Update local Hive with server response (for server-generated IDs/timestamps)
4. On network error: queue for later sync (future enhancement)

**Consequences:**
✅ **Instant responsiveness:** No waiting for network, feels native
✅ **Offline support:** App fully functional without internet
✅ **Data durability:** Hive persists data even if app crashes or is uninstal**Multi-device sync:** Supabase enables syncing across devices
✅ **Backup:** Data backed up in cloud automatically
⚠️ **Sync complexity:** Need conflict resolution for concurrent updates (future)
⚠️ **Storage overhead:** Data duplicated in Hive + Supabase (~2x storage)
⚠️ **Consistency challenges:** Potential for stale data if sync fails silently
⚠️ **Implementation cost:** More complex than single data source

**Future Improvements:**
- Implement sync queue for offline changes
- Add conflict resolution (last-write-wins, user prompt, etc.)
- Add background sync with WorkManager/Isolates

---

## ADR-004: Freezed for Immutability
**Date:** 2024-12-18
**Status:** Accepted

**Context:**
Dart classes are mutable by default. For state management with Riverpod and Clean Architecture, we need:
- Immutable data classes (prevent accidental mutations)
- Value equality (compare objects by content, not reference)
- `copyWith` method (update objects functionally)
- Sealed classes for error handling (exatching)

Alternatives considered:
- **Manual immutability:** Too verbose, error-prone
- **Equatable:** Only equality, no copyWith or sealed classes
- **Built Value:** More complex than Freezed, overkill for our needs

**Decision:**
Use Freezed for all:
- Domain entities (`Subscription`, `SubscriptionMember`)
- DTOs/Models (`SubscriptionModel`, `MemberModel`)
- State classes (`SubscriptionFormState`, `HomeState`)
- Failure types (`SubscriptionFailure`, `AuthFailure`)

**Consequences:**
✅ **Immutability:** Prevents accidental state mutations (fewer bugs)
✅ **Value equality:** Easy to compare objects (`sub1 == sub2`)
✅ **copyWith:** Update objects functionally without mutating original
✅ **Sealed classes:** Exhaustive pattern matching for failures (compile-time safety)
✅ **toString:** Automatic readable string representation for debugging
✅ **JSON serialization:** Works with `json_serializable` (if needed)
⚠️ **Code generation:** Requires `build_runner` (~5-10s build time)
⚠️ **File size:*d.dart` files (~2x file count)
⚠️ **Learning curve:** Developers must understand immutability patterns

**Example:**
```dart
@freezed
class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String name,
    required double amount,
  }) = _Subscription;
}

// Usage
final sub = Subscription(id: '1', name: 'Netflix', amount: 15.99);
final updated = sub.copyWith(amount: 17.99); // Immutable update
```

---

## ADR-005: Supabase as Backend
**Date:** 2024-12-19
**Status:** Accepted

**Context:**
SubMate needs backend services for:
- User authentication (email/password, OAuth)
- Cloud database for multi-device sync
- Real-time subscriptions (future feature)
- File storage for receipts (future feature)

Alternatives considered:
- **Firebase:** Great offline support but more expensive, vendor lock-in
- **AWS Amplify:** Complex setup, steep learning curve
- **Self-hosted backend:** High maintenance, costly, slow to develop
- **Parse Server:** Outdated, small coity

**Decision:**
Use Supabase for backend services:
- **Authentication:** Email/password + OAuth (Google, Apple)
- **Database:** PostgreSQL with Row Level Security (RLS)
- **Storage:** For future receipt uploads
- **Edge Functions:** For future server-side logic (notifications, cron jobs)

**Consequences:**
✅ **No backend code:** Focus 100% on Flutter app
✅ **Built-in auth:** Email, OAuth, MFA ready out of the box
✅ **RLS policies:** Row-level security for multi-tenancy (users can only see their data)
✅ **PostgreSQL:** Powerful relational database (joins, indexes, transactions)
✅ **Real-time:** WebSocket subscriptions for live updates (future)
✅ **Open source:** Can self-host if needed (exit strategy)
✅ **Generous free tier:** 500MB database, 1GB file storage, 50K auth users
⚠️ **Vendor lock-in:** Migrating away would require significant effort
⚠️ **Cost scaling:** Paid plans scale with usage (pay-per-GB, pay-per-request)
⚠️ **Learning curve:** Need to learn RLS policies and Postt:** Edge Functions can have cold start latency (~1-2s)

**RLS Policy Example:**
```sql
CREATE POLICY "Users can only see their own subscriptions"
  ON subscriptions FOR SELECT
  USING (auth.uid() = owner_id);
```

---

## ADR-006: GoRouter for Navigation
**Date:** 2024-12-20
**Status:** Accepted

**Context:**
Need navigation solution for SubMate that supports:
- Type-safe route definitions
- Deep linking (future: open specific subscription from notification)
- Declarative routing
- Auth guards (redirect to login if not authenticated)

Alternatives considered:
- **Navigator 1.0:** Imperative, no deep linking, hard to test
- **Navigator 2.0 (raw):** Too complex, verbose
- **Auto Route:** Good but more boilerplate than GoRouter
- **Beamer:** Less popular, smaller community

**Decision:**
Use GoRouter with type-safe route definitions.

Key patterns:
- Define routes in single file (`lib/core/router/app_router.dart`)
- Use `GoRoute` with `path` and `builder`
- Use `redirect` for auth guards
- Use `extra` for passing complex objects

**Consequences:**
✅ **Type-safety:** Compile-time route validation (catch typos early)
✅ **Deep linking:** URLs map to screens automatically
✅ **Declarative:** Routes defined in one place, easy to visualize
✅ **Redirects:** Easy auth guards (`redirect: (context, state) => ...`)
✅ **Nested navigation:** Supports bottom nav, tabs, nested routes
✅ **Testing:** Easy to test navigation logic
⚠️ **Learning curve:** Different from Navigator 1.0 (push/pop)
⚠️ **Complexity:** Nested navigation requires careful route tree design
⚠️ **Breaking changes:** GoRouter API evolving (currently v14)

**Example:**
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/subscription/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SubscriptionDetailScreen(id: id);
      },
    ),
  ],
);
```

---

## ADR-007: Material 324-12-21
**Status:** Accepted

**Context:**
Need modern, accessible UI that follows latest design guidelines. SubMate is a personal finance app, so:
- Dark theme preferred (less eye strain, battery savings on OLED)
- Must follow Material Design for consistency with OS
- Must be accessible (contrast ratios, touch targets, etc.)

**Decision:**
Use Material 3 (Material You) with dark theme as primary, light theme as optional secondary.

Key choices:
- Use Material 3 components (`FilledButton`, `NavigationBar`, etc.)
- Dynamic color scheme based on user's OS theme (Android 12+)
- Dark theme as default
- Custom color seed for brand identity

**Consequences:**
✅ **Modern UI:** Latest design patterns, feels current
✅ **Accessibility:** Better contrast ratios, larger touch targets
✅ **Consistency:** Follows platform conventions (iOS/Android)
✅ **Dynamic colors:** Adapts to user's wallpaper (Android 12+)
✅ **Dark theme:** Less eye strain, battery savings
⚠️ **Widget changes:** Some M2 widgets deprecateion)
⚠️ **Theme complexity:** M3 theming more verbose than M2
⚠️ **iOS differences:** Material 3 feels less native on iOS (trade-off)

**Color Scheme:**
- **Primary:** Indigo (subscription management theme)
- **Secondary:** Teal (accent for actions)
- **Surface:** Dark gray (#121212 for true black OLED)

---

## ADR-008: Patrol for Integration Tests
**Date:** 2024-12-22
**Status:** Accepted

**Context:**
Need E2E tests for SubMate that can:
- Test complete user flows (signup → create subscription → view → edit → delete)
- Interact with native dialogs (permissions, camera, biometric auth)
- Run on real devices (not just simulators)
- Take screenshots for documentation

Alternatives considered:
- **Flutter integration_test:** Built-in, but can't interact with native dialogs
- **Appium:** Cross-platform, but heavy setup, slow
- **Detox:** React Native only
- **Manual testing:** Time-consuming, not repeatable

**Decision:**
Use Patrol for integration tests.

Key features:
- Native selector suppoow" button)
- Screenshot testing (golden tests)
- Runs on real devices and CI
- Flutter-native (fast execution)

**Consequences:**
✅ **Native interactions:** Can test permission dialogs, biometric prompts
✅ **Better selectors:** More reliable widget finding than vanilla integration_test
✅ **Screenshot testing:** Built-in golden test support
✅ **Real devices:** Tests work on physical iOS/Android devices
✅ **CI integration:** Works with GitHub Actions, Codemagic, etc.
⚠️ **Additional setup:** Need Patrol CLI installation
⚠️ **Smaller community:** Less popular than integration_test (fewer resources)
⚠️ **Maintenance:** Patrol API may evolve (breaking changes)

**Example:**
```dart
patrolTest('Create subscription flow', ($) async {
  await $.pumpWidgetAndSettle(const MyApp());
  await $(#createButton).tap();
  await $(#nameField).enterText('Netflix');
  await $(#saveButton).tap();
  expect($(TextContaining('Netflix')), findsOneWidget);
});
```

---

## ADR-009: Hive TypeAdapters for All Mo-23
**Status:** Accepted

**Context:**
Hive requires TypeAdapters for custom classes. Need strategy to:
- Avoid typeId conflicts (each adapter needs unique ID)
- Support schema evolution (adding/removing fields)
- Generate adapters efficiently

Alternatives considered:
- **Manual TypeAdapters:** Error-prone, verbose
- **No TypeAdapters:** Only supports primitives (too limiting)
- **Hive with JSON:** Slower, no type safety

**Decision:**
- Create TypeAdapter for every domain model
- Use centralized `HiveTypeIds` class for typeId management
- Generate adapters with `hive_generator` and `build_runner`
- Use `defaultValue` in `@HiveField` for backward compatibility

**TypeId Registry:**
```dart
class HiveTypeIds {
  static const int subscription = 0;
  static const int member = 1;
  static const int category = 2;
  // Add new IDs sequentially
}
```

**Consequences:**
✅ **Type-safety:** Compile-time checks for Hive models
✅ **No conflicts:** Centralized typeId prevents duplicate IDs
✅ **Versioning:** Can a fields with `defaultValue` annotation
✅ **Code generation:** Fast, automated adapter creation
⚠️ **Boilerplate:** Need adapter for each model (slight overhead)
⚠️ **Migration complexity:** Changing model structure requires careful handling
⚠️ **Build runner:** Adds dependency and build time

**Migration Example:**
```dart
// v1
@HiveField(0)
final String name;

// v2 (add optional field)
@HiveField(1, defaultValue: null)
final String? category;
```

---

## ADR-010: Agent-Driven Development with Specialized Sub-Agents
**Date:** 2025-01-10
**Status:** Accepted

**Context:**
SubMate features span multiple technical domains:
- Clean Architecture (3 layers with strict boundaries)
- Riverpod state management (code generation, async handling)
- Hive database (TypeAdapters, encryption, lifecycle)
- Supabase integration (RLS, schemas, sync)
- Material 3 UI (composition, accessibility)
- Testing (unit, widget, Patrol integration)

Coordinating all this complexity is challenging. Need system to:
- Ensu across features
- Enforce architectural patterns
- Catch issues early (before production)
- Speed up development with templates

**Decision:**
Implement AI agent system with specialized sub-agents stored in `.claude/agents/`:

**Main Coordinators:**
- **Flutter Feature Architect** - Orchestrates feature development across layers
- **Flutter DevOps & Quality Guardian** - Ensures code quality, CI/CD, audits

**18+ Sub-agents (specialized executors):**
- @domain-layer-specialist
- @data-layer-specialist
- @riverpod-state-architect
- @ui-component-builder
- @hive-database-auditor
- @supabase-integration-specialist
- @patrol-test-engineer
- @performance-auditor
- @clean-architecture-validator
- @security-auditor
- And more...

Each sub-agent has:
- Defined responsibilities
- Code templates
- Validation checklists
- Best practices

**Consequences:**
✅ **Consistency:** Standardized patterns across all features
✅ **Quality:** Automated checks catch issues before production
✅ **Speed:** Templates and workflowlerate development
✅ **Documentation:** Agents document decisions and patterns automatically
✅ **Knowledge transfer:** New developers learn from agent specifications
✅ **Scalability:** Easy to add new specialized agents as needs grow
⚠️ **Learning curve:** Team must understand agent prompting patterns
⚠️ **Context switching:** Coordinating multiple agents adds overhead
⚠️ **Dependency:** Reliant on AI quality (Claude, GPT-4, etc.)
⚠️ **Maintenance:** Agent specs must be updated as tech evolves

**Workflow Example:**
```
User: "Implement Edit Subscription feature"
  ↓
Flutter Feature Architect:
  → Calls @domain-layer-specialist (use case design)
  → Calls @data-layer-specialist (Hive + Supabase)
  → Calls @riverpod-state-architect (providers)
  → Calls @ui-component-builder (Material 3 UI)
  → Calls @patrol-test-engineer (tests)
  ↓
Flutter DevOps & Quality Guardian:
  → Validates with @code-quality-inspector
  → Audits with @hive-database-auditor
  → Checks with @sion-ready code ✅
```

**References:**
- Agent specs: `.claude/agents/`
- Coordinator: `.claude/agents/flutter-feature-architect.md`
- Quality guardian: `.claude/agents/flutter-devops-quality-guardian.md`

---

## ADR-011: BMAD Method v6 Integration
**Date:** 2025-01-11
**Status:** Accepted

**Context:**
Development sessions are often interrupted (days or weeks between coding). Without context persistence:
- Lose track of what's completed vs pending
- Forget why architectural decisions were made
- Repeat planning work from scratch
- No clear roadmap of what's next

Agent system (ADR-010) handles **execution** well, but doesn't provide **context persistence**.

**Decision:**
Integrate BMAD Method v6 for structured context management:

**Core Files:**
1. `PROJECT_CONTEXT.md` - Immutable project overview (tech stack, architecture, principles)
2. `CURRENT_STATE.md` - Mutable state (features ✅🚧📋, test coverage, performance)
3. `NEXT_STEPS.md` - Prioritized roadmap (what's next, dependencies, estimates)
SIONS_LOG.md` - ADRs (architectural decisions with rationale)

**Integration with Agent System:**
- BMAD provides **WHAT** and **WHY** (context, decisions, roadmap)
- Agents provide **HOW** (execution, templates, validation)

**Workflow:**
```
Session Start:
  → Read CURRENT_STATE.md (where am I?)
  → Read NEXT_STEPS.md (what's next?)
  → Read DECISIONS_LOG.md (why this approach?)
  ↓
Development:
  → Use agents to implement (Feature Architect + sub-agents)
  ↓
Session End:
  → Update CURRENT_STATE.md (move feature to ✅)
  → Update NEXT_STEPS.md (mark completed, promote next)
  → Update DECISIONS_LOG.md (add ADR if needed)
  → Commit: git commit -m "docs(bmad): Update context"
```

**Consequences:**
✅ **Continuity:** Perfect context between sessions (no mental reload)
✅ **Traceability:** All decisions documented with rationale
✅ **Onboarding:** New developers understand project in 15 minutes
✅ **Hybrid approach:** BMAD context + agent execution = best of both
✅ **Time savingst to coding
⚠️ **Discipline required:** Must update files after each feature (easy to forget)
⚠️ **Maintenance overhead:** 4 files to keep synchronized
⚠️ **Overkill for small projects:** Best suited for medium-large projects
⚠️ **Learning curve:** Team must adopt BMAD workflow

**Example Benefit:**
```
Without BMAD:
  - Open project after 2 weeks
  - Spend 30 mins remembering what's done
  - Re-read code to understand architecture
  - Start coding

With BMAD:
  - Open project after 2 weeks
  - Read CURRENT_STATE.md (2 mins)
  - Read NEXT_STEPS.md (1 min)
  - Start coding immediately ✅
```

**References:**
- BMAD docs: https://docs.bmad-method.org/
- Integration guide: `.claude/bmad-integration.md`
- Context files: `_bmad-output/planning-artifacts/`

---

## Template for New ADRs
```markdown
## ADR-XXX: [Title]
**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Rejected | Superseded

**Context:**
[Describe the problem/situation that requires a decision]
[What alternatives were considerints exist?]

**Decision:**
[What did we decide?]
[How will it be implemented?]
[What are the key technical details?]

**Consequences:**
✅ **Benefit 1:** [Specific advantage]
✅ **Benefit 2:** [Another advantage]
⚠️ **Trade-off 1:** [What we're sacrificing]
⚠️ **Trade-off 2:** [Another compromise]
❌ **Drawback (if any):** [Significant downside]

**References:**
- [Link to docs, PRs, discussions, etc.]
```

---

## Status Legend
- **Proposed:** Decision suggested but not yet approved
- **Accepted:** Decision approved and implemented
- **Rejected:** Decision considered but rejected (keep for historical context)
- **Superseded:** Decision replaced by newer ADR (reference the new one)

---

## How to Add New ADRs

1. **Identify the need:** When making a significant technical/architectural decision
2. **Assign number:** Use next sequential number (ADR-012, ADR-013, etc.)
3. **Write ADR:** Use template above
4. **Get feedback:** Discuss with team or AI agents
5. **Mark status:** Proposed → Acceptedommit:** `git add DECISIONS_LOG.md && git commit -m "docs(adr): Add ADR-XXX [title]"`

---

## Cross-References

Related ADRs often inform each other:
- ADR-001 (Clean Arch) informs ADR-002 (Riverpod) and ADR-010 (Agents)
- ADR-003 (Offline-first) depends on ADR-005 (Supabase) and ADR-009 (Hive)
- ADR-010 (Agents) complements ADR-011 (BMAD)

When writing new ADRs, reference related ones for context.
