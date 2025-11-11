-- Update Profiles Table Default Role to 'fighter'
-- This ensures all new users get the 'fighter' role instead of 'user'
-- Run this in Supabase SQL Editor

-- Update the default value for the role column
ALTER TABLE public.profiles 
    ALTER COLUMN role SET DEFAULT 'fighter';

-- If there are any existing users with role='user', update them to 'fighter'
-- (unless they are admins)
UPDATE public.profiles
SET role = 'fighter'
WHERE role = 'user' 
  AND id NOT IN (
    SELECT id FROM public.profiles WHERE role = 'admin'
  );

-- Verify the change
SELECT 
    role,
    COUNT(*) as count
FROM public.profiles
GROUP BY role
ORDER BY role;

-- Note: This script only updates the role default and existing data.
-- If you need to update RLS policies, run the setup-profiles-for-existing-users.sql
-- or fix-fighter-profiles-rls.sql scripts first.
