-- ============================================================================
-- SUPABASE SCHEMA FOR SUBMATE APP
-- ============================================================================
-- This schema creates all necessary tables, indexes, RLS policies, and
-- functions for the SubMate subscription management application.
--
-- FEATURES:
-- - User authentication (handled by Supabase Auth)
-- - Subscriptions (personal and group)
-- - Subscription members (for split billing)
-- - Row Level Security (RLS) for data isolation
-- - Automatic timestamp management with triggers
-- - Cascade deletes for data integrity
--
-- EXECUTION:
-- Run this script in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ============================================================================

-- ============================================================================
-- 1. ENABLE REQUIRED EXTENSIONS
-- ============================================================================

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 2. CREATE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 SUBSCRIPTIONS TABLE
-- ----------------------------------------------------------------------------
-- Stores subscription information (both personal and group subscriptions)
--
-- Fields:
-- - id: Unique identifier (UUID)
-- - owner_id: User who created the subscription (references auth.users)
-- - name: Subscription name (e.g., "Netflix", "Spotify Family")
-- - icon_url: Optional URL/identifier for service icon
-- - color: Hex color code for UI display (e.g., "#FF0000")
-- - total_cost: Total subscription cost (before splitting)
-- - billing_cycle: 'monthly' or 'yearly'
-- - due_date: Next payment due date
-- - status: 'active', 'paused', or 'cancelled'
-- - created_at: Timestamp when subscription was created
-- - updated_at: Timestamp when subscription was last modified
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    icon_url TEXT,
    color VARCHAR(7) NOT NULL DEFAULT '#6C63FF',
    total_cost DECIMAL(10, 2) NOT NULL CHECK (total_cost > 0),
    billing_cycle VARCHAR(20) NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add comment to table
COMMENT ON TABLE subscriptions IS 'Stores subscription information for both personal and group subscriptions';

-- Add comments to important columns
COMMENT ON COLUMN subscriptions.owner_id IS 'User who created and manages this subscription';
COMMENT ON COLUMN subscriptions.total_cost IS 'Total subscription cost before splitting among members';
COMMENT ON COLUMN subscriptions.billing_cycle IS 'Payment frequency: monthly or yearly';
COMMENT ON COLUMN subscriptions.status IS 'Current status: active, paused, or cancelled';

-- ----------------------------------------------------------------------------
-- 2.2 SUBSCRIPTION MEMBERS TABLE
-- ----------------------------------------------------------------------------
-- Stores members who share a subscription (for group subscriptions)
--
-- Fields:
-- - id: Unique identifier (UUID)
-- - subscription_id: Reference to parent subscription
-- - user_id: Member user ID (can be real user or placeholder for non-registered users)
-- - user_name: Display name for the member
-- - user_email: Email address for the member
-- - user_avatar: Optional avatar URL
-- - amount_to_pay: Amount this member needs to pay (calculated split)
-- - has_paid: Whether this member has paid for current billing cycle
-- - last_payment_date: Timestamp of last payment
-- - due_date: Payment due date for this member
-- - created_at: Timestamp when member was added
-- - updated_at: Timestamp when member info was last modified
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS subscription_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    user_avatar TEXT,
    amount_to_pay DECIMAL(10, 2) NOT NULL CHECK (amount_to_pay >= 0),
    has_paid BOOLEAN NOT NULL DEFAULT FALSE,
    last_payment_date TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add comment to table
COMMENT ON TABLE subscription_members IS 'Stores members who share group subscriptions';

-- Add comments to important columns
COMMENT ON COLUMN subscription_members.user_id IS 'User ID (can be placeholder for non-registered users)';
COMMENT ON COLUMN subscription_members.amount_to_pay IS 'Calculated split amount for this member';
COMMENT ON COLUMN subscription_members.has_paid IS 'Payment status for current billing cycle';

-- ============================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Subscriptions indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_owner_id ON subscriptions(owner_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_due_date ON subscriptions(due_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_created_at ON subscriptions(created_at DESC);

-- Subscription members indexes
CREATE INDEX IF NOT EXISTS idx_subscription_members_subscription_id ON subscription_members(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_members_user_id ON subscription_members(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_members_has_paid ON subscription_members(has_paid);
CREATE INDEX IF NOT EXISTS idx_subscription_members_due_date ON subscription_members(due_date);

-- Composite index for common query: get unpaid members for a subscription
CREATE INDEX IF NOT EXISTS idx_subscription_members_sub_unpaid
    ON subscription_members(subscription_id, has_paid);

-- ============================================================================
-- 4. CREATE TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- ============================================================================

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to subscriptions table
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to subscription_members table
DROP TRIGGER IF EXISTS update_subscription_members_updated_at ON subscription_members;
CREATE TRIGGER update_subscription_members_updated_at
    BEFORE UPDATE ON subscription_members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_members ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. CREATE RLS POLICIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6.1 SUBSCRIPTIONS POLICIES
-- ----------------------------------------------------------------------------

-- Policy: Users can SELECT their own subscriptions
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON subscriptions;
CREATE POLICY "Users can view their own subscriptions"
    ON subscriptions FOR SELECT
    USING (auth.uid() = owner_id);

-- Policy: Users can INSERT their own subscriptions
DROP POLICY IF EXISTS "Users can create their own subscriptions" ON subscriptions;
CREATE POLICY "Users can create their own subscriptions"
    ON subscriptions FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can UPDATE their own subscriptions
DROP POLICY IF EXISTS "Users can update their own subscriptions" ON subscriptions;
CREATE POLICY "Users can update their own subscriptions"
    ON subscriptions FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can DELETE their own subscriptions
DROP POLICY IF EXISTS "Users can delete their own subscriptions" ON subscriptions;
CREATE POLICY "Users can delete their own subscriptions"
    ON subscriptions FOR DELETE
    USING (auth.uid() = owner_id);

-- ----------------------------------------------------------------------------
-- 6.2 SUBSCRIPTION MEMBERS POLICIES
-- ----------------------------------------------------------------------------

-- Policy: Users can SELECT members from their own subscriptions
DROP POLICY IF EXISTS "Users can view members of their subscriptions" ON subscription_members;
CREATE POLICY "Users can view members of their subscriptions"
    ON subscription_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM subscriptions
            WHERE subscriptions.id = subscription_members.subscription_id
            AND subscriptions.owner_id = auth.uid()
        )
    );

-- Policy: Users can INSERT members to their own subscriptions
DROP POLICY IF EXISTS "Users can add members to their subscriptions" ON subscription_members;
CREATE POLICY "Users can add members to their subscriptions"
    ON subscription_members FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM subscriptions
            WHERE subscriptions.id = subscription_members.subscription_id
            AND subscriptions.owner_id = auth.uid()
        )
    );

-- Policy: Users can UPDATE members of their own subscriptions
DROP POLICY IF EXISTS "Users can update members of their subscriptions" ON subscription_members;
CREATE POLICY "Users can update members of their subscriptions"
    ON subscription_members FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM subscriptions
            WHERE subscriptions.id = subscription_members.subscription_id
            AND subscriptions.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM subscriptions
            WHERE subscriptions.id = subscription_members.subscription_id
            AND subscriptions.owner_id = auth.uid()
        )
    );

-- Policy: Users can DELETE members from their own subscriptions
DROP POLICY IF EXISTS "Users can remove members from their subscriptions" ON subscription_members;
CREATE POLICY "Users can remove members from their subscriptions"
    ON subscription_members FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM subscriptions
            WHERE subscriptions.id = subscription_members.subscription_id
            AND subscriptions.owner_id = auth.uid()
        )
    );

-- ============================================================================
-- 7. CREATE HELPER FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 7.1 FUNCTION: Calculate monthly statistics for a user
-- ----------------------------------------------------------------------------
-- Returns aggregated statistics for dashboard display
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_monthly_stats(user_id UUID)
RETURNS TABLE (
    total_monthly_cost DECIMAL(10, 2),
    pending_to_collect DECIMAL(10, 2),
    active_subscriptions_count INTEGER,
    overdue_payments_count INTEGER,
    collected_amount DECIMAL(10, 2),
    paid_members_count INTEGER,
    unpaid_members_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH active_subs AS (
        SELECT
            s.id,
            CASE
                WHEN s.billing_cycle = 'yearly' THEN s.total_cost / 12
                ELSE s.total_cost
            END AS monthly_cost
        FROM subscriptions s
        WHERE s.owner_id = user_id
        AND s.status = 'active'
    ),
    member_stats AS (
        SELECT
            COUNT(*) FILTER (WHERE sm.has_paid = FALSE) AS unpaid_count,
            COUNT(*) FILTER (WHERE sm.has_paid = TRUE) AS paid_count,
            COALESCE(SUM(sm.amount_to_pay) FILTER (WHERE sm.has_paid = FALSE), 0) AS pending_amount,
            COALESCE(SUM(sm.amount_to_pay) FILTER (WHERE sm.has_paid = TRUE), 0) AS collected_amount,
            COUNT(*) FILTER (WHERE sm.has_paid = FALSE AND sm.due_date < NOW()) AS overdue_count
        FROM subscription_members sm
        INNER JOIN subscriptions s ON sm.subscription_id = s.id
        WHERE s.owner_id = user_id
        AND s.status = 'active'
    )
    SELECT
        COALESCE((SELECT SUM(monthly_cost) FROM active_subs), 0)::DECIMAL(10, 2) AS total_monthly_cost,
        ms.pending_amount::DECIMAL(10, 2) AS pending_to_collect,
        (SELECT COUNT(*) FROM active_subs)::INTEGER AS active_subscriptions_count,
        ms.overdue_count::INTEGER AS overdue_payments_count,
        ms.collected_amount::DECIMAL(10, 2) AS collected_amount,
        ms.paid_count::INTEGER AS paid_members_count,
        ms.unpaid_count::INTEGER AS unpaid_members_count
    FROM member_stats ms;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to function
COMMENT ON FUNCTION get_monthly_stats(UUID) IS 'Calculate aggregated monthly statistics for a user dashboard';

-- ============================================================================
-- 8. SEED DATA FOR TESTING (OPTIONAL - COMMENT OUT FOR PRODUCTION)
-- ============================================================================

-- Uncomment the section below to insert sample data for testing
/*
-- Note: Replace 'YOUR_USER_UUID' with actual user ID from auth.users table
-- You can get this from Supabase Auth Dashboard or by running:
-- SELECT id FROM auth.users LIMIT 1;

DO $$
DECLARE
    test_user_id UUID := 'YOUR_USER_UUID'; -- REPLACE WITH REAL USER ID
    netflix_sub_id UUID;
    spotify_sub_id UUID;
BEGIN
    -- Insert sample subscription 1: Netflix (personal)
    INSERT INTO subscriptions (id, owner_id, name, icon_url, color, total_cost, billing_cycle, due_date, status)
    VALUES (
        uuid_generate_v4(),
        test_user_id,
        'Netflix',
        'netflix',
        '#E50914',
        15.99,
        'monthly',
        NOW() + INTERVAL '15 days',
        'active'
    ) RETURNING id INTO netflix_sub_id;

    -- Insert sample subscription 2: Spotify Family (group)
    INSERT INTO subscriptions (id, owner_id, name, icon_url, color, total_cost, billing_cycle, due_date, status)
    VALUES (
        uuid_generate_v4(),
        test_user_id,
        'Spotify Family',
        'spotify',
        '#1DB954',
        19.99,
        'monthly',
        NOW() + INTERVAL '20 days',
        'active'
    ) RETURNING id INTO spotify_sub_id;

    -- Add members to Spotify Family subscription
    INSERT INTO subscription_members (subscription_id, user_id, user_name, user_email, amount_to_pay, has_paid, due_date)
    VALUES
        (spotify_sub_id, uuid_generate_v4(), 'John Doe', 'john@example.com', 6.66, FALSE, NOW() + INTERVAL '20 days'),
        (spotify_sub_id, uuid_generate_v4(), 'Jane Smith', 'jane@example.com', 6.66, TRUE, NOW() + INTERVAL '20 days');

    RAISE NOTICE 'Sample data inserted successfully!';
END $$;
*/

-- ============================================================================
-- 9. VERIFICATION QUERIES (RUN AFTER SCHEMA CREATION)
-- ============================================================================

-- Run these queries to verify the schema was created correctly:

-- Check tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('subscriptions', 'subscription_members')
ORDER BY table_name;

-- Check indexes
SELECT indexname, tablename FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('subscriptions', 'subscription_members')
ORDER BY tablename, indexname;

-- Check RLS policies
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('subscriptions', 'subscription_members')
ORDER BY tablename, policyname;

-- Check triggers
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE event_object_schema = 'public'
AND event_object_table IN ('subscriptions', 'subscription_members')
ORDER BY event_object_table, trigger_name;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

-- NEXT STEPS:
-- 1. Execute this script in Supabase SQL Editor
-- 2. Verify all tables, indexes, and policies were created
-- 3. (Optional) Insert seed data by uncommenting section 8 and adding your user ID
-- 4. Update Flutter app's injection.dart to use SubscriptionRepositoryImpl
-- 5. Test creating subscriptions from the Flutter app
