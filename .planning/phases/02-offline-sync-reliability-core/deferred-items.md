# Deferred Items

## 2026-03-08 — Plan 02-02

Out-of-scope analyzer infos found during plan verification (pre-existing in `subscription_remote_datasource.dart`, not introduced by this plan):

- `avoid_dynamic_calls` at lines `181`, `183`, `193`, `196`, `197`, `207`, `259`, `536`
- `cascade_invocations` at line `462`
- `curly_braces_in_flow_control_structures` at lines `1112`, `1114`

These were not auto-fixed because they are unrelated to the current task changes and would broaden scope.

## 2026-03-08 — Plan 02-03

Out-of-scope verification noise during plan execution:

- `flutter analyze` info-level lints remain in legacy sections of `subscription_remote_datasource.dart` and `payment_provider.dart` (existing style/lint debt not required for SYNC-03 behavior).
- Plan-provided grep guard `Amount:|notes|memberId|\$\{` matches required API identifiers (`memberId`, `notes`) and RPC params in payment contracts, so it cannot pass without breaking public method signatures and backend parameter mapping.

These were documented and deferred to avoid architectural churn outside the plan objective.
