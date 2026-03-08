-- =====================================================
-- SECU-03 RLS policy audit (database runtime checks)
-- =====================================================
-- Usage:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/security/rls_policy_audit.sql
--
-- This script fails with an exception when any isolation guard is missing.

DO $audit$
DECLARE
  v_issues TEXT[] := ARRAY[]::TEXT[];
  v_policy_count INTEGER;
  v_expr TEXT;
  v_has_required_functions BOOLEAN;
BEGIN
  -- 1) RLS must be enabled for all Phase 1 business tables.
  FOR v_expr IN
    SELECT table_name
    FROM (
      VALUES
        ('subscriptions'),
        ('subscription_members'),
        ('payment_history'),
        ('contacts')
    ) AS required(table_name)
    WHERE NOT EXISTS (
      SELECT 1
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = required.table_name
        AND c.relrowsecurity = TRUE
    )
  LOOP
    v_issues := array_append(v_issues, format('[SECU-03:RLS] RLS disabled for table public.%s', v_expr));
  END LOOP;

  -- 2) Canonical policies must exist.
  SELECT COUNT(*) INTO v_policy_count
  FROM (
    VALUES
      ('subscriptions', 'p1_subscriptions_select_own'),
      ('subscriptions', 'p1_subscriptions_insert_own'),
      ('subscriptions', 'p1_subscriptions_update_own'),
      ('subscriptions', 'p1_subscriptions_delete_own'),
      ('subscription_members', 'p1_subscription_members_select_owner_scope'),
      ('subscription_members', 'p1_subscription_members_insert_owner_scope'),
      ('subscription_members', 'p1_subscription_members_update_owner_scope'),
      ('subscription_members', 'p1_subscription_members_delete_owner_scope'),
      ('payment_history', 'p1_payment_history_select_owner_scope'),
      ('payment_history', 'p1_payment_history_insert_owner_scope'),
      ('payment_history', 'p1_payment_history_update_owner_scope'),
      ('payment_history', 'p1_payment_history_delete_owner_scope'),
      ('contacts', 'p1_contacts_select_own'),
      ('contacts', 'p1_contacts_insert_own'),
      ('contacts', 'p1_contacts_update_own'),
      ('contacts', 'p1_contacts_delete_own')
  ) AS expected(tablename, policyname)
  LEFT JOIN pg_policies p
    ON p.schemaname = 'public'
   AND p.tablename = expected.tablename
   AND p.policyname = expected.policyname
  WHERE p.policyname IS NULL;

  IF v_policy_count > 0 THEN
    v_issues := array_append(
      v_issues,
      format('[SECU-03:POLICY] %s canonical policies are missing in pg_policies', v_policy_count)
    );
  END IF;

  -- 3) Simulated cross-user denial checks via policy expressions.
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND policyname = 'p1_subscriptions_select_own'
      AND qual ILIKE '%auth.uid()%'
      AND qual ILIKE '%owner_id%'
  ) THEN
    v_issues := array_append(v_issues, '[SECU-03:SIM] subscriptions SELECT policy missing owner/auth.uid guard');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND policyname = 'p1_subscription_members_select_owner_scope'
      AND qual ILIKE '%auth.uid()%'
      AND qual ILIKE '%subscriptions%'
  ) THEN
    v_issues := array_append(v_issues, '[SECU-03:SIM] subscription_members SELECT policy missing owner-scope join guard');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND policyname = 'p1_payment_history_insert_owner_scope'
      AND with_check ILIKE '%auth.uid()%'
      AND with_check ILIKE '%marked_by%'
  ) THEN
    v_issues := array_append(v_issues, '[SECU-03:SIM] payment_history INSERT policy missing marked_by/auth.uid guard');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND policyname = 'p1_contacts_select_own'
      AND qual ILIKE '%auth.uid()%'
      AND qual ILIKE '%user_id%'
  ) THEN
    v_issues := array_append(v_issues, '[SECU-03:SIM] contacts SELECT policy missing user/auth.uid guard');
  END IF;

  -- 4) SECURITY DEFINER RPCs must be explicitly hardened.
  SELECT COUNT(*) = 3 INTO v_has_required_functions
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname IN (
      'mark_payment_as_paid_atomic',
      'unmark_payment_atomic',
      'get_payment_history_stats'
    );

  IF NOT v_has_required_functions THEN
    v_issues := array_append(v_issues, '[SECU-03:RPC] One or more required payment-history RPC functions are missing');
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'mark_payment_as_paid_atomic',
        'unmark_payment_atomic',
        'get_payment_history_stats'
      )
      AND (
        p.prosecdef = FALSE
        OR COALESCE(array_to_string(p.proconfig, ','), '') NOT ILIKE '%search_path=public, auth%'
        OR pg_get_functiondef(p.oid) NOT ILIKE '%auth.uid()%'
      )
  ) THEN
    v_issues := array_append(v_issues, '[SECU-03:RPC] SECURITY DEFINER/search_path/auth.uid hardening is incomplete');
  END IF;

  IF array_length(v_issues, 1) > 0 THEN
    RAISE EXCEPTION E'SECU-03 policy audit failed:\n%s', array_to_string(v_issues, E'\n');
  END IF;
END;
$audit$;

SELECT 'SECU-03 audit passed (database mode)' AS secu03_status;
