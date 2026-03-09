# Phase 3 Research: Subscription Setup Flow

**Phase:** 03-subscription-setup-flow  
**Date:** 2026-03-08  
**Status:** Ready for planning  
**Primary requirements:** CATA-01, CATA-02, CATA-03, CNTC-01, CNTC-02, SPLT-01, SPLT-02, SPLT-03

## Inputs Reviewed

- `.planning/phases/03-subscription-setup-flow/03-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- AGENTS instructions from prompt (`/Users/rogerpersonal/Documents/Proyectos Personales/share_mate/AGENTS.md` is not present in workspace)
- `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`
- `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart`
- `lib/features/subscriptions/presentation/widgets/service_icon_picker.dart`
- `lib/features/subscriptions/presentation/widgets/members_list_section.dart`
- `lib/features/subscriptions/presentation/widgets/add_member_dialog.dart`
- `lib/features/subscriptions/presentation/widgets/split_bill_preview_card.dart`
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
- `lib/features/subscriptions/data/models/subscription_model.dart`
- `lib/features/subscriptions/data/models/subscription_member_model.dart`
- `lib/features/contacts/domain/entities/add_contact_input.dart`
- `lib/features/contacts/domain/entities/update_contact_input.dart`
- `lib/features/contacts/domain/entities/contact.dart`
- `lib/features/contacts/data/models/contact_model.dart`
- `lib/features/contacts/data/datasources/contact_remote_datasource.dart`
- `lib/features/contacts/presentation/providers/contacts_provider.dart`
- `supabase/migrations/20260108_contacts_refactor.sql`
- `supabase/migrations/20260308_phase1_rls_hardening.sql`
- `lib/core/storage/hive_service.dart`
- `lib/core/storage/local_migrations/local_migration_runner.dart`
- `lib/core/storage/local_migrations/migrations/v2_encrypt_sensitive_boxes_migration.dart`

## Current State vs Phase 3 Requirements

### CATA-01/02/03 (catalog search + autofill + cached)

**Current state**
- Catalog is static only (`PredefinedServices.services`) and rendered as fixed grid (`ServiceIconPicker`).
- No `service_templates` table, migrations, datasource, repository, or provider.
- No search UX for catalog templates.
- No local TTL cache for catalog templates.

**Planning impact**
- Phase 3 needs new backend contract + Flutter data flow end-to-end.
- Must define cache strategy explicitly (context decision: 24h TTL + manual refresh + background refresh).

### CNTC-01/02 (local contacts in-flow, no email requirement)

**Current state**
- Contact domain/input requires email everywhere:
  - `AddContactInput.email` required.
  - `UpdateContactInput.email` required.
  - `Contact.email` required.
  - `ContactModel.email` required.
- Supabase `contacts` migration enforces `contact_email TEXT NOT NULL` + email regex + unique `(user_id, contact_email)`.
- Group flow does not use contacts feature:
  - `MembersListSection` opens `AddMemberDialog` with manual `name + email`.
  - No in-flow contacts select/edit/delete sheet.

**Planning impact**
- CNTC-01 is blocked by current domain/schema constraints.
- Planner must include coordinated refactor across domain, data, UI, and SQL migration.
- Must decide email strategy for `subscription_members.user_email` (currently required everywhere).

### SPLT-01/02/03 (split rules + recalculation + billing-day normalization)

**Current state**
- UI preview already includes owner in math (`totalMembers = members + 1`) and assigns remainder to owner in `breakdown`.
- Recalc on edit exists (`_handleMembersUpdate`) and can reset payment when members change.
- Date handling is raw `DateTime` from picker; no anchor-day normalization utility or persisted anchor day.

**Critical gap found**
- Persisted member split can be wrong on create/add-member path:
  - `addMemberToSubscription()` computes `amountToPay` using `subscription.costPerPerson`.
  - Created subscription is reloaded with `shared_with = []` from remote create response.
  - `costPerPerson` then becomes `totalCost / 1`, causing incorrect member amount assignment.
- Added members in edit path may also inherit wrong initial amount before recalculation updates existing members.

**Planning impact**
- Split math must be centralized as a single source of truth and reused in create + edit persistence paths.
- SPLT-03 requires a billing-anchor model (e.g. `billing_anchor_day`) to preserve original day (31 -> Feb 28/29 -> Mar 31).

## Standard Stack

- **Flutter + Riverpod codegen (`@riverpod`)** for state and async orchestration.
- **Clean architecture layering** already used in repo: `domain` <- `data` <- `presentation`.
- **Supabase** for canonical catalog/contact/subscription persistence and RLS.
- **Hive (encrypted)** for local cache and offline-friendly reads.
- **GoRouter** existing navigation; use modal bottom sheets inside current create/edit screen instead of route proliferation.

## Architecture Patterns

1. **Catalog: cache-first + stale-while-revalidate**
- Read Hive cache immediately (no UI blocking).
- If cache missing/stale (TTL 24h), trigger background Supabase refresh.
- Expose manual refresh action in catalog sheet to force re-fetch.

2. **Form orchestration: one coordinator provider**
- Keep `create_group_subscription_form_provider.dart` as the single orchestrator.
- Add catalog/template state and contact-selection state there (or a dedicated nested provider consumed by this form provider).
- Prevent split/date logic duplication across UI widgets.

3. **Contact quick-create and selection as first-class in-flow primitives**
- New modal sheet with tabs: `Select` and `Quick Create`.
- Reuse existing contacts providers/use cases; extend contracts for optional email and color/avatar.
- Keep selections live in form state; editing/deleting a contact updates selected members immediately.

4. **Deterministic split engine**
- Introduce pure utility/service used by provider + repository mapping.
- Inputs: `totalPrice`, selected members count, owner inclusion fixed true.
- Output: member amount, owner amount, per-member breakdown, cent remainder.

5. **Date normalization with anchor-day contract**
- Store `billing_anchor_day` at creation/edit time.
- Normalize computed due dates to last valid day of month while keeping anchor for future months.
- Use date-only semantics in local timezone in presentation/domain layer.

## Don’t Hand-Roll

- Don’t invent a custom search backend for templates. Use Supabase query + local filter for cached list.
- Don’t keep split formulas in multiple places (UI preview + repository + datasource). Keep one shared calculator.
- Don’t fake emails to satisfy schema (`foo@local`). Make email optional in the model/DB if contact is local-only.
- Don’t bypass existing Riverpod/DI patterns with ad-hoc singleton state in widgets.
- Don’t couple catalog TTL logic to widget lifecycle; keep it in repository/provider.

## Common Pitfalls

- **Persisted split drift:** UI preview looks correct but saved `amount_to_pay` differs (already possible in current code path).
- **Breaking edits for legacy members:** existing members with email-based identity must still render/select after migration.
- **Nullable email ripple effects:** contact/search/list UI currently assumes `contact.email` always present.
- **Schema/app mismatch:** Flutter optional email without SQL migration will fail inserts/updates.
- **Date anchor loss:** without a separate anchor day field, SPLT-03 cannot be deterministic across months.
- **Cache freshness bugs:** TTL checks implemented only at UI level can become inconsistent across entry points.

## Code Examples

### 1) Shared split calculator (single source of truth)

```dart
class SplitResult {
  const SplitResult({
    required this.memberAmount,
    required this.ownerAmount,
  });

  final double memberAmount;
  final double ownerAmount;
}

SplitResult calculateSplit({
  required double total,
  required int selectedMembers,
}) {
  final totalPeople = selectedMembers + 1; // owner included
  final raw = total / totalPeople;
  final memberAmount = (raw * 100).floor() / 100;
  final ownerAmount = total - (memberAmount * selectedMembers);
  return SplitResult(
    memberAmount: memberAmount,
    ownerAmount: ownerAmount,
  );
}
```

### 2) Billing day normalization with anchor day

```dart
DateTime normalizeBillingDate({
  required int anchorDay,
  required int year,
  required int month,
}) {
  final firstOfNextMonth = month == 12
      ? DateTime(year + 1, 1, 1)
      : DateTime(year, month + 1, 1);
  final lastDay = firstOfNextMonth.subtract(const Duration(days: 1)).day;
  final normalizedDay = anchorDay <= lastDay ? anchorDay : lastDay;
  return DateTime(year, month, normalizedDay);
}
```

### 3) Catalog repository contract with TTL + manual refresh

```dart
abstract class ServiceTemplateRepository {
  Future<List<ServiceTemplate>> getTemplates({
    String? query,
    bool forceRefresh = false,
  });
}

// Behavior:
// - read cache first
// - if stale (older than 24h) or forceRefresh, fetch remote + overwrite cache
// - return cached list immediately while refresh runs in background
```

### 4) Contact quick-create duplicate-name warning flow

```dart
Future<ContactSelectionResult> createQuickContact(
  QuickContactInput input,
  List<Contact> existing,
) async {
  final duplicate = existing.any(
    (c) => c.name.trim().toLowerCase() == input.name.trim().toLowerCase(),
  );

  if (duplicate) {
    // show "reuse existing?" warning, allow explicit continue
  }

  // proceed through addContact use case with optional email
}
```

## Concrete Implementation Blueprint (Planner-Oriented)

### A) Data model + schema groundwork (must come first)

1. Add catalog schema migration:
- New `service_templates` table (id, name, logo_url, brand_color, aliases/keywords, is_active, updated_at).
- Read policy for authenticated users.

2. Evolve contacts schema for CNTC-01:
- `contacts.contact_email` -> nullable.
- relax email regex check to allow null.
- keep uniqueness only when email is not null (partial unique index if needed).
- add `contact_color` (or equivalent) for quick-create color/avatar requirement.

3. Decide `subscription_members.user_email` contract:
- Recommended: nullable to avoid synthetic data.
- If kept required, planner must define deterministic placeholder strategy and validation boundaries.

### B) Subscriptions catalog feature slice (CATA-01/02/03)

1. New domain/data pieces under `features/subscriptions`:
- `domain/entities/service_template.dart`
- `data/datasources/service_template_remote_datasource.dart`
- `data/datasources/service_template_local_datasource.dart` (Hive cache + fetchedAt metadata)
- `data/repositories/service_template_repository_impl.dart`
- Riverpod providers for query + list + refresh.

2. Replace fixed `ServiceIconPicker` as primary input with searchable sheet:
- Keep `PredefinedServices` as fallback seed when remote/cache unavailable.
- On template select, apply `name/logo/color` to form state with manual override preserved.

3. Cache policy:
- TTL 24h.
- background refresh when stale.
- explicit pull-to-refresh / refresh button.

### C) In-flow contacts sheet (CNTC-01/02)

1. Refactor contact contracts to optional email and color/avatar.
2. Add `contacts_selection_sheet.dart` with tabs:
- `Select`: searchable existing contacts, multi-select.
- `Quick Create`: name + color/avatar only, optional email.
3. Add in-sheet edit/delete actions and immediate reflection in selected members state.
4. Duplicate exact-name warning (confirm continue).

### D) Split correctness hardening (SPLT-01/02)

1. Move split math into shared utility/service.
2. Ensure `addMemberToSubscription` gets explicit computed amount from provider/service (not from stale `sharedWith`).
3. In edit flow, apply same computation for:
- newly added members,
- existing members amount updates,
- owner remainder preview.
4. Keep payment reset semantics exactly as decided:
- members changed -> reset payments,
- price-only change -> keep payment status.

### E) Billing day normalization (SPLT-03)

1. Add `billing_anchor_day` storage in subscription model/schema.
2. Add date utility for month normalization to last valid day.
3. Show contextual hint in form when selected day can overflow short months.
4. Keep date-only local semantics for UI and domain calculations.

## File-Level Impact Map (Expected)

- `lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`
- `lib/features/subscriptions/presentation/providers/create_group_subscription_form_provider.dart`
- `lib/features/subscriptions/presentation/widgets/service_icon_picker.dart` (or replacement)
- `lib/features/subscriptions/presentation/widgets/members_list_section.dart` (or replacement)
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
- `lib/features/subscriptions/domain/entities/subscription_member_input.dart`
- `lib/features/contacts/domain/entities/add_contact_input.dart`
- `lib/features/contacts/domain/entities/update_contact_input.dart`
- `lib/features/contacts/domain/entities/contact.dart`
- `lib/features/contacts/data/models/contact_model.dart`
- `lib/features/contacts/data/datasources/contact_remote_datasource.dart`
- `lib/features/contacts/presentation/widgets/add_contact_dialog.dart`
- `lib/features/contacts/presentation/widgets/edit_contact_dialog.dart`
- `lib/features/contacts/presentation/widgets/contact_list_item.dart`
- `lib/core/di/injection.dart` (new providers wiring)
- `supabase/migrations/<new_phase3_*.sql>`
- optional local migration if Hive adapters/fields need compatibility handling

## Test Strategy Mapped to Requirement IDs

### CATA-01/CATA-02/CATA-03
- Repository tests for cache hit/miss, TTL expiry, background refresh, force refresh.
- Provider tests for query filtering and template apply-to-form behavior.
- Widget tests for searchable catalog sheet and autofill override behavior.

### CNTC-01/CNTC-02
- Entity/input validation tests for optional email.
- Contacts repository tests with nullable email responses and duplicate-name warning path.
- Widget tests for tabbed contact sheet (select/create/edit/delete) and live selection sync.

### SPLT-01/SPLT-02
- Pure unit tests for split utility (rounding and remainder assignment to owner).
- Provider tests verifying recalculation on price/member changes.
- Regression test for persisted `amount_to_pay` on create and edit add-member flows.

### SPLT-03
- Unit tests for anchor-day normalization (28/29/30/31 cases).
- Provider tests for hint display trigger conditions.
- Integration test covering create/edit persistence of anchor day + due date.

## Validation Gates Before Phase Close

1. SQL migration applies cleanly on a fresh project and on existing project state.
2. All new/updated providers pass tests without breaking current auth/sync flows.
3. Create/edit flow produces identical split values in preview and persisted members.
4. Catalog usable with network off when cache exists.
5. Contact quick-create works without email and remains editable/deletable in-flow.
6. SPLT-03 edge dates are deterministic for month transitions.

## Suggested Plan Breakdown (Execution Order)

1. **Plan A: schema + contracts**
- Supabase migrations (service templates + contacts/email/anchor fields).
- Domain/data model updates for optional contact email and billing anchor day.

2. **Plan B: catalog data + cache**
- Remote/local datasources, repository, providers, TTL, manual refresh.

3. **Plan C: create/edit UI integration**
- Searchable catalog sheet + autofill.
- Contacts selection/quick-create/edit/delete sheet in group form.

4. **Plan D: split/date correctness**
- Central split utility adoption in provider/repository paths.
- Anchor-day normalization + hints.

5. **Plan E: verification**
- Requirement-mapped tests and regression checks.

## RESEARCH COMPLETE
