-- ================================================
-- MANUAL ADMIN ACCOUNT CREATION
-- ================================================
-- Run this in Supabase Dashboard → SQL Editor
-- This will create the admin account directly in the database
-- ================================================

-- Step 1: Create admin account in Supabase Dashboard UI first
-- Go to: Authentication → Users → Add user → Create new user
-- Email: admin@tantalusboxing.com
-- Password: TantalusAdmin2025!
-- ✅ Check "Auto Confirm User"
-- Click "Create user"

-- Step 2: After creating the user, get the user ID
-- The user ID will be a UUID like: 12345678-1234-1234-1234-123456789012

-- Step 3: Run this SQL (replace USER_ID with the actual UUID from step 1)
-- ================================================

-- Insert profile (if not exists)
INSERT INTO profiles (id, email, full_name, role, created_at, updated_at)
VALUES (
  'REPLACE_WITH_USER_ID_FROM_AUTH_USERS',  -- Replace this!
  'admin@tantalusboxing.com',
  'Admin User',
  'admin',
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE 
SET role = 'admin', 
    full_name = 'Admin User';

-- Insert fighter profile (if not exists)
INSERT INTO fighter_profiles (
  user_id,
  name,
  handle,
  birthday,
  hometown,
  stance,
  height_feet,
  height_inches,
  reach,
  weight,
  weight_class,
  trainer,
  gym,
  tier,
  points,
  wins,
  losses,
  draws
)
VALUES (
  'REPLACE_WITH_USER_ID_FROM_AUTH_USERS',  -- Replace this!
  'Admin Fighter',
  'admin',
  '1994-01-01',
  'Admin City',
  'orthodox',
  6,
  0,
  72,
  200,
  'heavyweight',
  'System Trainer',
  'TBC HQ',
  'elite',
  1000,
  0,
  0,
  0
)
ON CONFLICT (user_id) DO NOTHING;

-- Verify the admin account was created
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.role,
  fp.name as fighter_name,
  fp.tier
FROM profiles p
LEFT JOIN fighter_profiles fp ON fp.user_id = p.id
WHERE p.email = 'admin@tantalusboxing.com';

-- ================================================
-- If successful, you should see:
-- email: admin@tantalusboxing.com
-- role: admin
-- fighter_name: Admin Fighter
-- tier: elite
-- ================================================


