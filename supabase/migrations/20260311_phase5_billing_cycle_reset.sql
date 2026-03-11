-- =====================================================
-- Migration: Phase 5 billing cycle reset
-- Date: 2026-03-11
-- Requirements: BILL-03
-- Purpose: Make backend billing-cycle resets canonical and auditable,
--          then expose the latest reset marker for deterministic client
--          reconciliation after app resume/sync.
-- =====================================================

CREATE TABLE IF NOT EXISTS public.billing_cycle_resets (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  batch_id UUID NOT NULL,
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  previous_due_date TIMESTAMPTZ NOT NULL,
  next_due_date TIMESTAMPTZ NOT NULL,
  billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly', 'yearly')),
  processed_member_count INTEGER NOT NULL DEFAULT 0 CHECK (processed_member_count >= 0),
  reset_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  executed_by TEXT NOT NULL DEFAULT 'system',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (batch_id, subscription_id)
);

CREATE INDEX IF NOT EXISTS idx_billing_cycle_resets_subscription_reset_at
  ON public.billing_cycle_resets(subscription_id, reset_at DESC);

CREATE INDEX IF NOT EXISTS idx_billing_cycle_resets_batch
  ON public.billing_cycle_resets(batch_id);

ALTER TABLE IF EXISTS public.billing_cycle_resets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.billing_cycle_resets FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p5_billing_cycle_resets_select_owner_scope"
  ON public.billing_cycle_resets;

CREATE POLICY "p5_billing_cycle_resets_select_owner_scope"
  ON public.billing_cycle_resets
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.subscriptions s
      WHERE s.id = billing_cycle_resets.subscription_id
        AND s.owner_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.billing_cycle_next_due_date(
  p_due_date TIMESTAMPTZ,
  p_billing_cycle TEXT,
  p_billing_anchor_day INTEGER
)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
AS $$
DECLARE
  v_base_utc TIMESTAMP;
  v_target_utc TIMESTAMP;
  v_anchor_day INTEGER;
  v_max_day INTEGER;
  v_seconds INTEGER;
BEGIN
  v_base_utc := timezone('UTC', p_due_date);
  v_target_utc := CASE
    WHEN p_billing_cycle = 'yearly' THEN v_base_utc + INTERVAL '1 year'
    ELSE v_base_utc + INTERVAL '1 month'
  END;

  v_anchor_day := GREATEST(
    1,
    LEAST(31, COALESCE(p_billing_anchor_day, EXTRACT(DAY FROM v_base_utc)::INTEGER))
  );
  v_max_day := EXTRACT(
    DAY FROM (
      date_trunc('month', v_target_utc) + INTERVAL '1 month - 1 day'
    )
  )::INTEGER;
  v_seconds := FLOOR(EXTRACT(SECOND FROM v_base_utc))::INTEGER;

  RETURN make_timestamptz(
    EXTRACT(YEAR FROM v_target_utc)::INTEGER,
    EXTRACT(MONTH FROM v_target_utc)::INTEGER,
    LEAST(v_anchor_day, v_max_day),
    EXTRACT(HOUR FROM v_base_utc)::INTEGER,
    EXTRACT(MINUTE FROM v_base_utc)::INTEGER,
    v_seconds,
    'UTC'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.run_billing_cycle_resets(
  p_now TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE(
  batch_id UUID,
  subscription_id UUID,
  previous_due_date TIMESTAMPTZ,
  next_due_date TIMESTAMPTZ,
  reset_at TIMESTAMPTZ,
  processed_member_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_batch_id UUID := gen_random_uuid();
  v_executed_by TEXT := COALESCE(auth.uid()::TEXT, 'pg_cron');
BEGIN
  RETURN QUERY
  WITH due_subscriptions AS (
    SELECT
      s.id AS subscription_id,
      s.due_date AS previous_due_date,
      public.billing_cycle_next_due_date(
        s.due_date,
        s.billing_cycle,
        s.billing_anchor_day
      ) AS next_due_date,
      s.billing_cycle
    FROM public.subscriptions s
    WHERE s.status = 'active'
      AND s.due_date <= p_now
  ),
  updated_subscriptions AS (
    UPDATE public.subscriptions s
    SET
      due_date = ds.next_due_date,
      updated_at = NOW()
    FROM due_subscriptions ds
    WHERE s.id = ds.subscription_id
    RETURNING
      ds.subscription_id,
      ds.previous_due_date,
      ds.next_due_date,
      ds.billing_cycle
  ),
  updated_members AS (
    UPDATE public.subscription_members sm
    SET
      has_paid=false,
      last_payment_date = NULL,
      due_date = us.next_due_date,
      updated_at = NOW()
    FROM updated_subscriptions us
    WHERE sm.subscription_id = us.subscription_id
    RETURNING sm.subscription_id
  ),
  member_counts AS (
    SELECT
      us.subscription_id,
      COUNT(um.subscription_id)::INTEGER AS processed_member_count
    FROM updated_subscriptions us
    LEFT JOIN updated_members um
      ON um.subscription_id = us.subscription_id
    GROUP BY us.subscription_id
  ),
  inserted_audit AS (
    INSERT INTO public.billing_cycle_resets (
      batch_id,
      subscription_id,
      previous_due_date,
      next_due_date,
      billing_cycle,
      processed_member_count,
      reset_at,
      executed_by
    )
    SELECT
      v_batch_id,
      us.subscription_id,
      us.previous_due_date,
      us.next_due_date,
      us.billing_cycle,
      COALESCE(mc.processed_member_count, 0),
      p_now,
      v_executed_by
    FROM updated_subscriptions us
    LEFT JOIN member_counts mc
      ON mc.subscription_id = us.subscription_id
    RETURNING
      billing_cycle_resets.batch_id,
      billing_cycle_resets.subscription_id,
      billing_cycle_resets.previous_due_date,
      billing_cycle_resets.next_due_date,
      billing_cycle_resets.reset_at,
      billing_cycle_resets.processed_member_count
  )
  SELECT
    inserted_audit.batch_id,
    inserted_audit.subscription_id,
    inserted_audit.previous_due_date,
    inserted_audit.next_due_date,
    inserted_audit.reset_at,
    inserted_audit.processed_member_count
  FROM inserted_audit;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_latest_billing_cycle_reset(
  p_subscription_id UUID DEFAULT NULL
)
RETURNS TABLE(
  batch_id UUID,
  subscription_id UUID,
  previous_due_date TIMESTAMPTZ,
  next_due_date TIMESTAMPTZ,
  reset_at TIMESTAMPTZ,
  processed_member_count INTEGER
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
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    r.batch_id,
    r.subscription_id,
    r.previous_due_date,
    r.next_due_date,
    r.reset_at,
    r.processed_member_count
  FROM public.billing_cycle_resets r
  JOIN public.subscriptions s
    ON s.id = r.subscription_id
  WHERE s.owner_id = v_actor_id
    AND (p_subscription_id IS NULL OR r.subscription_id = p_subscription_id)
  ORDER BY r.reset_at DESC, r.id DESC
  LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.billing_cycle_next_due_date(TIMESTAMPTZ, TEXT, INTEGER)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.run_billing_cycle_resets(TIMESTAMPTZ)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_latest_billing_cycle_reset(UUID)
  TO authenticated, service_role;

-- pg_cron scheduler contract (enable separately in managed environments):
--   SELECT cron.schedule(
--     'share_mate_billing_cycle_reset_hourly',
--     '5 * * * *',
--     $$SELECT public.run_billing_cycle_resets();$$
--   );
