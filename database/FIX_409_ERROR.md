# Fix for 409 Error on championship_belts Table

## Problem

You're seeing a 409 (Conflict) error when trying to query the `championship_belts` table:
```
andmtvsqqomgwphotdwf.supabase.co/rest/v1/championship_belts?select=*:1  Failed to load resource: the server responded with a status of 409 ()
```

## Root Cause

The 409 error is caused by **conflicting Row Level Security (RLS) policies** on the `championship_belts` table. Specifically:

1. The original setup had a policy `"Admins can manage championship belts"` that used `FOR ALL`, which includes SELECT operations
2. There were also separate SELECT policies (`"Public can view all championship belts"` and `"Fighters can view their own belts"`)
3. Having multiple policies that overlap for the same operation (SELECT) can cause conflicts in Supabase, resulting in a 409 error

## Solution

The fix separates the admin policies into individual policies for each operation (INSERT, UPDATE, DELETE) instead of using `FOR ALL`. This eliminates the conflict.

### Quick Fix

Run the fix script in your Supabase SQL Editor:

```sql
-- File: database/fix-championship-belts-rls-409.sql
```

This script will:
1. Drop all existing conflicting policies
2. Recreate them with separate policies for each operation
3. Keep the public SELECT policy (which allows everyone to view belts)

### What Changed

**Before (causing conflicts):**
- `"Admins can manage championship belts"` - FOR ALL (includes SELECT, INSERT, UPDATE, DELETE)
- `"Public can view all championship belts"` - FOR SELECT
- `"Fighters can view their own belts"` - FOR SELECT

**After (no conflicts):**
- `"Public can view all championship belts"` - FOR SELECT (everyone can view)
- `"Admins can insert championship belts"` - FOR INSERT
- `"Admins can update championship belts"` - FOR UPDATE
- `"Admins can delete championship belts"` - FOR DELETE

## How to Apply the Fix

1. Open your Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `database/fix-championship-belts-rls-409.sql`
4. Run the script
5. Refresh your application - the 409 error should be resolved

## Verification

After running the fix, you should be able to:
- ✅ Query `championship_belts` without getting 409 errors
- ✅ View belts on fighter profiles
- ✅ Admins can still insert, update, and delete belts
- ✅ All users can view all belts (as intended)

## Prevention

The original `create-championship-belts-table.sql` file has been updated to use the new policy structure, so future installations won't have this issue.

