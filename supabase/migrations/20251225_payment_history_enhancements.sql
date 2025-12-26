-- =====================================================
-- Migration: Payment History Enhancements
-- Date: 2025-12-25
-- Purpose: Add denormalization, atomic operations, stats
-- =====================================================

-- 1. Agregar columnas denormalizadas para audit trail
ALTER TABLE payment_history
  ADD COLUMN IF NOT EXISTS member_name TEXT,
  ADD COLUMN IF NOT EXISTS subscription_name TEXT,
  ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash',
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- 2. Backfill datos existentes usando subconsulta
UPDATE payment_history ph
SET
  member_name = subq.user_name,
  subscription_name = subq.sub_name
FROM (
  SELECT
    sm.id as member_id,
    sm.subscription_id,
    sm.user_name,
    s.name as sub_name
  FROM subscription_members sm
  JOIN subscriptions s ON s.id = sm.subscription_id
) subq
WHERE ph.member_id = subq.member_id
  AND ph.subscription_id = subq.subscription_id
  AND ph.member_name IS NULL;

-- 3. RPC: Mark Payment as Paid (ATOMIC)
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
SECURITY DEFINER  -- Ejecuta con permisos del creador
AS $$
DECLARE
  v_member_name TEXT;
  v_subscription_name TEXT;
  v_payment_history_id UUID;
BEGIN
  -- Obtener nombres para denormalizar
  SELECT sm.user_name, s.name
  INTO v_member_name, v_subscription_name
  FROM subscription_members sm
  JOIN subscriptions s ON s.id = sm.subscription_id
  WHERE sm.id = p_member_id
    AND sm.subscription_id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member or subscription not found';
  END IF;

  -- OPERACIÓN 1: Update member (dentro de transacción)
  UPDATE subscription_members
  SET
    has_paid = true,
    last_payment_date = p_payment_date,
    updated_at = NOW()
  WHERE id = p_member_id;

  -- OPERACIÓN 2: Insert payment history (dentro de transacción)
  INSERT INTO payment_history (
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
    p_marked_by,
    'paid',
    p_notes,
    p_payment_method,
    NOW()
  )
  RETURNING id INTO v_payment_history_id;

  -- Retornar datos
  RETURN QUERY
  SELECT
    v_payment_history_id,
    p_member_id,
    v_member_name,
    v_subscription_name;
END;
$$;

-- 4. RPC: Unmark Payment (ATOMIC)
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
AS $$
DECLARE
  v_member_name TEXT;
  v_subscription_name TEXT;
  v_payment_history_id UUID;
BEGIN
  -- Obtener nombres para denormalizar
  SELECT sm.user_name, s.name
  INTO v_member_name, v_subscription_name
  FROM subscription_members sm
  JOIN subscriptions s ON s.id = sm.subscription_id
  WHERE sm.id = p_member_id
    AND sm.subscription_id = p_subscription_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Member or subscription not found';
  END IF;

  -- Update member
  UPDATE subscription_members
  SET
    has_paid = false,
    updated_at = NOW()
  WHERE id = p_member_id;

  -- Insert payment history
  INSERT INTO payment_history (
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
    p_marked_by,
    'unpaid',
    p_notes,
    NOW()
  )
  RETURNING id INTO v_payment_history_id;

  RETURN v_payment_history_id;
END;
$$;

-- 5. RPC: Get Payment History Stats
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
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE action = 'paid') AS total_payments,
    COALESCE(SUM(amount) FILTER (WHERE action = 'paid'), 0) AS total_amount_paid,
    COALESCE(SUM(amount) FILTER (WHERE action = 'unpaid'), 0) AS total_amount_unpaid,
    COUNT(DISTINCT member_id) FILTER (WHERE action = 'paid') AS unique_payers,
    jsonb_object_agg(
      payment_method,
      COUNT(*) FILTER (WHERE action = 'paid')
    ) FILTER (WHERE payment_method IS NOT NULL) AS payment_methods
  FROM payment_history
  WHERE subscription_id = p_subscription_id
    AND (p_start_date IS NULL OR payment_date >= p_start_date)
    AND (p_end_date IS NULL OR payment_date <= p_end_date);
END;
$$;

-- 6. Índice para búsquedas con filtros
CREATE INDEX IF NOT EXISTS idx_payment_history_member_name
  ON payment_history(subscription_id, member_name);

CREATE INDEX IF NOT EXISTS idx_payment_history_action
  ON payment_history(subscription_id, action);

-- 7. Grants (ajustar según políticas RLS)
GRANT EXECUTE ON FUNCTION mark_payment_as_paid_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION unmark_payment_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION get_payment_history_stats TO authenticated;
