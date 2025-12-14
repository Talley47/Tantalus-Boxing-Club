# 🚨 QUICK FIX: News Not Showing

## The Problem

News & Announcements shows "No news or announcements at the moment" even though news items exist in the database.

## The Cause

The RLS (Row Level Security) policy is blocking access because it tries to read `auth.users` table, which regular users don't have permission to access.

## The Fix (5 minutes)

### Step 1: Open Supabase SQL Editor

1. Go to: **https://supabase.com/dashboard**
2. Select project: **andmtvsqqomgwphotdwf**
3. Click **SQL Editor** → **New Query**

### Step 2: Run Each Command Separately

**IMPORTANT:** Run each command ONE AT A TIME. Wait for "Success" before running the next.

#### Command 1: Create Function
```sql
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid()
        AND (email = 'tantalusboxingclub@gmail.com' OR email LIKE '%@admin.tantalus%')
    );
END;
$$;
```
**Click Run** → Wait for "Success"

#### Command 2: Grant Permissions
```sql
GRANT EXECUTE ON FUNCTION is_admin_user() TO authenticated, anon;
```
**Click Run** → Wait for "Success"

#### Command 3: Drop Old Policies
```sql
DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
```
**Click Run** → Wait for "Success"

#### Command 4: Create Public Policy
```sql
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT USING (is_published = TRUE);
```
**Click Run** → Wait for "Success"

#### Command 5: Create Admin Policy
```sql
CREATE POLICY "Admin manage news" ON news_announcements
    FOR ALL
    USING (is_admin_user())
    WITH CHECK (is_admin_user());
```
**Click Run** → Wait for "Success"

### Step 3: Test

1. **Hard refresh your browser** (Ctrl+Shift+R)
2. **Navigate to Home Page → News & Announcements tab**
3. **You should now see news items!**

## What This Does

1. Creates a `SECURITY DEFINER` function that can safely access `auth.users`
2. Fixes the RLS policy to use the function instead of direct access
3. Allows public users to read published news
4. Allows admins to manage news

## Verify It Worked

Run this query to check:
```sql
SELECT policyname FROM pg_policies WHERE tablename = 'news_announcements';
```

You should see:
- `Public read published news`
- `Admin manage news`

## Still Not Working?

1. **Check browser console** (F12) for errors
2. **Verify news items exist and are published:**
   ```sql
   SELECT COUNT(*) FROM news_announcements WHERE is_published = TRUE;
   ```
3. **Check if you're logged in** - try logging out and back in

## Files

- `FIX-NEWS-NOW.sql` - All commands in one file (run separately)
- `FIX-NEWS-QUICK.md` - This guide











