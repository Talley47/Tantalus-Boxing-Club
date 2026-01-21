# 🚨 Fix Fighter Names Not Displaying

## Problem
Fighter names are not displaying correctly in the app. This could be because:
1. Names are NULL or empty in the database
2. Names are using email usernames instead of fighter names
3. Names don't match the `fighterName` stored in user metadata

## Solution (2 Steps)

### Step 1: Diagnose the Issue
Run this SQL in **Supabase Dashboard → SQL Editor**:

```sql
-- See database/DIAGNOSE-FIGHTER-NAMES.sql for full script
```

Or copy this quick check:
```sql
SELECT 
  fp.name as profile_name,
  fp.handle,
  au.email,
  au.raw_user_meta_data->>'fighterName' as metadata_fighter_name,
  CASE 
    WHEN fp.name IS NULL OR TRIM(fp.name) = '' THEN '❌ MISSING'
    WHEN au.raw_user_meta_data->>'fighterName' IS NOT NULL 
         AND fp.name != au.raw_user_meta_data->>'fighterName' THEN '⚠️ MISMATCH'
    ELSE '✅ OK'
  END as status
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
ORDER BY fp.created_at DESC;
```

### Step 2: Fix the Names
If you see ❌ MISSING or ⚠️ MISMATCH, run this SQL:

```sql
-- See database/FIX-FIGHTER-NAMES.sql for full script
```

Or copy this quick fix:
```sql
-- Update names from metadata
UPDATE public.fighter_profiles fp
SET name = (
    SELECT au.raw_user_meta_data->>'fighterName' 
    FROM auth.users au 
    WHERE au.id = fp.user_id
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND TRIM(au.raw_user_meta_data->>'fighterName') != ''
)
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND TRIM(au.raw_user_meta_data->>'fighterName') != ''
    AND (
        fp.name IS NULL 
        OR TRIM(fp.name) = ''
        OR fp.name != au.raw_user_meta_data->>'fighterName'
    )
);

-- Update handles to match
UPDATE public.fighter_profiles fp
SET handle = LOWER(REPLACE(
    REGEXP_REPLACE(
        COALESCE(
            (SELECT au.raw_user_meta_data->>'fighterName' 
             FROM auth.users au 
             WHERE au.id = fp.user_id
             AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
             AND TRIM(au.raw_user_meta_data->>'fighterName') != ''),
            fp.name
        ),
        '[^a-zA-Z0-9 ]', '', 'g'
    ),
    ' ', '_'
))
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND TRIM(au.raw_user_meta_data->>'fighterName') != ''
);
```

## After Running the Fix

1. **Hard refresh your browser** (`Ctrl+Shift+R`)
2. **Log out and log back in** (to refresh your session)
3. **Check fighter names** - they should now display correctly

## If Names Are Still Wrong

If fighters don't have `fighterName` in their metadata, you'll need to:
1. Update the `fighter_profiles.name` column directly in Supabase Dashboard
2. Or have fighters update their profiles through the app

## Files Created

- `database/DIAGNOSE-FIGHTER-NAMES.sql` - Full diagnostic script
- `database/FIX-FIGHTER-NAMES.sql` - Full fix script
