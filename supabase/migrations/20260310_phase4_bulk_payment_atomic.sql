-- Phase 4: Atomic bulk payment marking to avoid member/history divergence.

DROP FUNCTION IF EXISTS public.mark_all_payments_as_paid_atomic(
  UUID,
  TIMESTAMPTZ,
  UUID,
  TEXT,
  TEXT
);

CREATE OR REPLACE FUNCTION public.mark_all_payments_as_paid_atomic(
  p_subscription_id UUID,
  p_payment_date TIMESTAMPTZ,
  p_marked_by UUID,
  p_notes TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT 'cash'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_actor_id UUID;
  v_subscription_owner_id UUID;
  v_subscription_name TEXT;
  v_updated_count INTEGER := 0;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_marked_by IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Marked-by user does not match auth.uid()';
  END IF;

  SELECT s.owner_id, s.name
  INTO v_subscription_owner_id, v_subscription_name
  FROM public.subscriptions s
  WHERE s.id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found';
  END IF;

  IF v_subscription_owner_id IS DISTINCT FROM v_actor_id THEN
    RAISE EXCEPTION 'Unauthorized subscription access';
  END IF;

  WITH target_members AS (
    SELECT
      sm.id,
      sm.user_name,
      sm.amount_to_pay
    FROM public.subscription_members sm
    WHERE sm.subscription_id = p_subscription_id
      AND sm.has_paid = false
    FOR UPDATE
  ),
  updated_members AS (
    UPDATE public.subscription_members sm
    SET
      has_paid = true,
      last_payment_date = p_payment_date,
      updated_at = NOW()
    FROM target_members tm
    WHERE sm.id = tm.id
    RETURNING sm.id
  ),
  inserted_history AS (
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
    )
    SELECT
      gen_random_uuid(),
      p_subscription_id,
      tm.id,
      tm.user_name,
      v_subscription_name,
      tm.amount_to_pay,
      p_payment_date,
      v_actor_id,
      'paid',
      p_notes,
      p_payment_method,
      '{}'::jsonb,
      NOW()
    FROM target_members tm
    RETURNING id
  )
  SELECT COUNT(*)
  INTO v_updated_count
  FROM updated_members;

  RETURN v_updated_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_all_payments_as_paid_atomic(
  UUID,
  TIMESTAMPTZ,
  UUID,
  TEXT,
  TEXT
) TO authenticated;
