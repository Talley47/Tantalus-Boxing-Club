-- Add platform column to fighter_profiles table if it doesn't exist
-- This migration ensures the platform field is available for all fighters

-- Check if the column exists and add it if not
DO $$
BEGIN
    -- Check if platform column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles' 
        AND column_name = 'platform'
    ) THEN
        -- Add the platform column
        ALTER TABLE public.fighter_profiles
        ADD COLUMN platform VARCHAR(10) NOT NULL DEFAULT 'PC'
        CHECK (platform IN ('PSN', 'Xbox', 'PC'));
        
        RAISE NOTICE 'Added platform column to fighter_profiles table';
    ELSE
        RAISE NOTICE 'Platform column already exists in fighter_profiles table';
    END IF;
    
    -- Check if platform_id column exists (required by schema)
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles' 
        AND column_name = 'platform_id'
    ) THEN
        -- Add the platform_id column
        ALTER TABLE public.fighter_profiles
        ADD COLUMN platform_id VARCHAR(50) NOT NULL DEFAULT 'unknown';
        
        RAISE NOTICE 'Added platform_id column to fighter_profiles table';
    ELSE
        RAISE NOTICE 'Platform_id column already exists in fighter_profiles table';
    END IF;
    
    -- Check if timezone column exists (required by schema)
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles' 
        AND column_name = 'timezone'
    ) THEN
        -- Add the timezone column
        ALTER TABLE public.fighter_profiles
        ADD COLUMN timezone VARCHAR(50) NOT NULL DEFAULT 'UTC';
        
        RAISE NOTICE 'Added timezone column to fighter_profiles table';
    ELSE
        RAISE NOTICE 'Timezone column already exists in fighter_profiles table';
    END IF;
    
    -- Update existing records to have valid platform values
    UPDATE public.fighter_profiles
    SET platform = CASE
        WHEN platform IS NULL OR platform NOT IN ('PSN', 'Xbox', 'PC') THEN 'PC'
        ELSE platform
    END
    WHERE platform IS NULL OR platform NOT IN ('PSN', 'Xbox', 'PC');
    
    -- Update platform_id for existing records if it's null
    UPDATE public.fighter_profiles
    SET platform_id = user_id::TEXT
    WHERE platform_id IS NULL OR platform_id = 'unknown';
    
    -- Update timezone for existing records if it's null
    UPDATE public.fighter_profiles
    SET timezone = 'UTC'
    WHERE timezone IS NULL;
    
    RAISE NOTICE 'Updated existing fighter profiles with default platform values';
END $$;

-- Verify the constraint exists
DO $$
BEGIN
    -- Check if the platform constraint exists
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conrelid = 'public.fighter_profiles'::regclass 
        AND conname LIKE '%platform%check%'
        AND contype = 'c'
    ) THEN
        -- Try to add the constraint if it doesn't exist
        BEGIN
            ALTER TABLE public.fighter_profiles
            ADD CONSTRAINT fighter_profiles_platform_check 
            CHECK (platform IN ('PSN', 'Xbox', 'PC'));
            
            RAISE NOTICE 'Added platform check constraint';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Platform constraint already exists';
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not add platform constraint: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Platform constraint already exists';
    END IF;
END $$;

COMMENT ON COLUMN public.fighter_profiles.platform IS 'Gaming platform: PSN (PlayStation), Xbox, or PC (Steam/PC)';
COMMENT ON COLUMN public.fighter_profiles.platform_id IS 'Platform-specific user ID (e.g., PSN username, Xbox gamertag, Steam ID)';

