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
