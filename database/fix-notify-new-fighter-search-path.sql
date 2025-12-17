-- Fix search_path for notify_new_fighter function(s)
-- This addresses the security issue where functions with SECURITY DEFINER
-- should have a fixed search_path to prevent search path injection attacks

-- Fix notify_new_fighter_joined() if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'notify_new_fighter_joined'
    ) THEN
        ALTER FUNCTION public.notify_new_fighter_joined()
        SET search_path = public;
        
        RAISE NOTICE 'Fixed search_path for notify_new_fighter_joined()';
    END IF;
END $$;

-- Fix notify_new_fighter() if it exists (without _joined suffix)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'notify_new_fighter'
    ) THEN
        ALTER FUNCTION public.notify_new_fighter()
        SET search_path = public;
        
        RAISE NOTICE 'Fixed search_path for notify_new_fighter()';
    END IF;
END $$;

-- Verify the fix
SELECT 
    p.proname as function_name,
    CASE 
        WHEN p.proconfig IS NULL THEN '❌ No search_path set'
        WHEN array_to_string(p.proconfig, ', ') LIKE '%search_path%' THEN '✅ search_path set'
        ELSE '⚠️ Other config'
    END as search_path_status,
    array_to_string(p.proconfig, ', ') as config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND (p.proname LIKE 'notify_new_fighter%' OR p.proname = 'notify_new_fighter')
ORDER BY p.proname;

