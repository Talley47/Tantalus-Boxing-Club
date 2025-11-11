-- Fix the fighter profile trigger to match the actual schema
-- This fixes the "Database error saving new user" error during registration
-- Updated to include platform and timezone fields
-- Enhanced with better logging and error handling to ensure physical information is saved
-- Run this in Supabase SQL Editor

-- Drop and recreate the function with correct columns
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
BEGIN
    -- Only create fighter profile if user is a fighter (not admin)
    -- Check role from metadata
    IF COALESCE(
        (NEW.raw_app_meta_data->>'role')::TEXT,
        (NEW.raw_user_meta_data->>'role')::TEXT,
        'fighter'
    ) = 'fighter' THEN
        -- Extract fighter name (priority: fighterName only - do NOT use account name)
        -- The fighter name should always be provided during registration
        -- Check multiple possible field names
        fighter_name := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighterName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighter_name'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxerName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxer_name'), ''),
            'Fighter'  -- Fallback only if fighterName is not provided (shouldn't happen)
        );
        
        -- Parse birthday
        IF NEW.raw_user_meta_data->>'birthday' IS NOT NULL THEN
            fighter_birthday := (NEW.raw_user_meta_data->>'birthday')::DATE;
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
        
        -- Parse height - handle both JSONB numeric and text values
        -- Registration form sends height_feet and height_inches directly (in imperial units)
        IF NEW.raw_user_meta_data ? 'height_feet' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'height_feet') = 'number' THEN
                    fighter_height_feet := (NEW.raw_user_meta_data->>'height_feet')::INTEGER;
                ELSIF NEW.raw_user_meta_data->>'height_feet' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'height_feet') != '' THEN
                    fighter_height_feet := (NEW.raw_user_meta_data->>'height_feet')::INTEGER;
                ELSE
                    RAISE WARNING 'height_feet is empty, using default 5';
                    fighter_height_feet := 5;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid height_feet: %, using default 5', NEW.raw_user_meta_data->'height_feet';
                fighter_height_feet := 5;
            END;
        ELSE
            RAISE WARNING 'height_feet key not found in metadata, using default 5';
            fighter_height_feet := 5;
        END IF;
        
        IF NEW.raw_user_meta_data ? 'height_inches' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'height_inches') = 'number' THEN
                    fighter_height_inches := (NEW.raw_user_meta_data->>'height_inches')::INTEGER;
                ELSIF NEW.raw_user_meta_data->>'height_inches' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'height_inches') != '' THEN
                    fighter_height_inches := (NEW.raw_user_meta_data->>'height_inches')::INTEGER;
                ELSE
                    RAISE WARNING 'height_inches is empty, using default 8';
                    fighter_height_inches := 8;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid height_inches: %, using default 8', NEW.raw_user_meta_data->'height_inches';
                fighter_height_inches := 8;
            END;
        ELSE
            RAISE WARNING 'height_inches key not found in metadata, using default 8';
            fighter_height_inches := 8;
        END IF;
        
        -- Parse reach (registration sends in cm, convert to inches for storage)
        IF NEW.raw_user_meta_data ? 'reach' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'reach') = 'number' THEN
                    -- Numeric value - convert directly
                    fighter_reach := ROUND((NEW.raw_user_meta_data->>'reach')::NUMERIC / 2.54)::INTEGER;
                ELSIF NEW.raw_user_meta_data->>'reach' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'reach') != '' THEN
                    -- String value - convert to numeric then to inches
                    fighter_reach := ROUND((NEW.raw_user_meta_data->>'reach')::NUMERIC / 2.54)::INTEGER;
                ELSE
                    RAISE WARNING 'reach is empty, using default 70';
                    fighter_reach := 70;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid reach: %, using default 70. Error: %', NEW.raw_user_meta_data->'reach', SQLERRM;
                fighter_reach := 70;
            END;
        ELSE
            RAISE WARNING 'reach key not found in metadata, using default 70';
            fighter_reach := 70;
        END IF;
        
        -- Parse weight (registration sends in kg, convert to lbs for storage)
        IF NEW.raw_user_meta_data ? 'weight' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'weight') = 'number' THEN
                    -- Numeric value - convert directly
                    fighter_weight := ROUND((NEW.raw_user_meta_data->>'weight')::NUMERIC / 0.453592)::INTEGER;
                ELSIF NEW.raw_user_meta_data->>'weight' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'weight') != '' THEN
                    -- String value - convert to numeric then to lbs
                    fighter_weight := ROUND((NEW.raw_user_meta_data->>'weight')::NUMERIC / 0.453592)::INTEGER;
                ELSE
                    RAISE WARNING 'weight is empty, using default 150';
                    fighter_weight := 150;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid weight: %, using default 150. Error: %', NEW.raw_user_meta_data->'weight', SQLERRM;
                fighter_weight := 150;
            END;
        ELSE
            RAISE WARNING 'weight key not found in metadata, using default 150';
            fighter_weight := 150;
        END IF;
        
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
    END IF;
  
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log detailed error information for debugging
        RAISE WARNING 'Error creating fighter profile for user % (email: %): %', 
            NEW.id, 
            NEW.email,
            SQLERRM;
        RAISE WARNING 'Fighter name extracted: %', fighter_name;
        RAISE WARNING 'Height: % feet % inches', fighter_height_feet, fighter_height_inches;
        RAISE WARNING 'Weight: % lbs, Reach: % inches', fighter_weight, fighter_reach;
        RAISE WARNING 'Metadata keys: %', (SELECT array_agg(key) FROM jsonb_each_text(NEW.raw_user_meta_data));
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

-- Grant execute permission on the function to ensure it can run
GRANT EXECUTE ON FUNCTION public.handle_new_fighter_profile_from_auth() TO postgres, anon, authenticated, service_role;

COMMENT ON FUNCTION public.handle_new_fighter_profile_from_auth() IS 'Automatically creates a fighter_profiles entry when a new fighter signs up. Includes all physical information (height, weight, reach, stance, hometown, trainer, gym, platform, timezone, birthday). Uses SECURITY DEFINER to bypass RLS.';

