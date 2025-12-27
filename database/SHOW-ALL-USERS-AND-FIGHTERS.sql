-- ============================================================================
-- 📊 SHOW ALL USERS, PROFILES, AND FIGHTER ACCOUNTS
-- ============================================================================
-- Copy this entire file into Supabase SQL Editor and run it
-- This will display all user accounts, profiles, and fighter data
-- ============================================================================

-- ============================================================================
-- SECTION 1: ALL PROFILES (USER ACCOUNTS)
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;
  
SELECT 
  'SECTION 1: ALL USER PROFILES' as section_name,
  COUNT(*) as total_profiles
FROM public.profiles;

SELECT 
  id,
  email,
  full_name,
  role,
  created_at,
  updated_at
FROM public.profiles
ORDER BY created_at DESC;

-- ============================================================================
-- SECTION 2: ALL FIGHTER PROFILES
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 2: ALL FIGHTER PROFILES' as section_name,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id,
  COUNT(*) FILTER (WHERE user_id IS NULL) as fighters_without_user_id
FROM public.fighter_profiles;

SELECT 
  id,
  user_id,
  name,
  handle,
  tier,
  points,
  weight_class,
  wins,
  losses,
  draws,
  created_at,
  updated_at
FROM public.fighter_profiles
ORDER BY points DESC, name ASC;

-- ============================================================================
-- SECTION 3: USERS WITH FIGHTER PROFILES (JOINED VIEW)
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 3: USERS WITH FIGHTER PROFILES (JOINED)' as section_name,
  COUNT(*) as total_users_with_fighters
FROM public.profiles p
INNER JOIN public.fighter_profiles fp ON p.id = fp.user_id;

SELECT 
  p.id as user_id,
  p.email,
  p.full_name as user_full_name,
  p.role as user_role,
  fp.id as fighter_profile_id,
  fp.name as fighter_name,
  fp.handle,
  fp.tier,
  fp.points,
  fp.weight_class,
  fp.wins,
  fp.losses,
  fp.draws,
  fp.created_at as fighter_created_at
FROM public.profiles p
INNER JOIN public.fighter_profiles fp ON p.id = fp.user_id
ORDER BY fp.points DESC, fp.name ASC;

-- ============================================================================
-- SECTION 4: USERS WITHOUT FIGHTER PROFILES
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 4: USERS WITHOUT FIGHTER PROFILES' as section_name,
  COUNT(*) as total_users_without_fighters
FROM public.profiles p
LEFT JOIN public.fighter_profiles fp ON p.id = fp.user_id
WHERE fp.id IS NULL;

SELECT 
  p.id as user_id,
  p.email,
  p.full_name,
  p.role,
  p.created_at
FROM public.profiles p
LEFT JOIN public.fighter_profiles fp ON p.id = fp.user_id
WHERE fp.id IS NULL
ORDER BY p.created_at DESC;

-- ============================================================================
-- SECTION 5: FIGHTER PROFILES WITHOUT USER ACCOUNTS
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 5: FIGHTER PROFILES WITHOUT USER ACCOUNTS (orphaned)' as section_name,
  COUNT(*) as total_orphaned_fighters
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE fp.user_id IS NOT NULL AND p.id IS NULL;

SELECT 
  fp.id as fighter_profile_id,
  fp.user_id,
  fp.name,
  fp.handle,
  fp.tier,
  fp.points,
  fp.weight_class,
  fp.wins,
  fp.losses,
  fp.draws,
  fp.created_at
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE fp.user_id IS NOT NULL AND p.id IS NULL
ORDER BY fp.points DESC;

-- ============================================================================
-- SECTION 6: SUMMARY STATISTICS
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 6: SUMMARY STATISTICS' as section_name;

SELECT 
  'Total Users' as metric,
  COUNT(*)::text as value
FROM public.profiles
UNION ALL
SELECT 
  'Total Fighter Profiles' as metric,
  COUNT(*)::text as value
FROM public.fighter_profiles
UNION ALL
SELECT 
  'Users with Fighter Profiles' as metric,
  COUNT(DISTINCT p.id)::text as value
FROM public.profiles p
INNER JOIN public.fighter_profiles fp ON p.id = fp.user_id
UNION ALL
SELECT 
  'Users without Fighter Profiles' as metric,
  COUNT(*)::text as value
FROM public.profiles p
LEFT JOIN public.fighter_profiles fp ON p.id = fp.user_id
WHERE fp.id IS NULL
UNION ALL
SELECT 
  'Fighter Profiles with User Accounts' as metric,
  COUNT(*)::text as value
FROM public.fighter_profiles fp
INNER JOIN public.profiles p ON fp.user_id = p.id
UNION ALL
SELECT 
  'Fighter Profiles without User Accounts' as metric,
  COUNT(*)::text as value
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE fp.user_id IS NOT NULL AND p.id IS NULL
UNION ALL
SELECT 
  'Fighter Profiles with NULL user_id' as metric,
  COUNT(*)::text as value
FROM public.fighter_profiles
WHERE user_id IS NULL
UNION ALL
SELECT 
  'Admin Users' as metric,
  COUNT(*)::text as value
FROM public.profiles
WHERE role = 'admin'
UNION ALL
SELECT 
  'Top Fighter Points' as metric,
  COALESCE(MAX(points)::text, '0') as value
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- ============================================================================
-- SECTION 7: FIGHTERS BY TIER
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 7: FIGHTERS BY TIER' as section_name;

SELECT 
  tier,
  COUNT(*) as fighter_count,
  AVG(points)::numeric(10,2) as avg_points,
  MAX(points) as max_points,
  MIN(points) as min_points
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
GROUP BY tier
ORDER BY 
  CASE tier
    WHEN 'Professional' THEN 1
    WHEN 'Elite' THEN 2
    WHEN 'Advanced' THEN 3
    WHEN 'Intermediate' THEN 4
    WHEN 'Amateur' THEN 5
    ELSE 6
  END;

-- ============================================================================
-- SECTION 8: FIGHTERS BY WEIGHT CLASS
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  'SECTION 8: FIGHTERS BY WEIGHT CLASS' as section_name;

SELECT 
  weight_class,
  COUNT(*) as fighter_count,
  AVG(points)::numeric(10,2) as avg_points
FROM public.fighter_profiles
WHERE user_id IS NOT NULL AND weight_class IS NOT NULL
GROUP BY weight_class
ORDER BY fighter_count DESC;

-- ============================================================================
-- ✅ DISPLAY COMPLETE
-- ============================================================================
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as separator;

SELECT 
  '✅ ALL DATA DISPLAYED ABOVE' as completion_message;

