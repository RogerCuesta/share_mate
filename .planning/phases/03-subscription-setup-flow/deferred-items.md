# Deferred Items

## 2026-03-08 — Plan 03-02 verification out-of-scope analyzer infos

The required command

`flutter analyze lib/features/subscriptions/data lib/features/subscriptions/presentation/providers/service_template_provider.dart lib/features/subscriptions/presentation/widgets/service_template_sheet.dart lib/features/subscriptions/presentation/screens/create_group_subscription_screen.dart`

still reports pre-existing infos in files untouched by this plan:

- `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart`
  - multiple `avoid_dynamic_calls`
  - multiple `cascade_invocations`
- `lib/features/subscriptions/data/datasources/subscription_seed_data.dart`
  - `avoid_classes_with_only_static_members`

These issues predate plan 03-02 and were intentionally not fixed to avoid out-of-scope churn.
