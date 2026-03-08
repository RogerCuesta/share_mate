-- =====================================================
-- Migration: Phase 2 sync conflict reconciliation
-- Date: 2026-03-08
-- Requirement: SYNC-02
-- Purpose: Persist non-PII sync conflict audits and add
--          idempotency-key aware payment mutation RPCs.
-- =====================================================

-- Non-PII audit table for deterministic cycle-conflict outcomes.
CREATE TABLE IF NOT EXISTS public.payment_sync_conflict_audit (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  operation_id TEXT NOT NULL,
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.subscription_members(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('paid', 'unpaid')),
  terminal_reason TEXT NOT NULL,
  queued_cycle_due_date TIMESTAMPTZ NOT NULL,
  backend_cycle_due_date TIMESTAMPTZ NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
  idempotency_key TEXT NOT NULL,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_conflict_audit_subscription_created_at
  ON public.payment_sync_conflict_audit(subscription_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sync_conflict_audit_operation
  ON public.payment_sync_conflict_audit(operation_id);

ALTER TABLE IF EXISTS public.payment_sync_conflict_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payment_sync_conflict_audit FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p2_sync_conflict_audit_select_owner_scope"
  ON public.payment_sync_conflict_audit;

CREATE POLICY "p2_sync_conflict_audit_select_owner_scope"
  ON public.payment_sync_conflict_audit
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.subscriptions s
      WHERE s.id = payment_sync_conflict_audit.subscription_id
        AND s.owner_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.record_payment_sync_conflict_audit(
  p_operation_id TEXT,
  p_subscription_id UUID,
  p_member_id UUID,
  p_action TEXT,
  p_terminal_reason TEXT,
  p_queued_cycle_due_date TIMESTAMPTZ,
  p_backend_cycle_due_date TIMESTAMPTZ,
  p_retry_count INTEGER,
  p_idempotency_key TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_id UUID;
  v_subscription_owner_id UUID;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_action NOT IN ('paid', 'unpaid') THEN
    RAISE EXCEPTION 'Invalid action for sync conflict audit';
  END IF;

  IF p_terminal_reason IS DISTINCT FROM 'cycle_conflict_noop' THEN
    RAISE EXCEPTION 'Invalid terminal reason for sync conflict audit';
  END IF;

  SELECT s.owner_id
  INTO v_subscription_owner_id
  FROM public.subscriptions s
  WHERE s.id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found';
  END IF;

  IF v_subscription_owner_id IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Unauthorized subscription access';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.subscription_members sm
    WHERE sm.id = p_member_id
      AND sm.subscription_id = p_subscription_id
  ) THEN
    RAISE EXCEPTION 'Member or subscription not found';
  END IF;

  INSERT INTO public.payment_sync_conflict_audit (
    operation_id,
    subscription_id,
    member_id,
    action,
    terminal_reason,
    queued_cycle_due_date,
    backend_cycle_due_date,
    retry_count,
    idempotency_key,
    created_by
  ) VALUES (
    p_operation_id,
    p_subscription_id,
    p_member_id,
    p_action,
    p_terminal_reason,
    p_queued_cycle_due_date,
    p_backend_cycle_due_date,
    GREATEST(p_retry_count, 0),
    p_idempotency_key,
    v_actor_id
  );
END;
$$;

-- Optional uniqueness helper for idempotent sync replays.
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_history_sync_idempotency
  ON public.payment_history (
    subscription_id,
    member_id,
    action,
    ((metadata ->> 'sync_idempotency_key'))
  )
  WHERE metadata ? 'sync_idempotency_key';

DROP FUNCTION IF EXISTS public.mark_payment_as_paid_atomic(
  UUID,
  UUID,
  DECIMAL,
  TIMESTAMPTZ,
  UUID,
  TEXT,
  TEXT
);

CREATE OR REPLACE FUNCTION public.mark_payment_as_paid_atomic(
  p_subscription_id UUID,
  p_member_id UUID,
  p_amount DECIMAL,
  p_payment_date TIMESTAMPTZ,
  p_marked_by UUID,
  p_notes TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT 'cash',
  p_idempotency_key TEXT DEFAULT NULL
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

  IF p_idempotency_key IS NOT NULL THEN
    SELECT ph.id
    INTO v_payment_history_id
    FROM public.payment_history ph
    WHERE ph.subscription_id = p_subscription_id
      AND ph.member_id = p_member_id
      AND ph.action = 'paid'
      AND ph.metadata ->> 'sync_idempotency_key' = p_idempotency_key
    ORDER BY ph.created_at DESC
    LIMIT 1;

    IF FOUND THEN
      RETURN QUERY
      SELECT
        v_payment_history_id,
        p_member_id,
        v_member_name,
        v_subscription_name;
      RETURN;
    END IF;
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
    metadata,
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
    CASE
      WHEN p_idempotency_key IS NULL THEN '{}'::jsonb
      ELSE jsonb_build_object('sync_idempotency_key', p_idempotency_key)
    END,
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

CREATE OR REPLACE FUNCTION public.unmark_payment_atomic(
  p_subscription_id UUID,
  p_member_id UUID,
  p_amount DECIMAL,
  p_payment_date TIMESTAMPTZ,
  p_marked_by UUID,
  p_notes TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
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

  IF p_idempotency_key IS NOT NULL THEN
    SELECT ph.id
    INTO v_payment_history_id
    FROM public.payment_history ph
    WHERE ph.subscription_id = p_subscription_id
      AND ph.member_id = p_member_id
      AND ph.action = 'unpaid'
      AND ph.metadata ->> 'sync_idempotency_key' = p_idempotency_key
    ORDER BY ph.created_at DESC
    LIMIT 1;

    IF FOUND THEN
      RETURN v_payment_history_id;
    END IF;
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
    metadata,
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
    CASE
      WHEN p_idempotency_key IS NULL THEN '{}'::jsonb
      ELSE jsonb_build_object('sync_idempotency_key', p_idempotency_key)
    END,
    NOW()
  )
  RETURNING id INTO v_payment_history_id;

  RETURN v_payment_history_id;
END;
$$;

DROP FUNCTION IF EXISTS public.unmark_payment_atomic(
  UUID,
  UUID,
  DECIMAL,
  TIMESTAMPTZ,
  UUID,
  TEXT
);

GRANT EXECUTE ON FUNCTION public.record_payment_sync_conflict_audit(
  TEXT,
  UUID,
  UUID,
  TEXT,
  TEXT,
  TIMESTAMPTZ,
  TIMESTAMPTZ,
  INTEGER,
  TEXT
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_payment_as_paid_atomic(
  UUID,
  UUID,
  DECIMAL,
  TIMESTAMPTZ,
  UUID,
  TEXT,
  TEXT,
  TEXT
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unmark_payment_atomic(
  UUID,
  UUID,
  DECIMAL,
  TIMESTAMPTZ,
  UUID,
  TEXT,
  TEXT
) TO authenticated;
