-- Fix search_path for prevent_opponents_training_camp and are_fighters_opponents functions
-- This addresses the security issue where functions should have a fixed search_path
-- to prevent search path injection attacks

-- Fix prevent_opponents_training_camp() if it exists
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
          AND p.proname = 'prevent_opponents_training_camp'
    LOOP
        IF func_record.func_args = '' THEN
            EXECUTE format('ALTER FUNCTION %I.%I() SET search_path = public', 'public', func_record.func_name);
        ELSE
            EXECUTE format('ALTER FUNCTION %I.%I(%s) SET search_path = public', 'public', func_record.func_name, func_record.func_args);
        END IF;
        RAISE NOTICE 'Fixed search_path for %(%)', func_record.func_name, func_record.func_args;
    END LOOP;
END $$;

-- Fix are_fighters_opponents() if it exists
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
          AND p.proname = 'are_fighters_opponents'
    LOOP
        IF func_record.func_args = '' THEN
            EXECUTE format('ALTER FUNCTION %I.%I() SET search_path = public', 'public', func_record.func_name);
        ELSE
            EXECUTE format('ALTER FUNCTION %I.%I(%s) SET search_path = public', 'public', func_record.func_name, func_record.func_args);
        END IF;
        RAISE NOTICE 'Fixed search_path for %(%)', func_record.func_name, func_record.func_args;
    END LOOP;
END $$;

-- Verify the fixes
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
  AND (p.proname = 'prevent_opponents_training_camp' OR p.proname = 'are_fighters_opponents')
ORDER BY p.proname, p.oid;

