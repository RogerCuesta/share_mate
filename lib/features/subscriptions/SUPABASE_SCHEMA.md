# Supabase Database Schema for Subscriptions

This document describes the database schema required for the Subscriptions feature in Supabase.

## Tables

### 1. `subscriptions` Table

Stores information about shared subscriptions.

```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  icon_url TEXT,
  color TEXT NOT NULL,
  total_cost DECIMAL(10, 2) NOT NULL CHECK (total_cost > 0),
  billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly', 'yearly')),
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'paused')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_color CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT name_not_empty CHECK (LENGTH(TRIM(name)) >= 2)
);

-- Indexes for performance
CREATE INDEX idx_subscriptions_owner_id ON subscriptions(owner_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_due_date ON subscriptions(due_date);
```

**Fields:**
- `id`: UUID primary key
- `name`: Subscription service name (e.g., "Netflix")
- `icon_url`: Optional URL to service icon/logo
- `color`: Hex color for UI display (e.g., "#E50914")
- `total_cost`: Total monthly or yearly cost
- `billing_cycle`: Either 'monthly' or 'yearly'
- `due_date`: Next payment due date
- `owner_id`: Reference to auth.users - the user who pays the main subscription
- `status`: Current status: 'active', 'cancelled', or 'paused'
- `created_at`: Timestamp of creation

---

### 2. `subscription_members` Table

Stores information about users sharing a subscription.

```sql
CREATE TABLE subscription_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  user_avatar TEXT,
  amount_to_pay DECIMAL(10, 2) NOT NULL CHECK (amount_to_pay >= 0),
  has_paid BOOLEAN NOT NULL DEFAULT FALSE,
  last_payment_date TIMESTAMP WITH TIME ZONE,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT unique_member_per_subscription UNIQUE(subscription_id, user_id),
  CONSTRAINT user_name_not_empty CHECK (LENGTH(TRIM(user_name)) >= 2)
);

-- Indexes for performance
CREATE INDEX idx_members_subscription_id ON subscription_members(subscription_id);
CREATE INDEX idx_members_user_id ON subscription_members(user_id);
CREATE INDEX idx_members_has_paid ON subscription_members(has_paid);
CREATE INDEX idx_members_due_date ON subscription_members(due_date);
```

**Fields:**
- `id`: UUID primary key
- `subscription_id`: Reference to subscriptions table
- `user_id`: Reference to auth.users - the member sharing the subscription
- `user_name`: Display name of the member
- `user_avatar`: Optional URL to member's avatar
- `amount_to_pay`: This member's share of the cost
- `has_paid`: Whether payment has been received
- `last_payment_date`: When the last payment was made
- `due_date`: When payment is due
- `created_at`: Timestamp of creation

---

## Row Level Security (RLS) Policies

### For `subscriptions` table:

```sql
-- Enable RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions"
ON subscriptions FOR SELECT
USING (auth.uid() = owner_id);

-- Policy: Users can create subscriptions
CREATE POLICY "Users can create subscriptions"
ON subscriptions FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can update their own subscriptions
CREATE POLICY "Users can update own subscriptions"
ON subscriptions FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can delete their own subscriptions
CREATE POLICY "Users can delete own subscriptions"
ON subscriptions FOR DELETE
USING (auth.uid() = owner_id);
```

### For `subscription_members` table:

```sql
-- Enable RLS
ALTER TABLE subscription_members ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view members of their subscriptions
CREATE POLICY "Users can view members of own subscriptions"
ON subscription_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_members.subscription_id
    AND subscriptions.owner_id = auth.uid()
  )
);

-- Policy: Users can create members for their subscriptions
CREATE POLICY "Users can create members for own subscriptions"
ON subscription_members FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_members.subscription_id
    AND subscriptions.owner_id = auth.uid()
  )
);

-- Policy: Users can update members of their subscriptions
CREATE POLICY "Users can update members of own subscriptions"
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

-- Policy: Users can delete members from their subscriptions
CREATE POLICY "Users can delete members from own subscriptions"
ON subscription_members FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.id = subscription_members.subscription_id
    AND subscriptions.owner_id = auth.uid()
  )
);
```

---

## Setup Instructions

### 1. Create Tables

Run the SQL commands above in the Supabase SQL Editor:
1. Go to Supabase Dashboard → SQL Editor
2. Create a new query
3. Copy and paste the table creation SQL
4. Execute

### 2. Enable RLS

Run the RLS policy SQL commands in the same SQL Editor.

### 3. Verify Setup

```sql
-- Check that tables exist
SELECT * FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('subscriptions', 'subscription_members');

-- Check that RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('subscriptions', 'subscription_members');

-- Check that policies exist
SELECT * FROM pg_policies
WHERE tablename IN ('subscriptions', 'subscription_members');
```

---

## Example Data

### Insert Sample Subscription

```sql
INSERT INTO subscriptions (
  name,
  color,
  total_cost,
  billing_cycle,
  due_date,
  owner_id,
  status
) VALUES (
  'Netflix',
  '#E50914',
  15.99,
  'monthly',
  NOW() + INTERVAL '30 days',
  'YOUR_USER_ID_HERE', -- Replace with actual auth.uid()
  'active'
);
```

### Insert Sample Member

```sql
INSERT INTO subscription_members (
  subscription_id,
  user_id,
  user_name,
  amount_to_pay,
  has_paid,
  due_date
) VALUES (
  'SUBSCRIPTION_ID_HERE', -- From above insert
  'MEMBER_USER_ID_HERE',  -- Another user's auth.uid()
  'John Doe',
  5.33, -- 15.99 / 3 if 3 people share
  FALSE,
  NOW() + INTERVAL '30 days'
);
```

---

## Backup & Migration

### Backup Schema

```bash
# From Supabase CLI
supabase db dump -f subscriptions_schema.sql
```

### Restore Schema

```bash
# From Supabase CLI
supabase db push --file subscriptions_schema.sql
```

---

## Real-time Subscriptions (Optional)

To enable real-time updates for subscriptions:

```sql
-- Enable real-time for subscriptions table
ALTER PUBLICATION supabase_realtime ADD TABLE subscriptions;
ALTER PUBLICATION supabase_realtime ADD TABLE subscription_members;
```

Then in Flutter:

```dart
// Listen to subscription changes
final subscription = SupabaseService.client
  .from('subscriptions')
  .stream(primaryKey: ['id'])
  .eq('owner_id', userId)
  .listen((data) {
    // Handle real-time updates
  });
```

---

## Notes

- All timestamps are stored in UTC
- The `shared_with` field from the domain model is NOT stored in the database
  - It's derived from the `subscription_members` table
  - This ensures data consistency and avoids duplication
- Cascade deletes ensure that when a subscription is deleted, all members are also deleted
- The unique constraint on `subscription_members` prevents duplicate members
- RLS policies ensure users can only access their own data

---

**Last Updated:** 2025-12-15
**Schema Version:** 1.0.0
