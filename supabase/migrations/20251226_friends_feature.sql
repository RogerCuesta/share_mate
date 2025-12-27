-- =====================================================
-- Migration: Friends Feature - Complete Implementation
-- Date: 2025-12-26
-- Purpose: Add profiles, friendships, and friend management
-- =====================================================

-- =====================================================
-- 1. PROFILES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    avatar_url TEXT,
    is_discoverable BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_full_name ON profiles(full_name);
CREATE INDEX IF NOT EXISTS idx_profiles_discoverable ON profiles(is_discoverable) WHERE is_discoverable = true;

-- =====================================================
-- 2. FRIENDSHIPS TABLE
-- =====================================================

-- Friendship status enum
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'rejected', 'removed');

-- Single-row bidirectional friendship model
CREATE TABLE IF NOT EXISTS friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    status friendship_status NOT NULL DEFAULT 'pending',
    initiator_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT no_self_friendship CHECK (user_id != friend_id),
    CONSTRAINT unique_friendship UNIQUE (user_id, friend_id),
    CONSTRAINT valid_initiator CHECK (initiator_id IN (user_id, friend_id))
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);
CREATE INDEX IF NOT EXISTS idx_friendships_user_status ON friendships(user_id, status);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_status ON friendships(friend_id, status);

-- =====================================================
-- 3. TRIGGERS
-- =====================================================

-- Auto-create profile when new user signs up
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (user_id, full_name, email, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_for_new_user();

-- Auto-update updated_at timestamp on profiles
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_profiles_update
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profiles_updated_at();

-- Auto-update updated_at timestamp on friendships
CREATE OR REPLACE FUNCTION update_friendships_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_friendships_update
    BEFORE UPDATE ON friendships
    FOR EACH ROW
    EXECUTE FUNCTION update_friendships_updated_at();

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = user_id);

-- Profiles: Users can view friend profiles
CREATE POLICY "Users can view friend profiles"
    ON profiles FOR SELECT
    USING (
        user_id IN (
            SELECT friend_id FROM friendships
            WHERE user_id = auth.uid() AND status = 'accepted'
            UNION
            SELECT user_id FROM friendships
            WHERE friend_id = auth.uid() AND status = 'accepted'
        )
    );

-- Profiles: Users can update own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Friendships: Users can view own friendships
CREATE POLICY "Users can view own friendships"
    ON friendships FOR SELECT
    USING (auth.uid() IN (user_id, friend_id));

-- Friendships: Users can send friend requests
CREATE POLICY "Users can send friend requests"
    ON friendships FOR INSERT
    WITH CHECK (
        auth.uid() = initiator_id
        AND auth.uid() IN (user_id, friend_id)
    );

-- Friendships: Users can respond to friend requests
CREATE POLICY "Users can respond to friend requests"
    ON friendships FOR UPDATE
    USING (
        auth.uid() IN (user_id, friend_id)
        AND auth.uid() != initiator_id
    );

-- Friendships: Users can remove friendships
CREATE POLICY "Users can remove friendships"
    ON friendships FOR UPDATE
    USING (auth.uid() IN (user_id, friend_id));

-- =====================================================
-- 5. RPC FUNCTIONS
-- =====================================================

-- Send friend request by email
CREATE OR REPLACE FUNCTION send_friend_request(p_friend_email TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_friend_user_id UUID;
    v_friendship_id UUID;
    v_current_user_id UUID;
    v_current_user_email TEXT;
BEGIN
    v_current_user_id := auth.uid();

    -- Get current user's email
    SELECT email INTO v_current_user_email
    FROM profiles
    WHERE user_id = v_current_user_id;

    -- Prevent self-friending
    IF LOWER(TRIM(v_current_user_email)) = LOWER(TRIM(p_friend_email)) THEN
        RAISE EXCEPTION 'Cannot send friend request to yourself';
    END IF;

    -- Find friend by email (only if discoverable)
    SELECT user_id INTO v_friend_user_id
    FROM profiles
    WHERE email = LOWER(TRIM(p_friend_email))
      AND is_discoverable = true;

    IF v_friend_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found or not discoverable';
    END IF;

    -- Check for existing friendship
    SELECT id INTO v_friendship_id
    FROM friendships
    WHERE (user_id = v_current_user_id AND friend_id = v_friend_user_id)
       OR (user_id = v_friend_user_id AND friend_id = v_current_user_id);

    IF v_friendship_id IS NOT NULL THEN
        RAISE EXCEPTION 'Friendship already exists or request pending';
    END IF;

    -- Insert new friend request (normalize: lower user_id first)
    IF v_current_user_id < v_friend_user_id THEN
        INSERT INTO friendships (user_id, friend_id, initiator_id, status)
        VALUES (v_current_user_id, v_friend_user_id, v_current_user_id, 'pending')
        RETURNING id INTO v_friendship_id;
    ELSE
        INSERT INTO friendships (user_id, friend_id, initiator_id, status)
        VALUES (v_friend_user_id, v_current_user_id, v_current_user_id, 'pending')
        RETURNING id INTO v_friendship_id;
    END IF;

    RETURN v_friendship_id;
END;
$$;

-- Accept friend request
CREATE OR REPLACE FUNCTION accept_friend_request(p_friendship_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE friendships
    SET status = 'accepted', updated_at = NOW()
    WHERE id = p_friendship_id
      AND auth.uid() IN (user_id, friend_id)
      AND initiator_id != auth.uid()
      AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Friend request not found or already processed';
    END IF;
END;
$$;

-- Reject friend request
CREATE OR REPLACE FUNCTION reject_friend_request(p_friendship_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE friendships
    SET status = 'rejected', updated_at = NOW()
    WHERE id = p_friendship_id
      AND auth.uid() IN (user_id, friend_id)
      AND initiator_id != auth.uid()
      AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Friend request not found or already processed';
    END IF;
END;
$$;

-- Remove friend
CREATE OR REPLACE FUNCTION remove_friend(p_friendship_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE friendships
    SET status = 'removed', updated_at = NOW()
    WHERE id = p_friendship_id
      AND auth.uid() IN (user_id, friend_id)
      AND status = 'accepted';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Friendship not found or not active';
    END IF;
END;
$$;

-- Get friends list
CREATE OR REPLACE FUNCTION get_friends_list()
RETURNS TABLE(
    friendship_id UUID,
    user_id UUID,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id AS friendship_id,
        p.user_id,
        p.full_name,
        p.email,
        p.avatar_url,
        f.created_at
    FROM friendships f
    JOIN profiles p ON p.user_id = CASE
        WHEN f.user_id = auth.uid() THEN f.friend_id
        ELSE f.user_id
    END
    WHERE (f.user_id = auth.uid() OR f.friend_id = auth.uid())
      AND f.status = 'accepted'
    ORDER BY p.full_name ASC;
END;
$$;

-- Get pending friend requests
CREATE OR REPLACE FUNCTION get_pending_friend_requests()
RETURNS TABLE(
    friendship_id UUID,
    user_id UUID,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id AS friendship_id,
        p.user_id,
        p.full_name,
        p.email,
        p.avatar_url,
        f.created_at
    FROM friendships f
    JOIN profiles p ON p.user_id = f.initiator_id
    WHERE (f.user_id = auth.uid() OR f.friend_id = auth.uid())
      AND f.initiator_id != auth.uid()
      AND f.status = 'pending'
    ORDER BY f.created_at DESC;
END;
$$;

-- Search users by email
CREATE OR REPLACE FUNCTION search_users_by_email(p_email_query TEXT)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    is_friend BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.user_id,
        p.full_name,
        p.email,
        p.avatar_url,
        EXISTS(
            SELECT 1 FROM friendships f
            WHERE (f.user_id = auth.uid() AND f.friend_id = p.user_id)
               OR (f.user_id = p.user_id AND f.friend_id = auth.uid())
            AND f.status = 'accepted'
        ) AS is_friend
    FROM profiles p
    WHERE p.email = LOWER(TRIM(p_email_query))
      AND p.user_id != auth.uid()
      AND p.is_discoverable = true;
END;
$$;

-- =====================================================
-- 6. GRANTS
-- =====================================================

GRANT EXECUTE ON FUNCTION send_friend_request TO authenticated;
GRANT EXECUTE ON FUNCTION accept_friend_request TO authenticated;
GRANT EXECUTE ON FUNCTION reject_friend_request TO authenticated;
GRANT EXECUTE ON FUNCTION remove_friend TO authenticated;
GRANT EXECUTE ON FUNCTION get_friends_list TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_friend_requests TO authenticated;
GRANT EXECUTE ON FUNCTION search_users_by_email TO authenticated;

-- =====================================================
-- 7. BACKFILL EXISTING USERS
-- =====================================================

-- Create profiles for all existing auth.users
INSERT INTO profiles (user_id, full_name, email, avatar_url)
SELECT
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', 'User'),
    au.email,
    au.raw_user_meta_data->>'avatar_url'
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.user_id = au.id)
ON CONFLICT (user_id) DO NOTHING;
