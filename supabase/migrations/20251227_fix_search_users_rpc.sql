-- Migration: Fix search_users_by_email RPC function
-- Remove is_friend field that causes type mismatch with ProfileModel
-- Created: 2025-12-27

-- Drop existing function
DROP FUNCTION IF EXISTS search_users_by_email(TEXT);

-- Recreate function without is_friend field
CREATE OR REPLACE FUNCTION search_users_by_email(p_email_query TEXT)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    is_discoverable BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
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
        p.is_discoverable,
        p.created_at,
        p.updated_at
    FROM profiles p
    WHERE p.email = LOWER(TRIM(p_email_query))
      AND p.user_id != auth.uid()
      AND p.is_discoverable = true;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION search_users_by_email TO authenticated;
