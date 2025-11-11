-- Fix the fighter profile trigger to ensure physical information is saved correctly
-- This script ensures the trigger properly extracts and saves all physical information
-- Run this in Supabase SQL Editor

-- First, ensure the trigger function has proper permissions
-- The function uses SECURITY DEFINER, so it should bypass RLS
-- But we need to make sure it can insert into fighter_profiles

-- Drop and recreate the function with enhanced logging and error handling
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
    fighter_platform TEXT;
    fighter_timezone TEXT;
    metadata_keys TEXT[];
BEGIN
    -- Only create fighter profile if user is a fighter (not admin)
    -- Check role from metadata
    IF COALESCE(
        (NEW.raw_app_meta_data->>'role')::TEXT,
        (NEW.raw_user_meta_data->>'role')::TEXT,
        'fighter'
    ) = 'fighter' THEN
        
        -- Log metadata keys for debugging (only in development)
        metadata_keys := ARRAY(SELECT jsonb_object_keys(NEW.raw_user_meta_data));
        RAISE NOTICE 'Creating fighter profile for user % (email: %). Metadata keys: %', 
            NEW.id, NEW.email, array_to_string(metadata_keys, ', ');
        
        -- Extract fighter name (priority: fighterName only - do NOT use account name)
        -- Check multiple possible field names
        fighter_name := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighterName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighter_name'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxerName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxer_name'), ''),
            'Fighter'  -- Fallback only if fighterName is not provided (shouldn't happen)
        );
        
        RAISE NOTICE 'Fighter name extracted: %', fighter_name;
        
        -- Parse birthday
        IF NEW.raw_user_meta_data->>'birthday' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'birthday') != '' THEN
            BEGIN
                fighter_birthday := (NEW.raw_user_meta_data->>'birthday')::DATE;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid birthday format: %, using default', NEW.raw_user_meta_data->>'birthday';
                fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
            END;
        ELSE
            fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
        END IF;
        
        -- Extract other fields
        fighter_hometown := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'hometown'), ''),
            'Unknown'
        );
        
        -- Handle stance - registration form sends capitalized values (Orthodox, Southpaw, Switch)
        -- Convert to lowercase to match database constraint
        fighter_stance := COALESCE(
            LOWER(NULLIF(TRIM(NEW.raw_user_meta_data->>'stance'), '')),
            'orthodox'
        );
        
        -- Ensure stance is valid (orthodox, southpaw, or switch)
        IF fighter_stance NOT IN ('orthodox', 'southpaw', 'switch') THEN
            fighter_stance := 'orthodox';
        END IF;
        
        -- Parse height - use height_feet/height_inches from metadata if available
        -- Registration form sends height_feet and height_inches directly (in imperial units)
        IF NEW.raw_user_meta_data->>'height_feet' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'height_feet') != '' THEN
            BEGIN
                fighter_height_feet := (NEW.raw_user_meta_data->>'height_feet')::INTEGER;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid height_feet: %, using default 5', NEW.raw_user_meta_data->>'height_feet';
                fighter_height_feet := 5;
            END;
        ELSE
            fighter_height_feet := 5;
        END IF;
        
        IF NEW.raw_user_meta_data->>'height_inches' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'height_inches') != '' THEN
            BEGIN
                fighter_height_inches := (NEW.raw_user_meta_data->>'height_inches')::INTEGER;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid height_inches: %, using default 8', NEW.raw_user_meta_data->>'height_inches';
                fighter_height_inches := 8;
            END;
        ELSE
            fighter_height_inches := 8;
        END IF;
        
        RAISE NOTICE 'Height extracted: % feet % inches', fighter_height_feet, fighter_height_inches;
        
        -- Parse reach (registration sends in cm, convert to inches for storage)
        IF NEW.raw_user_meta_data->>'reach' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'reach') != '' THEN
            BEGIN
                -- Registration form converts to cm, so convert back to inches
                fighter_reach := ROUND((NEW.raw_user_meta_data->>'reach')::NUMERIC / 2.54)::INTEGER;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid reach: %, using default 70', NEW.raw_user_meta_data->>'reach';
                fighter_reach := 70;
            END;
        ELSE
            fighter_reach := 70;
        END IF;
        
        RAISE NOTICE 'Reach extracted: % cm -> % inches', NEW.raw_user_meta_data->>'reach', fighter_reach;
        
        -- Parse weight (registration sends in kg, convert to lbs for storage)
        IF NEW.raw_user_meta_data->>'weight' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'weight') != '' THEN
            BEGIN
                -- Registration form converts to kg, so convert back to lbs
                fighter_weight := ROUND((NEW.raw_user_meta_data->>'weight')::NUMERIC / 0.453592)::INTEGER;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid weight: %, using default 150', NEW.raw_user_meta_data->>'weight';
                fighter_weight := 150;
            END;
        ELSE
            fighter_weight := 150;
        END IF;
        
        RAISE NOTICE 'Weight extracted: % kg -> % lbs', NEW.raw_user_meta_data->>'weight', fighter_weight;
        
        -- Extract weight class, trainer, and gym
        fighter_weight_class := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'weightClass'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'weight_class'), ''),
            'Middleweight'
        );
        fighter_trainer := NULLIF(TRIM(NEW.raw_user_meta_data->>'trainer'), '');
        fighter_gym := NULLIF(TRIM(NEW.raw_user_meta_data->>'gym'), '');
        
        -- Extract platform and timezone (optional)
        fighter_platform := NULLIF(TRIM(NEW.raw_user_meta_data->>'platform'), '');
        fighter_timezone := NULLIF(TRIM(NEW.raw_user_meta_data->>'timezone'), '');
        
        RAISE NOTICE 'Physical info: hometown=%, stance=%, weight_class=%, trainer=%, gym=%, platform=%, timezone=%', 
            fighter_hometown, fighter_stance, fighter_weight_class, fighter_trainer, fighter_gym, fighter_platform, fighter_timezone;
    
        -- Create fighter profile (including platform and timezone if provided)
        -- Using SECURITY DEFINER, this should bypass RLS
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
            platform,
            timezone,
            points,
            wins,
            losses,
            draws
        )
        VALUES (
            NEW.id,
            fighter_name,
            LOWER(REPLACE(fighter_name, ' ', '_')),
            fighter_birthday,
            fighter_hometown,
            fighter_stance,
            fighter_height_feet,
            fighter_height_inches,
            fighter_reach,
            fighter_weight,
            fighter_weight_class,
            'amateur',  -- Use lowercase to match constraint
            fighter_trainer,
            fighter_gym,
            fighter_platform,
            fighter_timezone,
            0,
            0,
            0,
            0
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE 'Fighter profile created successfully for user %', NEW.id;
    END IF;
  
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log detailed error information for debugging
        RAISE WARNING 'Error creating fighter profile for user % (email: %): %', 
            NEW.id, 
            NEW.email,
            SQLERRM;
        RAISE WARNING 'SQLSTATE: %', SQLSTATE;
        RAISE WARNING 'Fighter name extracted: %', fighter_name;
        RAISE WARNING 'Height: % feet % inches', fighter_height_feet, fighter_height_inches;
        RAISE WARNING 'Weight: % lbs, Reach: % inches', fighter_weight, fighter_reach;
        RAISE WARNING 'Metadata keys: %', array_to_string(metadata_keys, ', ');
        -- Don't fail the user creation - allow registration to succeed
        RETURN NEW;
END;
$$;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created_fighter ON auth.users;

CREATE TRIGGER on_auth_user_created_fighter
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_fighter_profile_from_auth();

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.handle_new_fighter_profile_from_auth() TO postgres, anon, authenticated, service_role;

COMMENT ON FUNCTION public.handle_new_fighter_profile_from_auth() IS 'Automatically creates a fighter_profiles entry when a new fighter signs up. Includes enhanced logging and error handling to ensure all physical information is saved correctly.';

-- Verify the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created_fighter';

