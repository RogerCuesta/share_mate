# Feature Research for MVP R1 (Share Mate)

## Context for this research
- Product focus: single-player subscription debt control for the paying owner, without requiring invitations.
- Baseline already present in app: auth/session, core subscription domain structure, contacts module, payment status support, offline-first stack (Hive + Supabase), app shell/navigation.
- Goal here: identify what must be completed to close MVP R1 in the existing codebase, not redesign the product.

## 1) Table Stakes (MVP Expectations)
1. Service catalog available in creation flow (RF1).
- User can pick common services (name + logo) from Supabase `service_templates`.
- Catalog must be cached locally so first-load latency does not block UI (RNF2).

2. Local contacts as shadow users integrated into subscription setup (RF2).
- Create/select contacts without email, invite, or account creation.
- Contacts must behave as local debtor records owned by current user.

3. Equal split calculation for shared subscription (RF3).
- Cost is auto-divided equally across selected members (owner excluded from debtor amount per current business rule).
- Recalculation happens when price or member list changes.

4. Per-contact payment status in subscription detail (RF4).
- Owner can toggle each contact between `pending` and `paid`.
- State change must be reflected immediately (optimistic UX), then synced.

5. Home debt dashboard as primary value surface (RF5).
- Home shows total outstanding debt and nearest upcoming charge.
- Totals must update immediately after payment status changes.

6. Local reminder 24h before charge date (RF6).
- Monthly notification scheduling per subscription.
- Rehydration required on app reopen/device migration to avoid missed reminders.

7. Monthly cycle reset to pending for new billing period.
- Paid states must reset when cycle rolls over to preserve month-by-month ritual.
- Preferred implementation in current plan: backend cron for reliability across devices.

8. Offline-first behavior preserved across all flows (RNF1).
- Full CRUD and payment marking must work without network.
- Sync conflicts must resolve without breaking debtor totals.

9. User data isolation and security boundary intact (RNF3).
- RLS ensures user can only access own subscriptions/contacts/payment states/templates permitted by policy.

## 2) Differentiators (within or adjacent to R1)
1. No-invite operating model.
- Core differentiator vs split apps: one person can manage everything alone.
- Keeps activation friction low and supports target audience behavior.

2. Settle-up ritual in two taps.
- Notification -> open detail -> mark paid -> Home total updates instantly.
- Delivers the product promise faster than generic expense apps.

3. Catalog-first creation UX.
- Preloaded service templates reduce manual entry and error rate.
- Strong impact on first-subscription completion (activation metric).

4. Debt-first Home design.
- Prioritizes “who owes me now” over generic analytics charts.
- Differentiates by decision speed, not reporting depth.

5. Built-in monthly cadence.
- Cycle reset + pre-charge reminders create recurring habit loop.
- Supports Day-30 retention target without adding social complexity.

## 3) Anti-features (Out of Scope for MVP R1)
1. Multi-user collaboration or invitations with shared state edits.
2. Integrated payment rails (Bizum, Stripe, card collection, payout flows).
3. Paywall/monetization mechanics (RevenueCat, subscription tiers, purchase gating).
4. Open Banking connections or automated transaction reconciliation.
5. Multicurrency ledger, FX conversion, or cross-currency settlement.
6. Advanced historical analytics (morosity ranking, long-term behavioral reports).
7. Web companion app for debtors to self-confirm payment.

## 4) Complexity per feature (S/M/L)
| ID | Feature | Complexity | Why this size in current app | R1 completion signal |
|---|---|---|---|---|
| F1 | Supabase service catalog wired to create flow | M | Backend table + provider + UI list + cache fallback | User selects template and fields autofill reliably |
| F2 | Shadow contacts CRUD integrated in create flow | M | Existing contacts module exists, but flow integration and UX hardening remain | Add/select contact without leaving activation funnel |
| F3 | Equal split engine (creation + edit recalculation) | S | Core math simple; needs guardrails for edge cases and rounding consistency | Amount per debtor stable and correct after edits |
| F4 | Payment status toggle with optimistic update | M | UI exists conceptually; atomic write + local cache coherence needed | Mark paid/pending updates detail + local model immediately |
| F5 | Home debt dashboard from aggregated stats | M | Requires reliable composition of RPC/local state and refresh triggers | Home total always matches current per-contact states |
| F6 | T-24 monthly local notifications | L | Scheduling, timezone normalization, recurrence, recovery after reinstall/open | Reminders fire at correct local time and are recreated when needed |
| F7 | Monthly cycle reset to pending | M | Needs robust period boundary logic; backend cron + client reconciliation | New billing cycle automatically reopens all pending dues |
| F8 | Offline-first sync hardening for R1 flows | M | Stack exists; must close gaps for catalog/cache/payment toggles conflicts | Core flows succeed offline and converge after reconnection |
| F9 | RLS/privacy verification on new/updated queries | S | Policies already present; incremental checks and query alignment | No cross-user data leakage in any R1 endpoint |
| F10 | R1 UI consistency pass (existing design system) | M | Cross-screen standardization in current Flutter views | Home/create/detail feel cohesive and reduce user hesitation |

## 5) Dependencies between features
- F1 and F2 are parallel starters; both feed the subscription creation funnel.
- F3 depends on F2 for selected-member set and on creation/edit form data stability.
- F4 depends on F3 because debtor amounts and member rows must exist before payment toggles make sense.
- F5 depends on F4 and F7; Home totals are only trustworthy when statuses and cycle boundaries are correct.
- F6 depends on stable subscription metadata from F1/F3 (service identity, charge day, active subscription state).
- F7 depends on canonical billing cycle fields established in creation/edit flows (F1/F3).
- F8 is cross-cutting: must validate F1-F7 work correctly offline and during resync.
- F9 is cross-cutting and should be checked whenever F1-F8 introduce or modify queries/RPC usage.
- F10 should run incrementally, but final polish pass should happen after F1-F7 are functionally stable.

### Suggested R1 execution order (critical path)
1. F1 + F2 (parallel)
2. F3
3. F4
4. F5
5. F7
6. F6
7. F8 + F9 (hardening gate)
8. F10 (final consistency pass)

### Risk notes tied to dependencies
- If F5 is implemented before F4/F7 are stable, Home trust will break due to stale or mis-scoped totals.
- If F6 ships before F7 cycle logic is validated, notifications may reinforce incorrect monthly states.
- If F8/F9 are postponed, R1 can look complete in happy path but fail in real-world offline/privacy scenarios.
