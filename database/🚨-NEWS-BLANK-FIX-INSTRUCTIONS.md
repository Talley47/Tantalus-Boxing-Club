# 🚨 FIX: News & Announcements Blank for Logged-In Users

## Problem
- **Admin account** can see news posts ✅
- **Regular logged-in users** see blank news section ❌
- **Unauthenticated users** might be able to see news (depending on RLS)

## Root Cause
The `news_announcements` table has Row Level Security (RLS) enabled, but the policies only allow:
- `anon` role (unauthenticated users) to read published news
- **Missing**: Policy for `authenticated` role (logged-in users)

When a user logs in, Supabase switches them from `anon` to `authenticated` role. Without a policy for `authenticated`, logged-in users are blocked by RLS.

## Solution
Run the SQL script to add a policy for authenticated users.

### Option 1: Supabase SQL Editor (Recommended)
1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Open the file: `database/🚨-URGENT-FIX-NEWS-RLS-AUTHENTICATED.sql`
4. Copy **ALL** the SQL code
5. Paste into SQL Editor
6. Click **Run** or press `Ctrl+Enter`

### Option 2: Quick Fix (Copy-Paste)
Copy and paste this into Supabase SQL Editor:

```sql
-- Drop all existing SELECT policies
DO $$ 
DECLARE 
  r RECORD;
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'news_announcements'
      AND cmd = 'SELECT'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.news_announcements', r.policyname);
  END LOOP;
END $$;

-- Create policy for anonymous users (unauthenticated)
CREATE POLICY "Public read published news" 
ON public.news_announcements 
FOR SELECT 
TO anon 
USING (is_published = TRUE);

-- Create policy for authenticated users (logged in)
-- ⚠️ THIS IS THE CRITICAL FIX
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (
  is_published IS NOT NULL 
  AND is_published = TRUE
);
```

## Verification
After running the SQL:
1. Refresh your app
2. Log in as a regular user (not admin)
3. Check the News & Announcements section
4. You should now see published news items

## What the Fix Does
- **Keeps** the existing policy for anonymous users
- **Adds** a new policy for authenticated users to read published news
- Both policies only allow reading `is_published = TRUE` items
- Admin users can still see all news (via admin panel with different permissions)

## Troubleshooting
If news is still blank after running SQL:
1. Check browser console for errors
2. Verify you're logged in (check auth status in console)
3. Check Supabase Dashboard → Authentication → Policies → `news_announcements`
4. Look for policies named:
   - `Public read published news` (for `anon`)
   - `Authenticated read published news` (for `authenticated`)

## Related Files
- `database/🚨-URGENT-FIX-NEWS-RLS-AUTHENTICATED.sql` - Full SQL script with diagnostics
- `database/FIX-NEWS-RLS-SIMPLE.sql` - Simpler version
- `src/services/newsService.ts` - Code that fetches news (has diagnostic logging)

