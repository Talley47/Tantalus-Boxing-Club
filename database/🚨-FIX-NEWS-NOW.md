# 🚨 FIX: News & Announcements Blank for Logged-In Users

## The Problem
- ✅ **Admin account** can see news posts
- ❌ **Regular logged-in users** see blank news section
- The query returns empty data (no error) because RLS is silently blocking it

## Root Cause
The `news_announcements` table has Row Level Security (RLS) enabled, but:
- ✅ Policy exists for `anon` role (unauthenticated users)
- ❌ **Missing**: Policy for `authenticated` role (logged-in users)

When you log in, Supabase switches you from `anon` to `authenticated` role. Without a policy for `authenticated`, you're blocked by RLS.

## The Fix (2 minutes)

### Step 1: Open Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Select your project
3. Click **SQL Editor** → **New Query**

### Step 2: Copy and Paste This SQL
```sql
-- Drop the policy if it exists (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated read published news" ON public.news_announcements;

-- Create policy for authenticated users (logged in)
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (
  is_published IS NOT NULL 
  AND is_published = TRUE
);
```

### Step 3: Run the Query
- Click **Run** button or press `Ctrl+Enter`
- Wait for "Success" message

### Step 4: Test
1. **Hard refresh your browser** (Ctrl+Shift+R or Cmd+Shift+R)
2. **Log in as a regular user** (not admin)
3. **Check News & Announcements section** - you should now see published news!

## Verification
After running the SQL, you can verify it worked:

```sql
-- Check if policy exists
SELECT 
  policyname,
  cmd as command,
  roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY policyname;
```

You should see:
- `Public read published news` (for `anon`)
- `Authenticated read published news` (for `authenticated`) ← **This is the new one**

## Troubleshooting

### If you get a permission error:
- Make sure you're logged into Supabase Dashboard as the project owner
- Try running the SQL in smaller chunks

### If news is still blank after running SQL:
1. Check browser console (F12) for errors
2. Verify you're logged in (check auth status)
3. Make sure news items have `is_published = TRUE` in database
4. Check Supabase Dashboard → Authentication → Policies → `news_announcements`

### If you see "policy already exists":
- That's fine! The policy is already there. Check if there's another issue.

## What This Fix Does
- ✅ Allows logged-in users (`authenticated` role) to read published news
- ✅ Keeps existing policy for unauthenticated users (`anon` role)
- ✅ Only shows news where `is_published = TRUE`
- ✅ Admin users can still see all news (via admin panel)

## Related Files
- `database/🔧-SIMPLE-FIX-NEWS-RLS.sql` - Simple SQL script (same as above)
- `database/🚨-URGENT-FIX-NEWS-RLS-AUTHENTICATED.sql` - Full script with diagnostics
- `src/services/newsService.ts` - Code that fetches news (has diagnostic logging)

