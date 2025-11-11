-- Fix RLS Policies for tournament_participants table
-- This fixes the issue where users cannot join tournaments due to RLS policy violations

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters read own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters join tournaments" ON tournament_participants;
    DROP POLICY IF EXISTS "Users can view own tournament participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Users can join tournaments" ON tournament_participants;
    DROP POLICY IF EXISTS "Users can update own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Tournament creators and admins can manage participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Tournament creators can manage participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Public read tournament participants" ON tournament_participants;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Ensure RLS is enabled
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- Public read access for tournament participants (so users can see who's participating)
-- This also fixes the 406 error when checking if user is already participating
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'tournament_participants' 
        AND policyname = 'Public read tournament participants'
    ) THEN
        EXECUTE 'CREATE POLICY "Public read tournament participants" ON tournament_participants
            FOR SELECT USING (true)';
        RAISE NOTICE 'Created Public read tournament participants policy';
    ELSE
        RAISE NOTICE 'Public read tournament participants policy already exists';
    END IF;
END $$;

-- Users can join tournaments (insert their own participation)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'tournament_participants' 
        AND policyname = 'Users can join tournaments'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can join tournaments" ON tournament_participants
            FOR INSERT WITH CHECK (
                fighter_id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
            )';
        RAISE NOTICE 'Created Users can join tournaments policy';
    ELSE
        RAISE NOTICE 'Users can join tournaments policy already exists';
    END IF;
END $$;

-- Users can update their own participations (e.g., check in)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'tournament_participants' 
        AND policyname = 'Users can update own participations'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can update own participations" ON tournament_participants
            FOR UPDATE USING (
                fighter_id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
            )';
        RAISE NOTICE 'Created Users can update own participations policy';
    ELSE
        RAISE NOTICE 'Users can update own participations policy already exists';
    END IF;
END $$;

-- Tournament creators and admins can manage all participants
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'tournament_participants' 
        AND policyname = 'Tournament creators and admins can manage participants'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'is_admin_user' 
            AND pronamespace = 'public'::regnamespace
        ) THEN
            -- Use is_admin_user function
            EXECUTE 'CREATE POLICY "Tournament creators and admins can manage participants" ON tournament_participants
                FOR ALL USING (
                    EXISTS (
                        SELECT 1 FROM tournaments 
                        WHERE id = tournament_id AND created_by = auth.uid()
                    ) OR is_admin_user()
                )';
            RAISE NOTICE 'Created Tournament creators and admins can manage participants policy using is_admin_user()';
        ELSE
            -- Fallback: check profiles table
            EXECUTE 'CREATE POLICY "Tournament creators and admins can manage participants" ON tournament_participants
                FOR ALL USING (
                    EXISTS (
                        SELECT 1 FROM tournaments 
                        WHERE id = tournament_id AND created_by = auth.uid()
                    ) OR EXISTS (
                        SELECT 1 FROM profiles 
                        WHERE id = auth.uid() AND role = ' || quote_literal('admin') || '
                    )
                )';
            RAISE NOTICE 'Created Tournament creators and admins can manage participants policy using profiles table';
        END IF;
    ELSE
        RAISE NOTICE 'Tournament creators and admins can manage participants policy already exists';
    END IF;
END $$;

