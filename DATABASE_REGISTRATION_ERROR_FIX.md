# Fix: Database Error Saving New User

## Problem
When trying to register a new user, you get:
```
Database error saving new user
POST https://*.supabase.co/auth/v1/signup 500 (Internal Server Error)
```

## Root Cause
The database trigger that automatically creates a profile when a user signs up is failing. This trigger runs after a user is created in `auth.users` and tries to create a corresponding entry in the `profiles` table.

## ✅ Solution: Check and Fix Database Triggers

### Step 1: Check if Trigger Exists

1. **Go to:** Supabase Dashboard → SQL Editor
2. **Run this query:**
```sql
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name LIKE '%auth_user%' 
   OR trigger_name LIKE '%new_user%'
   OR trigger_name LIKE '%fighter%';
```

### Step 2: Check if Function Exists

```sql
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND (routine_name LIKE '%handle_new%' OR routine_name LIKE '%fighter%');
```

### Step 3: Run the Trigger Setup

If the trigger doesn't exist or is broken, run this SQL in Supabase SQL Editor:

**File to use:** `database/auto-create-profiles-trigger.sql`

Or run this simplified version:

```sql
-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail user creation
        RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, anon, authenticated, service_role;
```

### Step 4: Verify Profiles Table Structure

Make sure the `profiles` table has the required columns:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;
```

Required columns:
- `id` (UUID, primary key)
- `email` (text)
- `full_name` (text, nullable)
- `role` (text, default 'user')
- `created_at` (timestamp)
- `updated_at` (timestamp)

### Step 5: Check RLS Policies

Make sure RLS policies allow the trigger to insert:

```sql
-- Check RLS policies on profiles
SELECT * FROM pg_policies WHERE tablename = 'profiles';
```

If RLS is blocking, temporarily disable it for testing:

```sql
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
```

Or add a policy that allows service_role to insert:

```sql
CREATE POLICY "Allow service role to insert profiles"
ON public.profiles
FOR INSERT
TO service_role
WITH CHECK (true);
```

## Common Issues

### Issue 1: Missing Columns in Profiles Table
**Symptom:** Trigger fails because column doesn't exist

**Fix:** Add missing columns to profiles table

### Issue 2: RLS Blocking Insert
**Symptom:** Trigger can't insert due to RLS policies

**Fix:** Use `SECURITY DEFINER` in function or adjust RLS policies

### Issue 3: Function Permissions
**Symptom:** Function doesn't have permission to insert

**Fix:** Grant execute permissions (see Step 3)

### Issue 4: Schema Mismatch
**Symptom:** Trigger tries to insert into columns that don't match

**Fix:** Update trigger function to match actual schema

## Quick Fix: Run Complete Trigger Setup

1. **Go to:** Supabase Dashboard → SQL Editor
2. **Open:** `database/auto-create-profiles-trigger.sql`
3. **Copy and paste** the entire file
4. **Run** the SQL
5. **Test registration** again

## Verify Fix

After running the trigger setup:

1. **Try registering** a new user
2. **Check Supabase logs:**
   - Dashboard → Logs → Postgres Logs
   - Look for any errors related to the trigger

3. **Verify profile was created:**
```sql
SELECT * FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 5;
```

## Alternative: Manual Profile Creation

If triggers continue to fail, you can manually create profiles after user registration, but this is not recommended for production.

---

**The trigger must be set up correctly for user registration to work!**

