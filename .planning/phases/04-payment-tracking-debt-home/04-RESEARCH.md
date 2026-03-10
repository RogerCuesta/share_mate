# Phase 4 Research: Payment Tracking & Debt Home

**Phase:** 04-payment-tracking-debt-home  
**Date:** 2026-03-10  
**Status:** Ready for planning  
**Primary requirements:** PAYM-01, PAYM-02, PAYM-03, DASH-01, DASH-02

## Inputs Reviewed

- `.planning/phases/04-payment-tracking-debt-home/04-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `lib/features/subscriptions/presentation/providers/payment_provider.dart`
- `lib/features/subscriptions/presentation/widgets/payment_status_toggle.dart`
- `lib/features/subscriptions/presentation/widgets/payment_action_buttons.dart`
- `lib/features/subscriptions/presentation/providers/subscription_detail_provider.dart`
- `lib/features/subscriptions/presentation/providers/subscriptions_provider.dart`
- `lib/features/subscriptions/presentation/screens/subscription_detail_screen.dart`
- `lib/features/subscriptions/data/repositories/subscription_repository_impl.dart`
- `lib/features/subscriptions/data/datasources/subscription_local_datasource.dart`
- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
- `lib/core/sync/payment_sync_queue.dart`
- `lib/core/sync/payment_sync_orchestrator.dart`
- `lib/core/sync/payment_sync_conflict_resolver.dart`
- `lib/core/sync/sync_status.dart`
- `lib/features/subscriptions/presentation/providers/sync_status_provider.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/stats_cards.dart`
- `lib/features/home/presentation/widgets/action_required_section.dart`
- `lib/features/home/presentation/widgets/home_header.dart`
- `lib/features/home/presentation/widgets/active_subscriptions_section.dart`
- `lib/features/subscriptions/domain/entities/subscription_member.dart`
- `lib/features/subscriptions/domain/entities/subscription.dart`
- `lib/features/subscriptions/data/models/subscription_member_model.dart`
- `lib/features/subscriptions/data/models/subscription_model.dart`
- `supabase/migrations/20260308_phase1_rls_hardening.sql`
- `supabase/migrations/20260308_phase2_sync_conflict_reconciliation.sql`
- `supabase/migrations/20260309_phase3_subscription_setup_foundation.sql`
- `test/core/sync/payment_sync_orchestrator_test.dart`
- `test/core/sync/conflict_resolution_test.dart`
- `test/features/subscriptions/data/repositories/subscription_repository_impl_sync_test.dart`
- `test/features/home/presentation/widgets/home_header_sync_badge_test.dart`

## Current State vs Phase 4 Requirements

| Requirement | Current state | Gap to close in planning |
|---|---|---|
| `PAYM-01` Toggle `pendiente/pagado` per contact in detail | Implemented via `PaymentStatusToggle` + `paymentActionProvider` + repository mutations (`markAsPaid`/`unmark`), plus undo snackbar. | Missing explicit pending-first ordering after status changes. Loading state is global (all toggles watch one provider), not per-member. |
| `PAYM-02` Immediate optimistic UI + Home aggregate update | Repository performs optimistic local member update before remote; provider invalidates members/stats/monthly/pending providers after success. | "Immediate" is limited by async action completion and provider invalidation path. No dedicated debt-home view model; Home still shows generic cards, not debt-first + next-collection. |
| `PAYM-03` Offline queue + later sync consistency | Implemented in Phase 2 stack (`PaymentSyncQueueService`, `PaymentSyncOrchestrator`, conflict preflight, idempotency keys, terminal recovery actions). | No explicit user-facing reconciliation notice when canonical remote state corrects optimistic local assumptions (required by context decisions). |
| `DASH-01` Home prioritizes total debt + next charge | Home currently renders `StatsCards` (`Total Monthly Cost` + `Pending to Collect`) and `ActionRequiredSection`. | No primary KPI block for "deuda total a favor" + no "proximo cobro" block with urgency policy and tie-break rule. |
| `DASH-02` Home totals stay consistent after toggles/sync/cycle resets | Invalidation helps after direct payment actions; sync status badges exist in Home/Detail/Settings. | No explicit refresh path from sync conflict resolution to Home KPIs; cycle-reset-ready consistency behavior is not wired to user feedback/correction flow yet. |

## Key Technical Findings You Need to Plan Around

1. **Payment foundation exists and is reusable.**
- Core actions (`mark`, `unmark`, `mark all`) already mutate local first, then remote/queue fallback.
- Sync pipeline already handles retry/backoff, stale-cycle terminal no-op, and idempotency.

2. **Detail screen behavior is functional but not phase-complete.**
- Member list order is currently fetch-order (`created_at desc`), not operational order (`pendiente` first).
- Global loading state in `paymentActionProvider` can freeze all member toggles while one action runs.

3. **Home data primitives exist but the debt-focused composition does not.**
- Existing providers: `monthlyStatsProvider`, `pendingPaymentsProvider`, `activeSubscriptionsProvider`.
- Missing: an explicit `DebtHome` aggregate model/provider implementing urgency and tie-break rules from context.

4. **Bulk mark-all remote path is not atomic at datasource level.**
- `markAllPaymentsAsPaid` remote implementation does update + history insert as separate operations.
- For phase consistency guarantees, plan should harden this path (single RPC or deterministic retry contract).

5. **Cycle conflict correction UX is missing.**
- Conflict/no-op terminalization exists in sync core.
- No direct UX hook currently informs user that optimistic local state was corrected by canonical backend state.

## Standard Stack

- **Flutter + Riverpod (`@riverpod`)** for UI/reactive state.
- **Current subscriptions repository** as mutation boundary (keep optimistic + queue contract there).
- **Supabase RPCs** for canonical payment mutation (`mark_payment_as_paid_atomic`, `unmark_payment_atomic`) and conflict audit.
- **Hive encrypted local cache + queue** for offline persistence.
- **Existing sync status model** (`Synced`, `Pending`, `Requires action`) for user-visible reliability signals.

## Architecture Patterns

1. **Debt Home as a dedicated read model (recommended).**
- Add a phase-specific provider (e.g. `debtHomeSnapshotProvider`) that composes current providers and applies business rules:
  - `totalDebt = pending amount in current cycle`
  - `nextCollection` chosen by urgency (overdue first, else nearest due date, tie by highest pending amount).

2. **Operational ordering in detail view.**
- Sort members for rendering, not storage:
  - group by `hasPaid` (`false` first),
  - then by due urgency,
  - then by amount/name for deterministic UI.

3. **Action-scoped loading state.**
- Evolve payment action state from single global `loading` to keyed loading (`memberId` or action scope) so one tap does not block unrelated toggles.

4. **Optimistic update + explicit reconciliation events.**
- Keep current optimistic mutation pattern.
- Add a small reconciliation signal channel so Home/detail can refresh and optionally show one-line notice after conflict/terminal correction.

5. **Keep sync rules centralized in core/sync.**
- Do not duplicate cycle conflict logic in UI providers.
- UI consumes normalized sync/debt signals only.

## Don’t Hand-Roll

- Do not build a second offline queue for Home; reuse `PaymentSyncQueueService` + orchestrator.
- Do not compute debt metrics ad-hoc inside widgets; keep one provider/read model.
- Do not add UI-only "fake corrected state" logic for conflicts; corrections must come from canonical data refresh.
- Do not bypass existing atomic payment RPCs for single-member actions.
- Do not implement cycle-reset simulation in Phase 4; make Phase 4 reset-ready, actual automation remains Phase 5.

## Common Pitfalls

- **Global loading lock:** One payment action disables all toggles, creating perceived lag and accidental double taps later.
- **Partial consistency after sync conflict:** Queue terminalization without UI refresh/notice can leave stale on-screen values.
- **Wrong next-collection candidate:** Selecting from raw pending members without subscription-level grouping can violate DASH-01 tie-break semantics.
- **Due-date drift assumptions:** Member `dueDate` and subscription `dueDate` may diverge after edit flows; next-collection should use a deterministic source of truth (recommend subscription-level due date + grouped pending).
- **Bulk mark-all durability gap:** Non-atomic remote bulk flow can produce history/state mismatch if one remote step fails.

## Code Examples

### 1) Debt Home read model (composition provider)

```dart
class DebtHomeSnapshot {
  const DebtHomeSnapshot({
    required this.totalDebt,
    required this.nextCollection,
    required this.hasDebt,
  });

  final double totalDebt;
  final NextCollectionCandidate? nextCollection;
  final bool hasDebt;
}

@riverpod
Future<DebtHomeSnapshot> debtHomeSnapshot(DebtHomeSnapshotRef ref) async {
  final pending = await ref.watch(pendingPaymentsProvider.future);
  final subscriptions = await ref.watch(activeSubscriptionsProvider.future);

  final pendingBySubscription = <String, List<SubscriptionMember>>{};
  for (final member in pending.where((m) => !m.hasPaid)) {
    pendingBySubscription.putIfAbsent(member.subscriptionId, () => []).add(member);
  }

  final totalDebt = pendingBySubscription.values
      .expand((v) => v)
      .fold<double>(0, (sum, m) => sum + m.amountToPay);

  final candidates = buildCandidates(pendingBySubscription, subscriptions);
  final next = selectNextCollection(candidates);

  return DebtHomeSnapshot(
    totalDebt: totalDebt,
    nextCollection: next,
    hasDebt: totalDebt > 0,
  );
}
```

### 2) Deterministic next-collection selector (DASH-01 rule)

```dart
NextCollectionCandidate? selectNextCollection(List<NextCollectionCandidate> all) {
  if (all.isEmpty) return null;

  all.sort((a, b) {
    // 1) Overdue first
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;

    // 2) Nearest due date
    final dueCmp = a.dueDate.compareTo(b.dueDate);
    if (dueCmp != 0) return dueCmp;

    // 3) Higher pending amount first
    final amountCmp = b.pendingAmount.compareTo(a.pendingAmount);
    if (amountCmp != 0) return amountCmp;

    return a.subscriptionId.compareTo(b.subscriptionId);
  });

  return all.first;
}
```

### 3) Pending-first render sort in detail

```dart
List<SubscriptionMember> sortedMembers(List<SubscriptionMember> input) {
  final copy = [...input];
  copy.sort((a, b) {
    if (a.hasPaid != b.hasPaid) return a.hasPaid ? 1 : -1;

    final dueCmp = a.dueDate.compareTo(b.dueDate);
    if (dueCmp != 0) return dueCmp;

    return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
  });
  return copy;
}
```

## Concrete Implementation Blueprint (Planner-Oriented)

### Slice A: Debt Home domain/read model first (`DASH-01`, `DASH-02`)

1. Add new Home-level model/provider for debt snapshot and next collection candidate.
2. Implement urgency + tie-break policy exactly as phase context states.
3. Replace/augment `StatsCards` with a debt-priority KPI block and next-collection panel.
4. Keep zero-debt state explicit (`Todo al dia`).

### Slice B: Detail operational UX completion (`PAYM-01`, `PAYM-02`)

1. Add deterministic pending-first ordering to detail member list.
2. Refactor payment action state to allow per-item loading.
3. Preserve undo behavior for both single and bulk actions.
4. Ensure provider invalidation includes all Home-relevant sources (already partly done, validate final set).

### Slice C: Sync reconciliation visibility (`PAYM-03`, `DASH-02`)

1. Introduce a lightweight reconciliation notifier surfaced in Home/detail.
2. On queue conflict/no-op or terminal correction, trigger refresh of debt snapshot providers.
3. Show short snackbar/info text for canonical corrections.

### Slice D: Bulk operation hardening (`PAYM-03`, `DASH-02`)

1. Decide one of:
- Replace current remote bulk path with single RPC transaction, or
- Execute per-member atomic RPC with idempotency keys.
2. Keep local optimistic bulk behavior, but enforce deterministic remote convergence.

### Slice E: Verification and traceability closure

1. Add requirement-tagged tests for PAYM and DASH IDs.
2. Add one integration/user-journey test proving home debt + next-collection update after toggle and after sync reconciliation.
3. Add static/contract checks to guard new provider composition and sorting rules.

## Test Strategy (Mapped to Requirement IDs)

| Test target | Purpose | Req IDs |
|---|---|---|
| `test/features/subscriptions/presentation/providers/payment_provider_*` | Per-member loading, single toggle, undo, invalidation guarantees. | PAYM-01, PAYM-02 |
| `test/features/subscriptions/presentation/screens/subscription_detail_*` | Pending-first ordering and visual state transitions. | PAYM-01 |
| `test/features/home/presentation/providers/debt_home_snapshot_provider_test.dart` (new) | Rule correctness: total debt, overdue priority, nearest due, amount tie-break. | DASH-01 |
| `test/features/home/presentation/widgets/debt_home_kpi_test.dart` (new) | Rendering for debt state and zero-debt state (`Todo al dia`). | DASH-01 |
| `test/core/sync/*` (extend existing) | Reconciliation event and provider refresh triggers after conflict/terminal/success paths. | PAYM-03, DASH-02 |
| `integration_test/payment_debt_home_flow_test.dart` (new) | End-to-end: toggle in detail updates Home debt + next collection without manual refresh; offline queue reconciliation correctness. | PAYM-02, PAYM-03, DASH-01, DASH-02 |

## Planning Decisions to Lock Before Writing PLAN.md

1. **Source of truth for due date in next-collection selection:** subscription-level due date vs member due date when they diverge.
2. **Bulk mutation backend path:** keep current two-step client flow or introduce transactional RPC.
3. **Where reconciliation notice is emitted:** payment provider, sync status provider, or dedicated event bus.
4. **Scope of Home redesign in Phase 4 vs Phase 6:** ensure minimal UI delta focused on debt semantics only.

## Confidence

- **High confidence:** PAYM-03 core sync reliability foundations already exist and are test-backed.
- **Medium confidence:** DASH-02 requires explicit reconciliation refresh/notice wiring not yet present.
- **Medium confidence:** DASH-01 implementation is straightforward but requires careful aggregation semantics to avoid wrong candidate selection.

## RESEARCH COMPLETE
