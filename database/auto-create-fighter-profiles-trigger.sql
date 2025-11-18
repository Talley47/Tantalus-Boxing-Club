-- Auto-create fighter_profiles when a user signs up with fighterName
-- This trigger ensures every new fighter gets a fighter profile automatically
-- Run this in Supabase SQL Editor

-- Create function to handle fighter profile creation after user signup
-- This runs AFTER auth.users INSERT, so we can access user metadata
-- This version dynamically checks which columns exist to support different schema versions
CREATE OR REPLACE FUNCTION public.handle_new_fighter_profile_from_auth()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    fighter_name TEXT;
    fighter_birthday DATE;
    fighter_hometown TEXT;
    fighter_stance TEXT;
    fighter_height_feet INTEGER;
    fighter_height_inches INTEGER;
    fighter_reach INTEGER;
    fighter_weight INTEGER;
    fighter_weight_class TEXT;
    fighter_trainer TEXT;
    fighter_gym TEXT;
    handle_value TEXT;
    has_platform BOOLEAN := FALSE;
    has_platform_id BOOLEAN := FALSE;
    has_timezone BOOLEAN := FALSE;
    fighter_platform TEXT;
    fighter_timezone TEXT;
BEGIN
    -- Only create fighter profile if user is a fighter (not admin)
    -- Check role from metadata
    IF COALESCE(
        (NEW.raw_app_meta_data->>'role')::TEXT,
        (NEW.raw_user_meta_data->>'role')::TEXT,
        'fighter'
    ) = 'fighter' THEN
        
        -- Check which columns exist in the table
        SELECT 
            EXISTS(SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'fighter_profiles' AND column_name = 'platform'),
            EXISTS(SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'fighter_profiles' AND column_name = 'platform_id'),
            EXISTS(SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'fighter_profiles' AND column_name = 'timezone')
        INTO has_platform, has_platform_id, has_timezone;
        
        -- Extract fighter name (priority: fighterName only - do NOT use account name)
        -- The fighter name should always be provided during registration
        -- Check multiple possible field names for fighter name
        fighter_name := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighterName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighter_name'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxerName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxer_name'), ''),
            'Fighter'  -- Fallback only if fighterName is not provided (shouldn't happen)
        );
        
        -- Generate handle from fighter name
        -- Make it unique by appending user ID to avoid conflicts
        -- Use first 8 chars of UUID to keep it short
        handle_value := LOWER(REPLACE(REGEXP_REPLACE(fighter_name, '[^a-zA-Z0-9 ]', '', 'g'), ' ', '_'));
        -- Ensure handle is not too long (max 50 chars typically, but we'll keep it shorter)
        IF LENGTH(handle_value) > 30 THEN
            handle_value := SUBSTRING(handle_value, 1, 30);
        END IF;
        -- Append user ID to ensure uniqueness
        handle_value := handle_value || '_' || SUBSTRING(REPLACE(NEW.id::TEXT, '-', ''), 1, 8);
        
        -- Parse birthday
        IF NEW.raw_user_meta_data->>'birthday' IS NOT NULL THEN
            BEGIN
                fighter_birthday := (NEW.raw_user_meta_data->>'birthday')::DATE;
            EXCEPTION
                WHEN OTHERS THEN
                    fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
            END;
        ELSE
            fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
        END IF;
        
        -- Extract other fields
        fighter_hometown := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'hometown'), ''), 'Unknown');
        fighter_stance := COALESCE(
            LOWER(NULLIF(TRIM(NEW.raw_user_meta_data->>'stance'), '')),
            'orthodox'
        );
        -- Ensure stance is valid
        IF fighter_stance NOT IN ('orthodox', 'southpaw', 'switch') THEN
            fighter_stance := 'orthodox';
        END IF;
        
        -- Extract platform/timezone only if columns exist
        IF has_platform THEN
            fighter_platform := COALESCE(
                NEW.raw_user_meta_data->>'platform',
                'PC'
            );
            -- Ensure platform is one of the valid values
            IF fighter_platform NOT IN ('PSN', 'Xbox', 'PC') THEN
                IF UPPER(fighter_platform) IN ('XBOX', 'X-BOX') THEN
                    fighter_platform := 'Xbox';
                ELSIF UPPER(fighter_platform) IN ('PSN', 'PLAYSTATION', 'PS4', 'PS5') THEN
                    fighter_platform := 'PSN';
                ELSIF UPPER(fighter_platform) IN ('PC', 'STEAM', 'COMPUTER') THEN
                    fighter_platform := 'PC';
                ELSE
                    fighter_platform := 'PC';
                END IF;
            END IF;
        END IF;
        
        IF has_timezone THEN
            fighter_timezone := COALESCE(
                NEW.raw_user_meta_data->>'timezone',
                'UTC'
            );
        END IF;
        
        -- Parse height - use height_feet/height_inches from metadata if available
        IF NEW.raw_user_meta_data->>'height_feet' IS NOT NULL THEN
            fighter_height_feet := (NEW.raw_user_meta_data->>'height_feet')::INTEGER;
            fighter_height_inches := COALESCE((NEW.raw_user_meta_data->>'height_inches')::INTEGER, 0);
        ELSE
            -- Default height if not provided
            fighter_height_feet := 5;
            fighter_height_inches := 8;
        END IF;
        
        -- Parse reach (registration sends in cm, but we store in inches)
        IF NEW.raw_user_meta_data->>'reach' IS NOT NULL THEN
            -- If reach is in cm (from registration conversion), convert to inches
            fighter_reach := ROUND((NEW.raw_user_meta_data->>'reach')::NUMERIC / 2.54)::INTEGER;
        ELSE
            fighter_reach := 70;
        END IF;
        
        -- Parse weight (registration sends in kg, but we store in lbs)
        IF NEW.raw_user_meta_data->>'weight' IS NOT NULL THEN
            -- If weight is in kg (from registration conversion), convert to lbs
            fighter_weight := ROUND((NEW.raw_user_meta_data->>'weight')::NUMERIC / 0.453592)::INTEGER;
        ELSE
            fighter_weight := 150;
        END IF;
        
        fighter_weight_class := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'weightClass'), ''), 'Middleweight');
        fighter_trainer := NULLIF(TRIM(NEW.raw_user_meta_data->>'trainer'), '');
        fighter_gym := NULLIF(TRIM(NEW.raw_user_meta_data->>'gym'), '');
        
        -- Ensure handle is unique - if it exists, append more of the UUID
        WHILE EXISTS (SELECT 1 FROM public.fighter_profiles WHERE handle = handle_value) LOOP
            handle_value := handle_value || '_' || SUBSTRING(REPLACE(NEW.id::TEXT, '-', ''), 1, 4);
        END LOOP;
        
        -- Create fighter profile with dynamic column insertion based on what exists
        IF has_platform AND has_platform_id AND has_timezone THEN
            -- Schema with platform, platform_id, timezone
            INSERT INTO public.fighter_profiles (
                user_id,
                name,
                handle,
                platform,
                platform_id,
                timezone,
                birthday,
                hometown,
                stance,
                height_feet,
                height_inches,
                reach,
                weight,
                weight_class,
                tier,
                trainer,
                gym,
                points,
                wins,
                losses,
                draws
            )
            VALUES (
                NEW.id,
                fighter_name,
                handle_value,
                fighter_platform,
                NEW.id::TEXT,
                fighter_timezone,
                fighter_birthday,
                fighter_hometown,
                fighter_stance,
                fighter_height_feet,
                fighter_height_inches,
                fighter_reach,
                fighter_weight,
                fighter_weight_class,
                'Amateur',
                fighter_trainer,
                fighter_gym,
                0,
                0,
                0,
                0
            )
            ON CONFLICT (user_id) DO NOTHING;
        ELSE
            -- Schema without platform, platform_id, timezone (COMPLETE_WORKING_SCHEMA.sql version)
            INSERT INTO public.fighter_profiles (
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
                tier,
                trainer,
                gym,
                points,
                wins,
                losses,
                draws
            )
            VALUES (
                NEW.id,
                fighter_name,
                handle_value,
                fighter_birthday,
                fighter_hometown,
                fighter_stance,
                fighter_height_feet,
                fighter_height_inches,
                fighter_reach,
                fighter_weight,
                fighter_weight_class,
                'Amateur',
                fighter_trainer,
                fighter_gym,
                0,
                0,
                0,
                0
            )
            ON CONFLICT (user_id) DO NOTHING;
        END IF;
    END IF;
  
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error with full details but don't fail the user creation
        -- This prevents the trigger from blocking user signup
        -- Use RAISE NOTICE so it appears in Supabase logs
        RAISE NOTICE 'Error creating fighter profile for user %: % (SQLSTATE: %)', 
            NEW.id, SQLERRM, SQLSTATE;
        RETURN NEW;
END;
$$;

-- Grant necessary permissions to the function
-- This ensures the function can insert into fighter_profiles even with RLS enabled
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.fighter_profiles TO postgres, service_role;

-- Create trigger on auth.users to create fighter profile after user signup
DROP TRIGGER IF EXISTS on_auth_user_created_fighter ON auth.users;

CREATE TRIGGER on_auth_user_created_fighter
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_fighter_profile_from_auth();

COMMENT ON FUNCTION public.handle_new_fighter_profile_from_auth() IS 'Automatically creates a fighter_profiles entry when a new fighter signs up';

-- =====================================================
-- DIAGNOSTIC QUERIES (Run these if registration still fails)
-- =====================================================

-- Check if trigger exists
-- SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created_fighter';

-- Check function exists
-- SELECT proname, proowner, prosecdef FROM pg_proc WHERE proname = 'handle_new_fighter_profile_from_auth';

-- Check table structure
-- SELECT column_name, data_type, is_nullable, column_default 
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' AND table_name = 'fighter_profiles' 
-- ORDER BY ordinal_position;

-- Check RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies 
-- WHERE tablename = 'fighter_profiles';

-- Test the function manually (replace USER_ID with an actual UUID)
-- SELECT public.handle_new_fighter_profile_from_auth() FROM auth.users WHERE id = 'USER_ID';

