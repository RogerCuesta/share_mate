-- ============================================================================
-- MIGRATION: Add updated_at field to subscriptions and subscription_members
-- ============================================================================
-- This migration adds the missing updated_at column to existing tables
-- Run this in Supabase SQL Editor if the tables were created without it
-- ============================================================================

-- Add updated_at column to subscriptions table (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'subscriptions'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE subscriptions
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();

        RAISE NOTICE 'Added updated_at column to subscriptions table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in subscriptions table';
    END IF;
END $$;

-- Add updated_at column to subscription_members table (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'subscription_members'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE subscription_members
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();

        RAISE NOTICE 'Added updated_at column to subscription_members table';
    ELSE
        RAISE NOTICE 'updated_at column already exists in subscription_members table';
    END IF;
END $$;

-- Ensure the trigger function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to subscriptions table (recreate to ensure it's correct)
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add trigger to subscription_members table (recreate to ensure it's correct)
DROP TRIGGER IF EXISTS update_subscription_members_updated_at ON subscription_members;
CREATE TRIGGER update_subscription_members_updated_at
    BEFORE UPDATE ON subscription_members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify the columns were added
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name IN ('subscriptions', 'subscription_members')
AND column_name = 'updated_at'
ORDER BY table_name;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
