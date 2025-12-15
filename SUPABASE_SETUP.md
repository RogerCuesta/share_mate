# 🚀 Supabase Setup Guide

Complete guide to configure Supabase for the SubMate authentication system.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Create Supabase Account](#step-1-create-supabase-account)
- [Step 2: Create a New Project](#step-2-create-a-new-project)
- [Step 3: Get Your Credentials](#step-3-get-your-credentials)
- [Step 4: Configure Environment Variables](#step-4-configure-environment-variables)
- [Step 5: Authentication Settings](#step-5-authentication-settings)
- [Step 6: Row Level Security (RLS)](#step-6-row-level-security-rls)
- [Step 7: Verify Integration](#step-7-verify-integration)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## ✅ Prerequisites

Before starting, ensure you have:

- ✅ A valid email address
- ✅ Internet connection
- ✅ Flutter project set up locally
- ✅ [.env.example](.env.example) file in project root

**Time estimate:** 10-15 minutes

---

## Step 1: Create Supabase Account

### 1.1 Sign Up

1. Go to [supabase.com](https://supabase.com)
2. Click **"Start your project"** or **"Sign In"**
3. Choose sign-up method:
   - **GitHub** (recommended for developers)
   - **Google**
   - **Email**

![Supabase Sign Up](https://supabase.com/images/authentication/github-login.png)

### 1.2 Verify Email

- Check your email inbox
- Click the verification link
- You'll be redirected to the Supabase Dashboard

---

## Step 2: Create a New Project

### 2.1 New Organization (First-time users)

1. After signing in, you'll be prompted to create an **Organization**
2. Enter organization name: `SubMate` (or your preferred name)
3. Click **"Create Organization"**

### 2.2 Create Project

1. Click **"New Project"**
2. Fill in project details:

   | Field | Value | Description |
   |-------|-------|-------------|
   | **Name** | `submate-app` | Your project name |
   | **Database Password** | `[Generate strong password]` | **⚠️ SAVE THIS!** You'll need it later |
   | **Region** | `[Closest to your users]` | e.g., `South America (São Paulo)` |
   | **Pricing Plan** | `Free` | Start with free tier |

3. Click **"Create new project"**

### 2.3 Wait for Project Setup

- ⏳ Project setup takes **~2 minutes**
- You'll see a progress screen
- Once ready, you'll see the Project Dashboard

![Project Setup](https://supabase.com/images/project-setup.png)

---

## Step 3: Get Your Credentials

### 3.1 Navigate to API Settings

1. In your project dashboard, click **⚙️ Settings** (left sidebar)
2. Click **"API"** section
3. You'll see the API settings page

### 3.2 Copy Project URL

```
┌─────────────────────────────────────┐
│ Configuration                       │
├─────────────────────────────────────┤
│ URL:                                │
│ https://xxxxx.supabase.co          │
│ [Copy]                              │
└─────────────────────────────────────┘
```

- Copy the **Project URL**
- It looks like: `https://abcdefghijklmnop.supabase.co`
- **Save this** - you'll need it for `SUPABASE_URL`

### 3.3 Copy API Keys

Scroll down to **"Project API keys"** section:

```
┌─────────────────────────────────────┐
│ Project API keys                    │
├─────────────────────────────────────┤
│ anon public                         │
│ eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp... │
│ [Copy]                              │
├─────────────────────────────────────┤
│ service_role secret                 │
│ eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp... │
│ [Copy]                              │
└─────────────────────────────────────┘
```

**Copy both keys:**

1. **`anon public`** key
   - This is your **SUPABASE_ANON_KEY**
   - ✅ Safe to use in client-side code
   - Used for all Flutter app authentication

2. **`service_role`** key
   - This is your **SUPABASE_SERVICE_ROLE_KEY**
   - ❌ **NEVER use in client code**
   - Only for backend/admin operations

---

## Step 4: Configure Environment Variables

### 4.1 Copy Example File

In your Flutter project root:

```bash
cp .env.example .env
```

### 4.2 Edit .env File

Open `.env` and replace the placeholders:

```env
# Supabase Configuration

# Supabase Project URL (from Step 3.2)
SUPABASE_URL=https://abcdefghijklmnop.supabase.co

# Supabase Anonymous Key (from Step 3.3 - anon public)
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxMjI4MjQwMCwiZXhwIjoxOTI3ODU4NDAwfQ...

# Supabase Service Role Key (from Step 3.3 - service_role)
# ⚠️ WARNING: Keep this secret! Do not expose in client-side code
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjEyMjgyNDAwLCJleHAiOjE5Mjc4NTg0MDB9...
```

### 4.3 Verify .gitignore

**CRITICAL:** Ensure `.env` is in `.gitignore`:

```bash
# Check if .env is ignored
cat .gitignore | grep .env
```

You should see:
```
# Environment Variables
.env
```

✅ If it's there, you're safe!
❌ If not, add it immediately:

```bash
echo ".env" >> .gitignore
```

---

## Step 5: Authentication Settings

### 5.1 Navigate to Auth Settings

1. Click **🔐 Authentication** in left sidebar
2. Click **"Settings"**
3. Click **"Auth"** tab

### 5.2 Configure Auth Providers

**Email Auth** (Required):

```
┌─────────────────────────────────────┐
│ Email                               │
├─────────────────────────────────────┤
│ ☑ Enable Email provider            │
│ ☑ Confirm email                    │ ← Enable for production
│ □ Secure email change              │
│ □ Double confirm email changes     │
└─────────────────────────────────────┘
```

**Settings:**
- ✅ **Enable Email provider** - ON
- ⚠️ **Confirm email** - OFF for development, ON for production
- ⚠️ **Secure email change** - ON for production

### 5.3 Configure Email Templates (Optional)

For production, customize:
- **Confirmation email**
- **Reset password email**
- **Magic link email**

Click **"Email Templates"** → Customize HTML/text

### 5.4 Configure Auth URL (Optional)

```
┌─────────────────────────────────────┐
│ Site URL                            │
├─────────────────────────────────────┤
│ http://localhost:3000              │ ← Update for production
└─────────────────────────────────────┘
```

For development: `http://localhost:3000`
For production: `https://yourdomain.com`

### 5.5 Rate Limiting (Recommended)

Scroll to **"Rate Limiting"**:

```
┌─────────────────────────────────────┐
│ Rate Limiting                       │
├─────────────────────────────────────┤
│ Max requests per hour: [5]         │
│ Per IP address                      │
└─────────────────────────────────────┘
```

**Recommended:**
- Development: `10 requests/hour`
- Production: `5 requests/hour`

---

## Step 6: Row Level Security (RLS)

### 6.1 Why RLS Matters

**Without RLS:**
- ❌ Any authenticated user can read/write ALL data
- ❌ Major security vulnerability

**With RLS:**
- ✅ Users can only access their own data
- ✅ Database-level security enforcement

### 6.2 Enable RLS (When you create tables)

For now, the app uses **only Supabase Auth** (no custom tables yet).

**When you add custom tables** (e.g., user profiles, subscriptions):

1. Go to **🗄️ Database** → **Tables**
2. Select your table
3. Click **"Enable RLS"**
4. Create policies:

```sql
-- Example: Users can only read their own data
CREATE POLICY "Users can view own data"
ON public.user_profiles
FOR SELECT
USING (auth.uid() = user_id);

-- Example: Users can only update their own data
CREATE POLICY "Users can update own data"
ON public.user_profiles
FOR UPDATE
USING (auth.uid() = user_id);
```

### 6.3 RLS Policy Examples

**Read own data:**
```sql
CREATE POLICY "read_own_data"
ON public.your_table
FOR SELECT
USING (auth.uid() = user_id);
```

**Write own data:**
```sql
CREATE POLICY "write_own_data"
ON public.your_table
FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

**Update own data:**
```sql
CREATE POLICY "update_own_data"
ON public.your_table
FOR UPDATE
USING (auth.uid() = user_id);
```

**See:** [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security) for advanced policies

---

## Step 7: Verify Integration

### 7.1 Run Flutter App

```bash
flutter pub get
flutter run
```

### 7.2 Test Registration

1. Open app
2. Go to **Register** screen
3. Fill in:
   - Full Name: `Test User`
   - Email: `test@example.com`
   - Password: `password123`
   - Confirm Password: `password123`
4. Click **"Sign Up"**

**Expected:**
- ✅ User created in Supabase
- ✅ Redirected to Home screen
- ✅ No errors

### 7.3 Verify in Supabase Dashboard

1. Go to **🔐 Authentication** → **Users**
2. You should see your test user:

```
┌────────────────────────────────────────────┐
│ Users                                      │
├────────────────────────────────────────────┤
│ test@example.com                          │
│ • Created: just now                       │
│ • Last sign in: just now                  │
│ • Email confirmed: ✅ (or ⏳ pending)    │
└────────────────────────────────────────────┘
```

### 7.4 Test Login

1. Logout from app
2. Go to **Login** screen
3. Enter:
   - Email: `test@example.com`
   - Password: `password123`
4. Click **"Sign In"**

**Expected:**
- ✅ Successfully logged in
- ✅ Redirected to Home screen

### 7.5 Test Offline Mode

1. Turn off internet/WiFi
2. Try to login with cached credentials
3. Should work offline ✅

---

## 🛠️ Troubleshooting

### Problem: "Invalid API key"

**Symptoms:**
```
Supabase error: Invalid API key
```

**Solution:**
1. Check `.env` file has correct `SUPABASE_ANON_KEY`
2. Ensure no extra spaces/newlines
3. Restart app (hot reload won't work)
4. Verify key from Supabase Dashboard → Settings → API

### Problem: "Project not found"

**Symptoms:**
```
Supabase error: Project not found
```

**Solution:**
1. Check `SUPABASE_URL` is correct
2. Ensure URL includes `https://`
3. Verify project is active in Dashboard
4. Check you're in correct organization

### Problem: "Email already registered"

**Symptoms:**
```
User with this email already registered
```

**Solution:**
1. Go to Supabase Dashboard → Authentication → Users
2. Delete test user
3. Or use different email for testing

### Problem: "Network request failed"

**Symptoms:**
```
Network request failed / Socket exception
```

**Solution:**
1. Check internet connection
2. Verify Supabase project is running (not paused)
3. Free tier projects pause after inactivity
4. Go to Dashboard → restart project

### Problem: ".env not found"

**Symptoms:**
```
Missing environment variables
```

**Solution:**
```bash
# Create .env from example
cp .env.example .env

# Edit with your credentials
nano .env  # or use your editor
```

### Problem: "Rate limit exceeded"

**Symptoms:**
```
Too many requests
```

**Solution:**
1. Wait 1 hour (rate limit resets)
2. Or increase rate limit in Dashboard:
   - Settings → Auth → Rate Limiting
   - Set to higher value (e.g., 10/hour)

---

## 🔐 Best Practices

### Security

✅ **DO:**
- ✅ Keep `.env` in `.gitignore`
- ✅ Use `SUPABASE_ANON_KEY` in client code
- ✅ Enable RLS on all tables
- ✅ Use PKCE flow (already configured)
- ✅ Enable email confirmation in production
- ✅ Set up rate limiting

❌ **DON'T:**
- ❌ Commit `.env` to git
- ❌ Use `SUPABASE_SERVICE_ROLE_KEY` in client
- ❌ Disable RLS without good reason
- ❌ Share API keys publicly
- ❌ Use weak database passwords

### Development

✅ **Recommendations:**
- ✅ Use separate projects for dev/staging/production
- ✅ Test offline mode regularly
- ✅ Monitor auth logs in Dashboard
- ✅ Set up error tracking (e.g., Sentry)
- ✅ Document any custom RLS policies

### Production Checklist

Before deploying to production:

- [ ] Email confirmation enabled
- [ ] Custom email templates configured
- [ ] Rate limiting set appropriately (5/hour)
- [ ] RLS enabled on all tables
- [ ] Auth policies tested
- [ ] SSL pinning implemented (optional but recommended)
- [ ] Environment variables in CI/CD secrets
- [ ] Monitoring and alerts configured

---

## 📚 Additional Resources

### Official Documentation
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Auth Guide](https://supabase.com/docs/guides/auth/auth-helpers/flutter-auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [PKCE Flow](https://supabase.com/docs/guides/auth/auth-code-flow)

### SubMate Documentation
- [Main README](README.md) - Project overview
- [SECURITY.md](SECURITY.md) - Security guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [Auth Feature README](lib/features/auth/README.md) - Architecture details

### Community
- [Supabase Discord](https://discord.supabase.com)
- [GitHub Discussions](https://github.com/supabase/supabase/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/supabase)

---

## 🎯 Next Steps

After completing this setup:

1. ✅ Test authentication flows (register, login, logout)
2. ✅ Review [SECURITY.md](SECURITY.md) for security best practices
3. ✅ Implement recommended security features (Hive encryption, SSL pinning)
4. ✅ Configure RLS when adding custom tables
5. ✅ Set up production environment with separate Supabase project
6. ✅ Enable monitoring and analytics

---

**Setup Complete!** 🎉

Your Supabase integration is ready. You can now:
- Register users
- Authenticate with email/password
- Work offline with cached credentials
- Sync with Supabase when online

For issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or create an issue in the repository.

---

**Last Updated:** 2025-12-15
**Supabase Version:** Latest
**Flutter SDK Version:** >=3.24.0
