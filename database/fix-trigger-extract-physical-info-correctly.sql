-- Fix the trigger to correctly extract physical information from registration
-- The issue is that the trigger is using default values instead of actual registration data
-- Run this in Supabase SQL Editor

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
    height_feet_str TEXT;
    height_inches_str TEXT;
    reach_str TEXT;
    weight_str TEXT;
BEGIN
    -- Only create fighter profile if user is a fighter (not admin)
    IF COALESCE(
        (NEW.raw_app_meta_data->>'role')::TEXT,
        (NEW.raw_user_meta_data->>'role')::TEXT,
        'fighter'
    ) = 'fighter' THEN
        
        -- DEBUG: Log all metadata keys and values
        RAISE NOTICE '=== TRIGGER DEBUG START ===';
        RAISE NOTICE 'User ID: %, Email: %', NEW.id, NEW.email;
        RAISE NOTICE 'Raw user metadata: %', NEW.raw_user_meta_data::TEXT;
        
        -- Extract fighter name
        fighter_name := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighterName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighter_name'), ''),
            'Fighter'
        );
        RAISE NOTICE 'Fighter name: %', fighter_name;
        
        -- Parse birthday
        IF NEW.raw_user_meta_data->>'birthday' IS NOT NULL AND TRIM(NEW.raw_user_meta_data->>'birthday') != '' THEN
            BEGIN
                fighter_birthday := (NEW.raw_user_meta_data->>'birthday')::DATE;
                RAISE NOTICE 'Birthday: %', fighter_birthday;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid birthday: %, using default', NEW.raw_user_meta_data->>'birthday';
                fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
            END;
        ELSE
            RAISE WARNING 'No birthday in metadata, using default';
            fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
        END IF;
        
        -- Extract hometown
        fighter_hometown := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'hometown'), ''),
            'Unknown'
        );
        RAISE NOTICE 'Hometown: %', fighter_hometown;
        
        -- Extract stance
        fighter_stance := COALESCE(
            LOWER(NULLIF(TRIM(NEW.raw_user_meta_data->>'stance'), '')),
            'orthodox'
        );
        IF fighter_stance NOT IN ('orthodox', 'southpaw', 'switch') THEN
            fighter_stance := 'orthodox';
        END IF;
        RAISE NOTICE 'Stance: %', fighter_stance;
        
        -- Extract height_feet - handle both JSONB numeric and text
        IF NEW.raw_user_meta_data ? 'height_feet' THEN
            BEGIN
                -- Try to extract as numeric first, then as text
                IF jsonb_typeof(NEW.raw_user_meta_data->'height_feet') = 'number' THEN
                    fighter_height_feet := (NEW.raw_user_meta_data->>'height_feet')::INTEGER;
                ELSE
                    height_feet_str := NEW.raw_user_meta_data->>'height_feet';
                    IF height_feet_str IS NOT NULL AND TRIM(height_feet_str) != '' THEN
                        fighter_height_feet := (height_feet_str)::INTEGER;
                    ELSE
                        RAISE WARNING 'height_feet is empty string, using default 5';
                        fighter_height_feet := 5;
                    END IF;
                END IF;
                RAISE NOTICE 'Height feet extracted: %', fighter_height_feet;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid height_feet: %, using default 5. Error: %', NEW.raw_user_meta_data->'height_feet', SQLERRM;
                fighter_height_feet := 5;
            END;
        ELSE
            RAISE WARNING 'height_feet key not found in metadata, using default 5';
            fighter_height_feet := 5;
        END IF;
        
        -- Extract height_inches - handle both JSONB numeric and text
        IF NEW.raw_user_meta_data ? 'height_inches' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'height_inches') = 'number' THEN
                    fighter_height_inches := (NEW.raw_user_meta_data->>'height_inches')::INTEGER;
                ELSE
                    height_inches_str := NEW.raw_user_meta_data->>'height_inches';
                    IF height_inches_str IS NOT NULL AND TRIM(height_inches_str) != '' THEN
                        fighter_height_inches := (height_inches_str)::INTEGER;
                    ELSE
                        RAISE WARNING 'height_inches is empty string, using default 8';
                        fighter_height_inches := 8;
                    END IF;
                END IF;
                RAISE NOTICE 'Height inches extracted: %', fighter_height_inches;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Invalid height_inches: %, using default 8. Error: %', NEW.raw_user_meta_data->'height_inches', SQLERRM;
                fighter_height_inches := 8;
            END;
        ELSE
            RAISE WARNING 'height_inches key not found in metadata, using default 8';
            fighter_height_inches := 8;
        END IF;
        
        -- Extract reach (registration sends in cm, convert to inches)
        IF NEW.raw_user_meta_data ? 'reach' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'reach') = 'number' THEN
                    reach_str := (NEW.raw_user_meta_data->>'reach');
                ELSE
                    reach_str := NEW.raw_user_meta_data->>'reach';
                END IF;
                
                IF reach_str IS NOT NULL AND TRIM(reach_str) != '' THEN
                    BEGIN
                        -- Registration form converts to cm, so convert back to inches
                        fighter_reach := ROUND((reach_str)::NUMERIC / 2.54)::INTEGER;
                        RAISE NOTICE 'Reach extracted: % cm -> % inches', reach_str, fighter_reach;
                    EXCEPTION WHEN OTHERS THEN
                        RAISE WARNING 'Invalid reach value: %, using default 70. Error: %', reach_str, SQLERRM;
                        fighter_reach := 70;
                    END;
                ELSE
                    RAISE WARNING 'reach is empty string, using default 70';
                    fighter_reach := 70;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error extracting reach: %, using default 70. Error: %', NEW.raw_user_meta_data->'reach', SQLERRM;
                fighter_reach := 70;
            END;
        ELSE
            RAISE WARNING 'reach key not found in metadata, using default 70';
            fighter_reach := 70;
        END IF;
        
        -- Extract weight (registration sends in kg, convert to lbs)
        IF NEW.raw_user_meta_data ? 'weight' THEN
            BEGIN
                IF jsonb_typeof(NEW.raw_user_meta_data->'weight') = 'number' THEN
                    weight_str := (NEW.raw_user_meta_data->>'weight');
                ELSE
                    weight_str := NEW.raw_user_meta_data->>'weight';
                END IF;
                
                IF weight_str IS NOT NULL AND TRIM(weight_str) != '' THEN
                    BEGIN
                        -- Registration form converts to kg, so convert back to lbs
                        fighter_weight := ROUND((weight_str)::NUMERIC / 0.453592)::INTEGER;
                        RAISE NOTICE 'Weight extracted: % kg -> % lbs', weight_str, fighter_weight;
                    EXCEPTION WHEN OTHERS THEN
                        RAISE WARNING 'Invalid weight value: %, using default 150. Error: %', weight_str, SQLERRM;
                        fighter_weight := 150;
                    END;
                ELSE
                    RAISE WARNING 'weight is empty string, using default 150';
                    fighter_weight := 150;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error extracting weight: %, using default 150. Error: %', NEW.raw_user_meta_data->'weight', SQLERRM;
                fighter_weight := 150;
            END;
        ELSE
            RAISE WARNING 'weight key not found in metadata, using default 150';
            fighter_weight := 150;
        END IF;
        
        -- Extract weight class, trainer, gym
        fighter_weight_class := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'weightClass'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'weight_class'), ''),
            'Middleweight'
        );
        RAISE NOTICE 'Weight class: %', fighter_weight_class;
        
        fighter_trainer := NULLIF(TRIM(NEW.raw_user_meta_data->>'trainer'), '');
        RAISE NOTICE 'Trainer: %', fighter_trainer;
        
        fighter_gym := NULLIF(TRIM(NEW.raw_user_meta_data->>'gym'), '');
        RAISE NOTICE 'Gym: %', fighter_gym;
        
        -- Extract platform and timezone
        fighter_platform := NULLIF(TRIM(NEW.raw_user_meta_data->>'platform'), '');
        fighter_timezone := NULLIF(TRIM(NEW.raw_user_meta_data->>'timezone'), '');
        RAISE NOTICE 'Platform: %, Timezone: %', fighter_platform, fighter_timezone;
        
        RAISE NOTICE '=== INSERTING FIGHTER PROFILE ===';
        RAISE NOTICE 'Values: name=%, height=% feet % inches, weight=% lbs, reach=% inches', 
            fighter_name, fighter_height_feet, fighter_height_inches, fighter_weight, fighter_reach;
    
        -- Create fighter profile
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
            'amateur',
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
        
        RAISE NOTICE '=== TRIGGER DEBUG END - PROFILE CREATED ===';
    END IF;
  
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'ERROR in trigger: %', SQLERRM;
        RAISE WARNING 'SQLSTATE: %', SQLSTATE;
        RETURN NEW;
END;
$$;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created_fighter ON auth.users;

CREATE TRIGGER on_auth_user_created_fighter
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_fighter_profile_from_auth();

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_fighter_profile_from_auth() TO postgres, anon, authenticated, service_role;

COMMENT ON FUNCTION public.handle_new_fighter_profile_from_auth() IS 'Creates fighter profile with all physical information from registration. Includes detailed logging to debug data extraction.';

