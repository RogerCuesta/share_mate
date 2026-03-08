-- =====================================================
-- Migration: Phase 1 RLS hardening
-- Date: 2026-03-08
-- Requirement: SECU-03
-- Purpose: Enforce explicit tenant-isolation policies for all
--          Phase 1 business tables.
-- =====================================================

-- Ensure RLS is active on all in-scope business tables.
ALTER TABLE IF EXISTS public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.subscription_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.contacts ENABLE ROW LEVEL SECURITY;

-- Optional hardening: force owner-scoped access through policies.
ALTER TABLE IF EXISTS public.subscriptions FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.subscription_members FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payment_history FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.contacts FORCE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- subscriptions
  IF to_regclass('public.subscriptions') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "p1_subscriptions_select_own" ON public.subscriptions';
    EXECUTE 'CREATE POLICY "p1_subscriptions_select_own"
      ON public.subscriptions FOR SELECT
      USING (owner_id = auth.uid())';

    EXECUTE 'DROP POLICY IF EXISTS "p1_subscriptions_insert_own" ON public.subscriptions';
    EXECUTE 'CREATE POLICY "p1_subscriptions_insert_own"
      ON public.subscriptions FOR INSERT
      WITH CHECK (owner_id = auth.uid())';

    EXECUTE 'DROP POLICY IF EXISTS "p1_subscriptions_update_own" ON public.subscriptions';
    EXECUTE 'CREATE POLICY "p1_subscriptions_update_own"
      ON public.subscriptions FOR UPDATE
      USING (owner_id = auth.uid())
      WITH CHECK (owner_id = auth.uid())';

    EXECUTE 'DROP POLICY IF EXISTS "p1_subscriptions_delete_own" ON public.subscriptions';
    EXECUTE 'CREATE POLICY "p1_subscriptions_delete_own"
      ON public.subscriptions FOR DELETE
      USING (owner_id = auth.uid())';
  END IF;

  -- subscription_members
  IF to_regclass('public.subscription_members') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "p1_subscription_members_select_owner_scope" ON public.subscription_members';
    EXECUTE 'CREATE POLICY "p1_subscription_members_select_owner_scope"
      ON public.subscription_members FOR SELECT
      USING (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = subscription_members.subscription_id
            AND s.owner_id = auth.uid()
        )
      )';

    EXECUTE 'DROP POLICY IF EXISTS "p1_subscription_members_insert_owner_scope" ON public.subscription_members';
    EXECUTE 'CREATE POLICY "p1_subscription_members_insert_owner_scope"
      ON public.subscription_members FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = subscription_members.subscription_id
            AND s.owner_id = auth.uid()
        )
      )';

    EXECUTE 'DROP POLICY IF EXISTS "p1_subscription_members_update_owner_scope" ON public.subscription_members';
    EXECUTE 'CREATE POLICY "p1_subscription_members_update_owner_scope"
      ON public.subscription_members FOR UPDATE
      USING (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = subscription_members.subscription_id
            AND s.owner_id = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = subscription_members.subscription_id
            AND s.owner_id = auth.uid()
        )
      )';

    EXECUTE 'DROP POLICY IF EXISTS "p1_subscription_members_delete_owner_scope" ON public.subscription_members';
    EXECUTE 'CREATE POLICY "p1_subscription_members_delete_owner_scope"
      ON public.subscription_members FOR DELETE
      USING (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = subscription_members.subscription_id
            AND s.owner_id = auth.uid()
        )
      )';
  END IF;

  -- payment_history
  IF to_regclass('public.payment_history') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "p1_payment_history_select_owner_scope" ON public.payment_history';
    EXECUTE 'CREATE POLICY "p1_payment_history_select_owner_scope"
      ON public.payment_history FOR SELECT
      USING (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = payment_history.subscription_id
            AND s.owner_id = auth.uid()
        )
      )';

    EXECUTE 'DROP POLICY IF EXISTS "p1_payment_history_insert_owner_scope" ON public.payment_history';
    EXECUTE 'CREATE POLICY "p1_payment_history_insert_owner_scope"
      ON public.payment_history FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = payment_history.subscription_id
            AND s.owner_id = auth.uid()
        )
        AND marked_by = auth.uid()
      )';

    EXECUTE 'DROP POLICY IF EXISTS "p1_payment_history_update_owner_scope" ON public.payment_history';
    EXECUTE 'CREATE POLICY "p1_payment_history_update_owner_scope"
      ON public.payment_history FOR UPDATE
      USING (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = payment_history.subscription_id
            AND s.owner_id = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = payment_history.subscription_id
            AND s.owner_id = auth.uid()
        )
        AND marked_by = auth.uid()
      )';

    EXECUTE 'DROP POLICY IF EXISTS "p1_payment_history_delete_owner_scope" ON public.payment_history';
    EXECUTE 'CREATE POLICY "p1_payment_history_delete_owner_scope"
      ON public.payment_history FOR DELETE
      USING (
        EXISTS (
          SELECT 1
          FROM public.subscriptions s
          WHERE s.id = payment_history.subscription_id
            AND s.owner_id = auth.uid()
        )
      )';
  END IF;

  -- contacts
  IF to_regclass('public.contacts') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "p1_contacts_select_own" ON public.contacts';
    EXECUTE 'CREATE POLICY "p1_contacts_select_own"
      ON public.contacts FOR SELECT
      USING (user_id = auth.uid())';

    EXECUTE 'DROP POLICY IF EXISTS "p1_contacts_insert_own" ON public.contacts';
    EXECUTE 'CREATE POLICY "p1_contacts_insert_own"
      ON public.contacts FOR INSERT
      WITH CHECK (user_id = auth.uid())';

    EXECUTE 'DROP POLICY IF EXISTS "p1_contacts_update_own" ON public.contacts';
    EXECUTE 'CREATE POLICY "p1_contacts_update_own"
      ON public.contacts FOR UPDATE
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid())';

    EXECUTE 'DROP POLICY IF EXISTS "p1_contacts_delete_own" ON public.contacts';
    EXECUTE 'CREATE POLICY "p1_contacts_delete_own"
      ON public.contacts FOR DELETE
      USING (user_id = auth.uid())';
  END IF;
END $$;

-- Recreate payment history SECURITY DEFINER RPCs with explicit ownership checks.
CREATE OR REPLACE FUNCTION mark_payment_as_paid_atomic(
  p_subscription_id UUID,
  p_member_id UUID,
  p_amount DECIMAL,
  p_payment_date TIMESTAMPTZ,
  p_marked_by UUID,
  p_notes TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT 'cash'
)
RETURNS TABLE(
  payment_history_id UUID,
  member_id UUID,
  member_name TEXT,
  subscription_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_id UUID;
  v_subscription_owner_id UUID;
  v_member_name TEXT;
  v_subscription_name TEXT;
  v_payment_history_id UUID;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_marked_by IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Marked-by user does not match auth.uid()';
  END IF;

  SELECT s.owner_id, sm.user_name, s.name
  INTO v_subscription_owner_id, v_member_name, v_subscription_name
  FROM public.subscription_members sm
  JOIN public.subscriptions s ON s.id = sm.subscription_id
  WHERE sm.id = p_member_id
    AND sm.subscription_id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member or subscription not found';
  END IF;

  IF v_subscription_owner_id IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Unauthorized subscription access';
  END IF;

  UPDATE public.subscription_members
  SET
    has_paid = true,
    last_payment_date = p_payment_date,
    updated_at = NOW()
  WHERE id = p_member_id
    AND subscription_id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription member update denied';
  END IF;

  INSERT INTO public.payment_history (
    id,
    subscription_id,
    member_id,
    member_name,
    subscription_name,
    amount,
    payment_date,
    marked_by,
    action,
    notes,
    payment_method,
    created_at
  ) VALUES (
    gen_random_uuid(),
    p_subscription_id,
    p_member_id,
    v_member_name,
    v_subscription_name,
    p_amount,
    p_payment_date,
    v_actor_id,
    'paid',
    p_notes,
    p_payment_method,
    NOW()
  )
  RETURNING id INTO v_payment_history_id;

  RETURN QUERY
  SELECT
    v_payment_history_id,
    p_member_id,
    v_member_name,
    v_subscription_name;
END;
$$;

CREATE OR REPLACE FUNCTION unmark_payment_atomic(
  p_subscription_id UUID,
  p_member_id UUID,
  p_amount DECIMAL,
  p_payment_date TIMESTAMPTZ,
  p_marked_by UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_id UUID;
  v_subscription_owner_id UUID;
  v_member_name TEXT;
  v_subscription_name TEXT;
  v_payment_history_id UUID;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_marked_by IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Marked-by user does not match auth.uid()';
  END IF;

  SELECT s.owner_id, sm.user_name, s.name
  INTO v_subscription_owner_id, v_member_name, v_subscription_name
  FROM public.subscription_members sm
  JOIN public.subscriptions s ON s.id = sm.subscription_id
  WHERE sm.id = p_member_id
    AND sm.subscription_id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member or subscription not found';
  END IF;

  IF v_subscription_owner_id IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Unauthorized subscription access';
  END IF;

  UPDATE public.subscription_members
  SET
    has_paid = false,
    updated_at = NOW()
  WHERE id = p_member_id
    AND subscription_id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription member update denied';
  END IF;

  INSERT INTO public.payment_history (
    id,
    subscription_id,
    member_id,
    member_name,
    subscription_name,
    amount,
    payment_date,
    marked_by,
    action,
    notes,
    created_at
  ) VALUES (
    gen_random_uuid(),
    p_subscription_id,
    p_member_id,
    v_member_name,
    v_subscription_name,
    p_amount,
    p_payment_date,
    v_actor_id,
    'unpaid',
    p_notes,
    NOW()
  )
  RETURNING id INTO v_payment_history_id;

  RETURN v_payment_history_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_payment_history_stats(
  p_subscription_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE(
  total_payments BIGINT,
  total_amount_paid DECIMAL,
  total_amount_unpaid DECIMAL,
  unique_payers BIGINT,
  payment_methods JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_id UUID;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.subscriptions s
    WHERE s.id = p_subscription_id
      AND s.owner_id = v_actor_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized subscription access';
  END IF;

  RETURN QUERY
  WITH payment_method_counts AS (
    SELECT
      payment_method,
      COUNT(*) AS method_count
    FROM public.payment_history
    WHERE subscription_id = p_subscription_id
      AND action = 'paid'
      AND payment_method IS NOT NULL
      AND (p_start_date IS NULL OR payment_date >= p_start_date)
      AND (p_end_date IS NULL OR payment_date <= p_end_date)
    GROUP BY payment_method
  )
  SELECT
    COUNT(*) FILTER (WHERE action = 'paid') AS total_payments,
    COALESCE(SUM(amount) FILTER (WHERE action = 'paid'), 0) AS total_amount_paid,
    COALESCE(SUM(amount) FILTER (WHERE action = 'unpaid'), 0) AS total_amount_unpaid,
    COUNT(DISTINCT member_id) FILTER (WHERE action = 'paid') AS unique_payers,
    COALESCE(
      (SELECT jsonb_object_agg(payment_method, method_count) FROM payment_method_counts),
      '{}'::jsonb
    ) AS payment_methods
  FROM public.payment_history
  WHERE subscription_id = p_subscription_id
    AND (p_start_date IS NULL OR payment_date >= p_start_date)
    AND (p_end_date IS NULL OR payment_date <= p_end_date);
END;
$$;
