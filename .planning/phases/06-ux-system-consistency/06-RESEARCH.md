# Phase 6 Research: UX System Consistency

## Scope Lock

Phase 6 should unify the existing MVP surfaces visually without changing product scope, data flow, or interaction semantics. The locked source of truth is [`.planning/phases/06-ux-system-consistency/06-CONTEXT.md`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/.planning/phases/06-ux-system-consistency/06-CONTEXT.md): evolved dark fintech direction, medium-high contrast, restrained decorative accents, compact guided forms, summary-first detail, and shared components.

This is a presentation-system refactor phase, not a feature phase.

## Current State Summary

The codebase already has the right architectural seam for a system refactor, but the seam is underused:

- [`lib/core/theme/app_theme.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/core/theme/app_theme.dart) centralizes `ThemeData`, but most critical screens bypass it with local `Color`, `TextStyle`, `BoxDecoration`, and dialog/button styling.
- [`lib/core/theme/theme_extensions.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/core/theme/theme_extensions.dart) exposes gradients, shadows, radii, spacing, and blur, but not semantic surface roles, state colors, component variants, or density tokens.
- [`lib/features/home/presentation/screens/home_screen.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/features/home/presentation/screens/home_screen.dart) already respects the Phase 4 hierarchy (debt first), but uses local screen background, placeholder, error, and snackbar styling.
- [`lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart) is the main density outlier: one long screen, repeated field styling, local date picker theme, local CTA treatment, and multiple ad-hoc surfaces.
- [`lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart) contains the largest concentration of duplicated card language, badges, chips, dialogs, and status treatments. It is the clearest target for summary-first consolidation.
- [`lib/features/subscriptions/presentation/widgets/billing_cycle_selector.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/features/subscriptions/presentation/widgets/billing_cycle_selector.dart) and [`lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart) are high-value extraction candidates, but both are still visually local.

## MASTER.md vs Locked Phase 6 Direction

There is a real source-of-truth conflict.

[`design-system/share-mate/MASTER.md`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/design-system/share-mate/MASTER.md) persists a light, blue/orange, generic, landing-style system generated for a "Mental Health App". That conflicts with all locked Phase 6 decisions:

- `MASTER.md` pushes light backgrounds and blue/orange CTA language.
- Phase 6 explicitly locks a dark fintech evolution.
- `MASTER.md` describes generic single-column/landing patterns that do not map to the app's transactional mobile surfaces.
- The repo currently has no `design-system/share-mate/pages/*` overrides, so `MASTER.md` would mislead future implementation if treated literally.

Planning should reconcile this explicitly:

1. Treat Phase 6 context as authoritative for all core app surfaces in this phase.
2. Treat the current `MASTER.md` as stale design documentation, not as implementation truth.
3. Add an early planning task to update persisted design-system docs so the post-phase source of truth matches the implemented dark system.
4. Prefer one of these reconciliation paths:
   - Replace `MASTER.md` with the dark transactional system after Phase 6 foundations are agreed.
   - Or create page/app-surface overrides first, then collapse them back into `MASTER.md` once the system stabilizes.
5. Do not spend Phase 6 implementing the current light `MASTER.md`; that would violate locked context and create avoidable churn.

The `ui-ux-pro-max` skill output is directionally useful only for confirming "dark, trustworthy, high-readability fintech". Its landing/page-pattern suggestions are not appropriate as a direct implementation template for this Flutter app.

## Recommended System Direction

Use the existing dark foundation as the baseline and evolve it into a stricter semantic system:

- Backgrounds: deep dark canvas with clearer separation between app background, base cards, elevated cards, and accent surfaces.
- Contrast: medium-high, with readable text/body/supporting tiers and visible borders on dark surfaces.
- Accent usage: reserve gradients and stronger chroma for KPI hero surfaces, primary CTA emphasis, and selected states only.
- Density: reduce vertical sprawl in forms and secondary sections; keep section rhythm tighter and more consistent.
- Hierarchy: strong first fold on Home and Detail; guided grouped sections on Create/Split.
- Reuse: one shared language for cards, badges, feedback, dialogs, sheets, selectors, and CTA variants.

## Tokens To Extract First

Planner priority should be semantic tokens, not more raw colors.

### 1. Surface Tokens

Extend the theme layer with semantic roles such as:

- `screenBackground`
- `surfaceBase`
- `surfaceRaised`
- `surfaceSubtle`
- `surfaceAccent`
- `surfaceDanger`
- `surfaceSuccess`
- `borderSubtle`
- `borderStrong`
- `divider`

This is the main missing layer today. Current screens repeatedly hardcode `0xFF0D0D1E`, `0xFF1A1A2E`, `0xFF1E1E2D`, `0xFF2A2A3E`, `0xFF2D2D44`, and `0xFF3D3D54` instead of describing intent.

### 2. Content Tokens

Add semantic text/icon roles beyond default `onSurface`:

- `textPrimary`
- `textSecondary`
- `textTertiary`
- `textInverse`
- `iconPrimary`
- `iconMuted`

This matters because the code currently uses `Colors.white`, `Colors.white70`, and `Colors.grey[300/400/600]` interchangeably across screens.

### 3. Feedback and Status Tokens

Centralize status semantics used in sync/payment/subscription state:

- `info`
- `success`
- `warning`
- `error`
- badge background/border/content variants for synced, pending, requires-action, active, paused, cancelled

These are currently scattered across detail, snackbars, badges, and dialogs.

### 4. Density Tokens

Add compact layout constants for core mobile flows:

- section spacing (`12/16/24` roles, not raw values everywhere)
- card padding roles (`compact`, `standard`, `hero`)
- field gap roles
- control heights for pills, chips, buttons, and rows

Phase 6 requires screens to feel like one density system, not just one color palette.

### 5. Component-Specific Tokens

Add tokens for:

- form fill/border/focus/error states
- CTA variants (`primary`, `secondary`, `ghost/destructive`)
- dialog and bottom sheet surface treatment
- summary hero gradient or accent treatment
- operational snackbar/banner treatment

If `AppThemeExtension` becomes too broad, split it into multiple theme extensions by concern instead of keeping one oversized extension.

## Shared Components To Extract

These extractions give the highest consistency return with the lowest product risk.

### Core Primitives

- `AppScreenScaffold` or equivalent screen shell for dark background, safe padding, scroll padding, and bottom CTA spacing.
- `AppSectionCard` with variants like `base`, `raised`, `accent`, `outlined`, `critical`.
- `AppSectionHeader` with title, supporting text, trailing action/count chip.
- `AppInfoRow` for label/value metadata rows.
- `AppStatusBadge` for subscription status and sync/payment status.
- `AppConfirmationDialog` for destructive confirmation.
- `AppOperationalSnackbar` or `AppInlineNotice` for non-blocking operational feedback.

### Form/System Components

- `AppTextField` / themed input wrapper for create/edit flows.
- `AppDateField` or date-trigger row to remove local date picker theming.
- `AppSegmentedControl` extracted from `BillingSycleSelector`.
- `AppStickySubmitBar` or equivalent bottom CTA treatment for guided forms.
- themed bottom sheet wrapper used by service-template and contact-selection sheets.

### Domain-Specific Reusable Components

- summary hero card for KPI/detail first fold
- split summary card variant based on `SplitBillPreviewCard`
- sync status card variant based on `SubscriptionDetailSyncStatusCard`
- count chip and member-stat pills used in detail sections

Note: `BillingSycleSelector` should likely be renamed while extracting. The current typo is small, but Phase 6 is the right time to normalize that API.

## Screen-By-Screen Refactor Boundaries

### Home

Refactor scope:

- keep provider wiring, invalidation, and debt-first ordering unchanged
- move screen shell, loading cards, error card, and snackbar styling onto shared primitives/tokens
- align section spacing and section wrappers to the new surface system

Do not change:

- KPI ordering established in Phase 4
- reconciliation behavior
- data grouping logic from providers

Planner note: this is the safest first screen to validate the system foundation because the logic is already stable and the hierarchy is already correct.

### Create Group Subscription

Refactor scope:

- preserve provider state, controller sync, member selection flow, submit behavior, and service-template application
- reorganize presentation into guided grouped sections:
  - service/template selection summary
  - subscription basics
  - billing cadence/date
  - members
  - split preview
  - submit CTA
- replace repeated local field/input/date/button styles with shared components
- convert the screen from a visually long stack of similar blocks into a compact progression

Likely implementation boundary:

- keep the stateful screen as orchestration
- extract section widgets without touching domain logic first
- only after that, introduce shared form primitives

Planner note: this is the highest-effort screen and should not be mixed with business-logic cleanup. Keep the phase scoped to presentation structure and component reuse.

### Subscription Detail

Refactor scope:

- preserve payment ordering, optimistic toggles, sync invalidation, and delete behavior
- make the first fold summary-first: header, strongest metrics, due urgency, and state should read as one dominant block
- move secondary information into consistent section cards below the summary
- consolidate duplicated dialog/button/status styling into shared primitives

Likely restructuring target:

- summary hero block
- operational sync status block
- members block
- split/collection block
- analytics block
- actions block with strict CTA hierarchy

Planner note: detail is currently the best place to prove the new shared card language because almost every local variant exists here already.

### Billing Cycle Selector

Refactor scope:

- evolve into a generic segmented control driven by tokens for height, radius, selected background, and content color
- ensure it matches the same CTA/selection language used elsewhere

### Split Bill Preview Card

Refactor scope:

- keep its functional role and provider-driven breakdown intact
- reduce one-off styling so it reads as part of the same system as detail/home summary surfaces
- keep decorative accent only on the per-person emphasis area, not on the entire component family

### Catalog / Sheets Follow-Through

Even though the main inputs here were Home/Create/Detail, UX-01 also covers Catalog and selectors. Planning should include a consistency pass on the service-template sheet and contact-selection sheet because Phase 6 context explicitly includes bottom sheets and searchable selectors as part of the normalization effort.

## Suggested Planning Order

1. Theme foundation and semantic token expansion.
2. Shared primitives for surfaces, status, dialogs, feedback, and segmented control.
3. Home adoption to validate shell/section/status language with low product risk.
4. Create flow refactor with compact guided grouping and shared form primitives.
5. Detail refactor with summary-first consolidation and shared card language.
6. Sheet/catalog consistency pass.
7. Hardcoded-style cleanup and regression guard tests.
8. Persisted design-system documentation update so `MASTER.md` no longer conflicts with the product.

## Likely Risks And Regressions

- Home hierarchy regression: visual cleanup accidentally demotes the debt-first block mandated by Phase 4.
- Create flow regression: extracting widgets can break controller/provider synchronization or form submission timing.
- Interaction drift: CTA hierarchy changes could accidentally weaken the primary submit action.
- Over-decoration: gradients/glow spread from hero areas into routine sections, violating the restrained accent rule.
- Contrast drift: replacing literals without semantic roles can reduce readability on dark surfaces.
- Incomplete normalization: date picker, bottom sheets, snackbars, dialogs, and selectors remain local even after cards are unified.
- Test brittleness: copy or structure changes may break widget tests that rely on exact text trees; preserve critical keys and behavior-level assertions.
- Design-doc drift: if implementation moves to the dark system but `MASTER.md` stays light, future phases will reintroduce inconsistency.

## Validation Architecture

A future `VALIDATION.md` should combine source guards, widget/golden coverage, and flow validation.

### 1. Source-Level System Guards

Add targeted regression tests that fail if scoped core surfaces reintroduce ad-hoc styling patterns.

Suggested guard scope:

- `lib/features/home/presentation/screens/`
- `lib/features/subscriptions/presentation/screens/`
- selected reusable widgets in `lib/features/subscriptions/presentation/widgets/`

Suggested guard rules:

- fail on new hardcoded dark surface colors in scoped files
- fail on direct repeated gradient definitions outside theme/component primitives
- allow dynamic service/logo colors only where domain data requires them

This matches the repo's existing use of source-level regression guards in earlier phases.

### 2. Widget Tests For Shared Primitives And Screen Composition

Extend existing tests instead of replacing them:

- [`test/features/home/presentation/screens/home_screen_debt_priority_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/test/features/home/presentation/screens/home_screen_debt_priority_test.dart)
- [`test/features/subscriptions/presentation/screens/create_group_subscription_screen_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/test/features/subscriptions/presentation/screens/create_group_subscription_screen_test.dart)
- [`test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/test/features/subscriptions/presentation/screens/subscription_detail_sync_status_test.dart)
- [`test/features/subscriptions/presentation/screens/subscription_detail_payment_ordering_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/test/features/subscriptions/presentation/screens/subscription_detail_payment_ordering_test.dart)

Add focused tests for:

- segmented control selection states
- status badge variants
- confirmation dialog variants
- split preview card layout states
- screen-level CTA hierarchy and first-fold ordering

### 3. Golden Coverage For Visual Contracts

The repo does not currently show dedicated golden tooling, so start with `flutter_test` golden snapshots before adding another package.

Recommended golden targets:

- Home first fold
- Create screen default state
- Create screen with members + split preview
- Detail summary-first state
- sync status card variants
- segmented control variants

Run goldens under the dark theme, fixed text scale, and stable device sizes. Goldens are especially useful here because Phase 6 acceptance is mostly about hierarchy, density, and consistency.

### 4. Integration / Patrol Smoke Validation

Reuse existing flow coverage to ensure UX refactors do not break behavior:

- [`integration_test/subscription_setup_flow_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/integration_test/subscription_setup_flow_test.dart)
- [`integration_test/payment_debt_home_flow_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/integration_test/payment_debt_home_flow_test.dart)
- [`integration_test/subscription_setup_offline_catalog_test.dart`](/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/integration_test/subscription_setup_offline_catalog_test.dart)

Focus on smoke coverage, not visual assertions:

- create/edit submission still works
- member selection still works
- payment toggles still update Home/detail correctly
- bottom sheets/date picker/dialog flows still open and close correctly

### 5. Manual Visual Acceptance Checklist

Manual verification should explicitly check:

- Home still leads with debt/KPI and next collection
- Create feels compact and guided on narrow devices
- Detail opens with dominant summary, not a stack of equivalent cards
- primary/secondary/destructive CTAs are visually consistent across screens
- snackbars, sheets, dialogs, badges, and selectors share one system language
- decorative accent is restrained to key emphasis surfaces
- text contrast remains strong on all dark surfaces

## Planner Takeaway

The phase should be planned as a system-foundation pass plus three surface adoptions, not as isolated per-screen restyling. The key technical move is to upgrade the theme layer from raw brand values to semantic UX tokens, then force core screens and repeated widgets to consume those shared roles.

If planning starts directly at screen repainting without first resolving the `MASTER.md` conflict and token gaps, Phase 6 will produce another visually improved but still non-systematic result.

## RESEARCH COMPLETE
