-- =====================================================
-- Migration: Contacts Feature - Refactor from Friends
-- Date: 2026-01-08
-- Purpose: Simplify Friends feature to simple Contacts list
--          Remove complex friend requests, bidirectional relationships
--          Replace with personal contact book model
-- =====================================================

-- =====================================================
-- 1. CREATE CONTACTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    contact_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_avatar TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT contacts_name_length CHECK (length(TRIM(BOTH FROM contact_name)) >= 2),
    CONSTRAINT contacts_email_format CHECK (
        contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT contacts_unique_email_per_user UNIQUE(user_id, contact_email)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(user_id, contact_email);
CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(user_id, contact_name);

-- =====================================================
-- 2. CREATE TRIGGER FOR AUTO-UPDATE TIMESTAMP
-- =====================================================

CREATE OR REPLACE FUNCTION update_contacts_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_contacts_update
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_contacts_updated_at();

-- =====================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Users can view only their own contacts
CREATE POLICY "Users can view own contacts"
    ON contacts FOR SELECT
    USING (user_id = auth.uid());

-- Users can insert only their own contacts
CREATE POLICY "Users can insert own contacts"
    ON contacts FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can update only their own contacts
CREATE POLICY "Users can update own contacts"
    ON contacts FOR UPDATE
    USING (user_id = auth.uid());

-- Users can delete only their own contacts
CREATE POLICY "Users can delete own contacts"
    ON contacts FOR DELETE
    USING (user_id = auth.uid());

-- =====================================================
-- 4. DROP OLD FRIENDS FEATURE COMPONENTS
-- =====================================================

-- Drop all RPC functions (7 total)
DROP FUNCTION IF EXISTS send_friend_request(TEXT) CASCADE;
DROP FUNCTION IF EXISTS accept_friend_request(UUID) CASCADE;
DROP FUNCTION IF EXISTS reject_friend_request(UUID) CASCADE;
DROP FUNCTION IF EXISTS remove_friend(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_friends_list() CASCADE;
DROP FUNCTION IF EXISTS get_pending_friend_requests() CASCADE;
DROP FUNCTION IF EXISTS search_users_by_email(TEXT) CASCADE;

-- Drop triggers on old tables
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_profiles_update ON profiles;
DROP TRIGGER IF EXISTS on_friendships_update ON friendships;

-- Drop trigger functions
DROP FUNCTION IF EXISTS create_profile_for_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_profiles_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_friendships_updated_at() CASCADE;

-- Drop old tables (CASCADE to handle foreign key dependencies)
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Drop custom enum type
DROP TYPE IF EXISTS friendship_status;

-- =====================================================
-- 5. GRANTS
-- =====================================================

-- No RPC functions to grant (simple CRUD via direct table access)
-- RLS policies handle all authorization

-- =====================================================
-- END OF MIGRATION
-- =====================================================

-- Migration Summary:
-- ✅ Created contacts table with user_id FK, name, email, avatar, notes
-- ✅ Added indexes for performance (user_id, email, name)
-- ✅ Added constraints (name length, email format, unique email per user)
-- ✅ Enabled RLS with user ownership policies (view/insert/update/delete own contacts)
-- ✅ Added auto-update trigger for updated_at timestamp
-- ✅ Dropped old friendships table (0 rows - no data loss)
-- ✅ Dropped old profiles table
-- ✅ Dropped all friend request RPC functions (7 total)
-- ✅ Dropped all triggers and trigger functions from old schema
-- ✅ Dropped friendship_status enum type
