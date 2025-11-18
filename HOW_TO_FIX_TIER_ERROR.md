# How to Fix Tier Constraint Error

## ⚠️ Important: Don't Copy Browser Errors!

The error you're seeing:
```
fetch.ts:7  PATCH https://andmtvsqqomgwphotdwf.supabase.co/rest/v1/fighter_profiles...
```

This is a **browser console error**, NOT SQL code. You cannot paste this into Supabase SQL Editor.

## ✅ Correct Steps to Fix

### Step 1: Open Supabase SQL Editor

1. **Go to:** https://supabase.com/dashboard
2. **Select:** Your project
3. **Click:** "SQL Editor" (left sidebar)
4. **Click:** "New query"

### Step 2: Copy the SQL Script

**Open this file:** `database/QUICK_FIX_TIER_CONSTRAINT.sql`

**Copy the ENTIRE SQL script** (not the browser error)

### Step 3: Paste and Run

1. **Paste** the SQL script into Supabase SQL Editor
2. **Click:** "Run" button (or press Ctrl+Enter)
3. **Wait** for it to complete

### Step 4: Verify

After running, you should see:
- ✅ All tier values updated to valid ones
- ✅ Constraint recreated
- ✅ Query results showing tier distribution

## What the SQL Does

1. **Updates invalid tier values:**
   - `bronze` → `Amateur`
   - `silver` → `Semi-Pro`
   - `gold` → `Pro`
   - `platinum` → `Contender`
   - `diamond` → `Elite`

2. **Recreates the constraint** with correct values

3. **Sets default tier** to `Amateur`

4. **Fixes any NULL tiers**

## After Running the SQL

1. **Try updating a fighter profile** again
2. **The error should be gone**
3. **All tier values will be valid**

## If You Still Get Errors

1. **Check Supabase logs:**
   - Dashboard → Logs → Postgres Logs
   - Look for any SQL errors

2. **Verify constraint exists:**
   ```sql
   SELECT conname, pg_get_constraintdef(oid)
   FROM pg_constraint
   WHERE conrelid = 'fighter_profiles'::regclass
   AND conname = 'fighter_profiles_tier_check';
   ```

3. **Check for invalid values:**
   ```sql
   SELECT tier, COUNT(*) 
   FROM fighter_profiles
   WHERE tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite')
   GROUP BY tier;
   ```

---

**Remember: Copy the SQL script, NOT the browser error message!**

