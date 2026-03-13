# Share Mate Design System

## Purpose
This file is the persistent source of truth for Share Mate Phase 6.
The product language is **dark**, **transactional**, and **trust-first**: users should read debt status quickly, execute payment actions safely, and understand sync state without visual noise.

## Product Surfaces
- Home: debt-first summary, next collection urgency, concise operational state.
- Create and Split: compact guided flow, dense forms, restrained accent usage.
- Catalog and selectors: sheet-based exploration with clear selection states.
- Detail: summary-first hero, members and actions grouped in disciplined sections.

## System Principles
- Prioritize legibility over decorative effects.
- Reserve high-contrast accent for the most important CTA or status in each fold.
- Keep secondary cards quieter than KPI and summary blocks.
- Use shared primitives for cards, headers, status badges, snackbar feedback, and confirmation dialogs.
- Avoid per-screen ad-hoc gradients, hardcoded dark hexes, and local dialog/snackbar themes.

## Semantic Token Model

### Surface Roles
- `surfaceBase`: app background.
- `surfaceRaised`: default card/background container.
- `surfaceAccent`: elevated emphasis card.
- `surfaceCritical`: destructive or high-risk context card.

### Content Roles
- `textPrimary`: main labels and values.
- `textSecondary`: supporting copy.
- `textMuted`: helper text and tertiary metadata.
- `textOnAccent`: text/icons on primary CTA blocks.
- `iconPrimary` / `iconSecondary`: icon contrast hierarchy.

### Feedback Roles
- `statusSynced`: healthy sync and settled states.
- `statusPending`: in-progress or queued sync/payment status.
- `statusRequiresAction`: terminal failure or manual recovery state.
- `statusInfo`: neutral operational updates.
- `statusSuccess`, `statusWarning`, `statusError`: global feedback tones.

### CTA Roles
- `ctaPrimary`: strongest action for current screen/fold.
- `ctaSecondary`: supportive action with lower contrast.
- `ctaDestructive`: irreversible actions (delete, dangerous resets).

### Density Roles
- `densityCompact`: dense list/form spacing for transactional flows.
- `densityRegular`: default section spacing between blocks.

## Shared Primitive Contract
- `AppScreenScaffold`: consistent safe-area behavior, baseline horizontal rhythm, bottom breathing space.
- `AppSectionCard`: reusable container with base/raised/accent/critical tones.
- `AppSectionHeader`: unified section title + subtitle + optional trailing action/count.
- `AppStatusBadge`: normalized status treatment for sync, payment, and automation.
- `AppOperationalSnackbar`: concise non-blocking feedback with tone-specific icon/color.
- `AppConfirmationDialog`: unified confirm/cancel pattern with optional destructive emphasis.

## Home Contract
- First fold must always prioritize debt total and next collection.
- KPI and next collection can use stronger accents than secondary sections.
- Secondary sections (`stats`, `action required`, `active subscriptions`) keep quieter surfaces and denser spacing.
- Sync and automation feedback must remain concise and non-blocking.

## Create/Split/Catalog Contract
- Form fields, date selectors, segmented controls, and sticky submit bars use shared primitives.
- Catalog and contact selection use consistent sheet treatment and search field language.
- Split preview can highlight money math; surrounding form sections should remain restrained.
- Contact editing dialogs reuse shared confirmation/feedback patterns.

## Detail Contract
- First fold is summary-first: value, urgency, and sync state.
- Members, analytics, and secondary actions sit below the summary fold in consistent section cards.
- Payment toggles and ordering semantics remain behaviorally unchanged from prior phases.
- Destructive actions must use shared confirmation dialog styling.

## Anti-Patterns
- Reintroducing local `SnackBar` visual styling inside feature screens.
- Reintroducing local `AlertDialog` visual styling inside scoped Phase 6 surfaces.
- Adding new hardcoded dark-surface hex values directly in Home/Create/Detail files.
- Adding competing visual systems for cards/badges outside shared primitives.

## Accessibility and Stability
- Maintain visible focus states and sufficient contrast in dark mode.
- Keep typography stable across 1.0 and 1.15 text scale.
- Preserve business behavior while refactoring visual layers.
