-- Comprehensive Fix for tournament_participants RLS Policies
-- This ensures fighters can join tournaments properly
-- Run this in Supabase SQL Editor

-- Enable RLS on tournament_participants table if not already enabled
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to avoid conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters read own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters join tournaments" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters can join tournaments" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters can view own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters can update own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Users can view own tournament participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Users can join tournaments" ON tournament_participants;
    DROP POLICY IF EXISTS "Users can update own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Tournament creators and admins can manage participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Tournament creators can manage participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Admins can manage all participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Public read tournament participants" ON tournament_participants;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 1. Public read access for tournament participants (so users can see who's participating)
CREATE POLICY "Public read tournament participants" ON tournament_participants
    FOR SELECT USING (true);

-- 2. Fighters can join tournaments (insert their own participation)
-- This is the critical policy that was failing
CREATE POLICY "Fighters can join tournaments" ON tournament_participants
    FOR INSERT WITH CHECK (
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 3. Fighters can view their own tournament participations
CREATE POLICY "Fighters can view own participations" ON tournament_participants
    FOR SELECT USING (
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 4. Fighters can update their own participations (e.g., check in)
CREATE POLICY "Fighters can update own participations" ON tournament_participants
    FOR UPDATE USING (
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 5. Admins can manage all participants
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can manage all participants" ON tournament_participants
            FOR ALL USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can manage all participants" ON tournament_participants
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON tournament_participants TO authenticated;

-- Verify all policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'tournament_participants';
    
    RAISE NOTICE '✅ Total policies created: %', policy_count;
    
    IF policy_count >= 5 THEN
        RAISE NOTICE '✅ All RLS policies for tournament_participants created successfully!';
    ELSE
        RAISE WARNING '⚠️ Expected 5 policies but found %. Please check policy creation.', policy_count;
    END IF;
END $$;

-- Add helpful comments
COMMENT ON POLICY "Public read tournament participants" ON tournament_participants IS 
    'Allows anyone to view tournament participants';
COMMENT ON POLICY "Fighters can join tournaments" ON tournament_participants IS 
    'Allows fighters to join tournaments. Checks that fighter_id matches a fighter profile owned by auth.uid().';
COMMENT ON POLICY "Fighters can view own participations" ON tournament_participants IS 
    'Allows fighters to view their own tournament participations';
COMMENT ON POLICY "Fighters can update own participations" ON tournament_participants IS 
    'Allows fighters to update their own participations (e.g., check in)';
COMMENT ON POLICY "Admins can manage all participants" ON tournament_participants IS 
    'Allows admins to manage all tournament participants';

