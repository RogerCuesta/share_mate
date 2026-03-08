-- =====================================================
-- Migration: Phase 3 Subscription Setup Foundations
-- Date: 2026-03-09
-- Purpose:
--  - Add canonical catalog source: service_templates
--  - Allow local contacts without email
--  - Allow subscription_members.user_email to be nullable
--  - Add contact color metadata for quick-create UX
--  - Persist subscriptions.billing_anchor_day for deterministic month rollover
-- =====================================================

-- =====================================================
-- 1) Service templates catalog table
-- =====================================================

create table if not exists service_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    logo_url TEXT,
    brand_color TEXT,
    aliases TEXT[] NOT NULL DEFAULT '{}',
    search_terms TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

    CONSTRAINT service_templates_name_not_blank
        CHECK (length(trim(BOTH FROM name)) > 0),
    CONSTRAINT service_templates_brand_color_hex
        CHECK (
            brand_color IS NULL
            OR brand_color ~* '^#([0-9A-F]{6}|[0-9A-F]{8})$'
        )
);

CREATE INDEX IF NOT EXISTS idx_service_templates_active
    ON public.service_templates (is_active);

CREATE INDEX IF NOT EXISTS idx_service_templates_name_lower
    ON public.service_templates (lower(name));

CREATE INDEX IF NOT EXISTS idx_service_templates_aliases_gin
    ON public.service_templates USING gin (aliases);

CREATE INDEX IF NOT EXISTS idx_service_templates_search_terms_gin
    ON public.service_templates USING gin (search_terms);

CREATE OR REPLACE FUNCTION public.update_service_templates_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_service_templates_update ON public.service_templates;
CREATE TRIGGER on_service_templates_update
    BEFORE UPDATE ON public.service_templates
    FOR EACH ROW
    EXECUTE FUNCTION public.update_service_templates_updated_at();

ALTER TABLE public.service_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_templates FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "p3_service_templates_select_authenticated" ON public.service_templates;
CREATE POLICY "p3_service_templates_select_authenticated"
    ON public.service_templates
    FOR SELECT
    TO authenticated
    USING (is_active = TRUE);

GRANT SELECT ON public.service_templates TO authenticated;

-- =====================================================
-- 2) Contacts: allow nullable contact_email + add color metadata
-- =====================================================

ALTER TABLE IF EXISTS public.contacts
    ADD COLUMN IF NOT EXISTS contact_color TEXT;

ALTER TABLE IF EXISTS public.contacts
    ALTER COLUMN contact_email DROP NOT NULL;

ALTER TABLE IF EXISTS public.contacts
    DROP CONSTRAINT IF EXISTS contacts_email_format;

ALTER TABLE IF EXISTS public.contacts
    ADD CONSTRAINT contacts_email_format
    CHECK (
        contact_email IS NULL
        OR contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    );

ALTER TABLE IF EXISTS public.contacts
    DROP CONSTRAINT IF EXISTS contacts_unique_email_per_user;

DROP INDEX IF EXISTS idx_contacts_email;
CREATE UNIQUE INDEX IF NOT EXISTS idx_contacts_unique_non_null_email_per_user
    ON public.contacts (user_id, lower(contact_email))
    WHERE contact_email IS NOT NULL;

ALTER TABLE IF EXISTS public.contacts
    DROP CONSTRAINT IF EXISTS contacts_color_hex;

ALTER TABLE IF EXISTS public.contacts
    ADD CONSTRAINT contacts_color_hex
    CHECK (
        contact_color IS NULL
        OR contact_color ~* '^#([0-9A-F]{6}|[0-9A-F]{8})$'
    );

-- =====================================================
-- 3) Subscription members: allow nullable user_email
-- =====================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'subscription_members'
          AND column_name = 'user_email'
    ) THEN
        ALTER TABLE public.subscription_members
            ALTER COLUMN user_email DROP NOT NULL;

        UPDATE public.subscription_members
        SET user_email = NULL
        WHERE NULLIF(trim(BOTH FROM user_email), '') IS NULL;
    END IF;
END
$$;

-- =====================================================
-- 4) Subscriptions: persist billing_anchor_day with backfill
-- =====================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'subscriptions'
          AND column_name = 'due_date'
    ) THEN
        ALTER TABLE public.subscriptions
            ADD COLUMN IF NOT EXISTS billing_anchor_day INTEGER;

        UPDATE public.subscriptions
        SET billing_anchor_day = GREATEST(
            1,
            LEAST(31, EXTRACT(DAY FROM due_date)::INTEGER)
        )
        WHERE billing_anchor_day IS NULL;

        ALTER TABLE public.subscriptions
            DROP CONSTRAINT IF EXISTS subscriptions_billing_anchor_day_range;

        ALTER TABLE public.subscriptions
            ADD CONSTRAINT subscriptions_billing_anchor_day_range
            CHECK (billing_anchor_day BETWEEN 1 AND 31);

        ALTER TABLE public.subscriptions
            ALTER COLUMN billing_anchor_day SET NOT NULL;
    END IF;
END
$$;
