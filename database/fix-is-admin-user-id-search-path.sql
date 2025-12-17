-- Fix search_path for is_admin_user_id function
-- This addresses the security issue where functions should have a fixed search_path
-- to prevent search path injection attacks
-- This is especially critical for SECURITY DEFINER functions

-- Fix is_admin_user_id() if it exists
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT 
            p.proname as func_name,
            pg_get_function_identity_arguments(p.oid) as func_args,
            p.oid as func_oid
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'is_admin_user_id'
    LOOP
        IF func_record.func_args = '' THEN
            EXECUTE format('ALTER FUNCTION %I.%I() SET search_path = public', 'public', func_record.func_name);
        ELSE
            EXECUTE format('ALTER FUNCTION %I.%I(%s) SET search_path = public', 'public', func_record.func_name, func_record.func_args);
        END IF;
        RAISE NOTICE 'Fixed search_path for %(%)', func_record.func_name, func_record.func_args;
    END LOOP;
END $$;

-- Verify the fix
SELECT 
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as function_arguments,
    CASE 
        WHEN p.proconfig IS NULL THEN '❌ No search_path set'
        WHEN array_to_string(p.proconfig, ', ') LIKE '%search_path%' THEN '✅ search_path set'
        ELSE '⚠️ Other config'
    END as search_path_status,
    array_to_string(p.proconfig, ', ') as config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'is_admin_user_id'
ORDER BY p.proname, p.oid;

