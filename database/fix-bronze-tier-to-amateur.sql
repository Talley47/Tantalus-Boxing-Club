-- Fix fighters with incorrect tier and name issues
-- This script updates existing fighters who were incorrectly set to 'bronze' tier
-- or have account names instead of fighter names
-- Run this in Supabase SQL Editor

-- Step 1: Update all fighters with 'bronze' tier to 'amateur'
-- Only update fighters who have 0 points and 0 wins (new fighters)
UPDATE fighter_profiles
SET tier = 'amateur'
WHERE tier = 'bronze'
  AND points = 0
  AND wins = 0
  AND losses = 0
  AND draws = 0;

-- Step 2: Also update any fighters with 'bronze' tier regardless of stats
-- (in case there are any edge cases)
UPDATE fighter_profiles
SET tier = 'amateur'
WHERE tier = 'bronze';

-- Step 3: Fix fighters who have account names instead of fighter names
-- Check if name looks like an email or account name (contains @ or is very generic)
-- Note: This requires manual review - you may need to update these manually
-- by checking the user's metadata in auth.users table

-- First, let's see which fighters might have the wrong name
SELECT 
  fp.id,
  fp.user_id,
  fp.name as current_name,
  fp.handle,
  fp.tier,
  u.email,
  u.raw_user_meta_data->>'fighterName' as fighter_name_from_metadata,
  u.raw_user_meta_data->>'name' as account_name_from_metadata,
  fp.created_at
FROM fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
WHERE 
  -- Check if name looks like an email (contains @)
  fp.name LIKE '%@%'
  OR 
  -- Check if name is very generic (like "Fighter" or email prefix)
  fp.name = 'Fighter'
  OR
  -- Check if name matches email prefix (likely account name)
  LOWER(REPLACE(fp.name, ' ', '')) = LOWER(REPLACE(split_part(u.email, '@', 1), '_', ''))
ORDER BY fp.created_at DESC;

-- Step 4: Update fighters with wrong names (if fighterName exists in metadata)
-- This will update fighters whose name matches their email prefix or is generic
UPDATE fighter_profiles fp
SET 
  name = COALESCE(
    NULLIF(TRIM((u.raw_user_meta_data->>'fighterName')::TEXT), ''),
    NULLIF(TRIM((u.raw_user_meta_data->>'fighter_name')::TEXT), ''),
    NULLIF(TRIM((u.raw_user_meta_data->>'boxerName')::TEXT), ''),
    fp.name  -- Keep current name if no fighter name found
  ),
  handle = LOWER(REPLACE(
    COALESCE(
      NULLIF(TRIM((u.raw_user_meta_data->>'fighterName')::TEXT), ''),
      NULLIF(TRIM((u.raw_user_meta_data->>'fighter_name')::TEXT), ''),
      NULLIF(TRIM((u.raw_user_meta_data->>'boxerName')::TEXT), ''),
      fp.name
    ),
    ' ', '_'
  ))
FROM auth.users u
WHERE fp.user_id = u.id
  AND (
    -- Only update if fighterName exists in metadata and is different from current name
    (u.raw_user_meta_data->>'fighterName')::TEXT IS NOT NULL
    OR (u.raw_user_meta_data->>'fighter_name')::TEXT IS NOT NULL
    OR (u.raw_user_meta_data->>'boxerName')::TEXT IS NOT NULL
  )
  AND (
    -- And current name looks wrong (like email or generic)
    fp.name LIKE '%@%'
    OR fp.name = 'Fighter'
    OR LOWER(REPLACE(fp.name, ' ', '')) = LOWER(REPLACE(split_part(u.email, '@', 1), '_', ''))
  );

-- Step 5: Verify the updates
SELECT 
  id,
  name,
  handle,
  tier,
  points,
  wins,
  losses,
  draws,
  created_at
FROM fighter_profiles
WHERE tier = 'bronze'
ORDER BY created_at DESC;

-- If the above query returns 0 rows, all tier issues have been fixed

-- Step 6: Check for any remaining name issues
SELECT 
  fp.id,
  fp.name,
  fp.handle,
  u.email,
  u.raw_user_meta_data->>'fighterName' as fighter_name_in_metadata
FROM fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
WHERE 
  fp.name LIKE '%@%'
  OR fp.name = 'Fighter'
  OR (u.raw_user_meta_data->>'fighterName')::TEXT IS NOT NULL
    AND fp.name != (u.raw_user_meta_data->>'fighterName')::TEXT
ORDER BY fp.created_at DESC;

