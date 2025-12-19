# Supabase Migrations Log

This document tracks all migrations applied to the Supabase database.

## Migration History

### 2025-12-19: add_user_email_to_subscription_members

**Purpose:** Add missing `user_email` column to `subscription_members` table.

**Reason:** The initial schema execution didn't create the `user_email` column, causing errors when creating group subscriptions.

**SQL:**
```sql
ALTER TABLE subscription_members 
ADD COLUMN user_email VARCHAR(255) NOT NULL DEFAULT 'no-email@example.com';

COMMENT ON COLUMN subscription_members.user_email IS 'Email address for the member';

ALTER TABLE subscription_members 
ALTER COLUMN user_email DROP DEFAULT;
```

**Status:** ✅ Applied successfully

---

### 2025-12-19: add_updated_at_to_subscription_members

**Purpose:** Add missing `updated_at` column to `subscription_members` table.

**Reason:** The `update_updated_at_column()` trigger was trying to update a non-existent column, causing UPDATE queries to fail.

**SQL:**
```sql
ALTER TABLE subscription_members 
ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();

COMMENT ON COLUMN subscription_members.updated_at IS 'Timestamp when member info was last modified';
```

**Status:** ✅ Applied successfully

---

### 2025-12-19: Update existing members with valid emails

**Purpose:** Update existing members that had the default placeholder email.

**SQL:**
```sql
UPDATE subscription_members 
SET user_email = 'sarah@email.com'
WHERE user_name = 'Sarah Jenkins' AND user_email = 'no-email@example.com';

UPDATE subscription_members 
SET user_email = 'mike@email.com'
WHERE user_name = 'Mike T.' AND user_email = 'no-email@example.com';
```

**Status:** ✅ Applied successfully

---

### 2025-12-19: remove_user_id_foreign_key_from_subscription_members

**Purpose:** Remove foreign key constraint on `user_id` to allow placeholder users.

**Reason:** The app uses hardcoded members with placeholder UUIDs that don't exist in `auth.users`. The FK constraint was preventing creation of group subscriptions with non-registered members.

**SQL:**
```sql
ALTER TABLE subscription_members
DROP CONSTRAINT IF EXISTS subscription_members_user_id_fkey;

COMMENT ON COLUMN subscription_members.user_id IS 'User ID - can be a placeholder UUID for non-registered users (no FK constraint)';
```

**Status:** ✅ Applied successfully

**Impact:**
- Allows adding members who are not registered users
- Enables hardcoded demo members (Sarah, Mike, Emma)
- Future friends feature will work with both registered and placeholder users

---

## Current Schema Status

### Tables
- ✅ `subscriptions` - All columns present
- ✅ `subscription_members` - All columns present (user_email and updated_at added)

### Constraints Modified
- ❌ Removed: `subscription_members.user_id` FK to `auth.users` (allows placeholder users)
- ✅ Kept: `subscription_members.subscription_id` FK to `subscriptions` (maintains integrity)

### Missing from initial execution
The following columns were missing from the initial schema execution but have been added via migrations:
- `subscription_members.user_email` (VARCHAR(255) NOT NULL)
- `subscription_members.updated_at` (TIMESTAMP WITH TIME ZONE NOT NULL)

## Next Steps

Future schema changes should be applied using the Supabase MCP tools with the `apply_migration` function to ensure they are tracked and can be rolled back if needed.
