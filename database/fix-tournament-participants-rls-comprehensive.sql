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
    DROP POLICY IF EXISTS "Fighters and admins can update participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Tournament creators and admins can manage participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Tournament creators can manage participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Admins can manage all participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Public read tournament participants" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters can view own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Authenticated and admins can view participants" ON tournament_participants;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 1. Public read access for tournament participants (so users can see who's participating)
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read tournament participants" ON tournament_participants
    FOR SELECT TO anon
    USING (true);

-- 2. Combined INSERT policy: Fighters can join tournaments OR tournament creators can insert OR admins can insert
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Fighters and creators and admins can insert participants" ON tournament_participants;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Fighters and creators and admins can insert participants" ON tournament_participants
            FOR INSERT TO authenticated
            WITH CHECK (
                fighter_id IN (
                    SELECT id FROM fighter_profiles 
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR is_admin_user()
            )';
    ELSE
        EXECUTE 'CREATE POLICY "Fighters and creators and admins can insert participants" ON tournament_participants
            FOR INSERT TO authenticated
            WITH CHECK (
                fighter_id IN (
                    SELECT id FROM fighter_profiles 
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Note: "Fighters can view own participations" policy has been merged into "Authenticated and admins can view participants"
-- This avoids multiple permissive policies for the same role and action

-- 4. Fighters can update their own participations (e.g., check in)
-- Combined UPDATE policy: Fighters can update their own participations OR tournament creators can update their tournament's participants OR admins can update any
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Fighters and admins can update participations" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament creators and admins can update participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admins can update participants" ON tournament_participants;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Combined UPDATE policy: Fighters can update their own participations OR tournament creators can update their tournament's participants OR admins can update any
        EXECUTE 'CREATE POLICY "Fighters and admins can update participations" ON tournament_participants
            FOR UPDATE TO authenticated
            USING (
                fighter_id IN (
                    SELECT id FROM fighter_profiles 
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR is_admin_user()
            )';
    ELSE
        -- Combined UPDATE policy: Fighters can update their own participations OR tournament creators can update their tournament's participants OR admins can update any
        EXECUTE 'CREATE POLICY "Fighters and admins can update participations" ON tournament_participants
            FOR UPDATE TO authenticated
            USING (
                fighter_id IN (
                    SELECT id FROM fighter_profiles 
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 5. Admins can manage all participants (INSERT, UPDATE, DELETE only - SELECT is handled by combined policy below)
-- PostgreSQL doesn't support FOR INSERT, UPDATE, DELETE, so we create separate policies
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Admins can manage all participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admins can insert participants" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament creators and admins can insert participants" ON tournament_participants;
-- Note: "Admins can update participants" UPDATE policy removed - handled by "Fighters and admins can update participations"
DROP POLICY IF EXISTS "Admins can delete participants" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament creators and admins can delete participants" ON tournament_participants;
DROP POLICY IF EXISTS "Authenticated and admins can view participants" ON tournament_participants;

-- Combined SELECT policy: Fighters can view their own participations OR tournament creators can view their tournament's participants OR admins can view all
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Tournament creators and admins can view participants" ON tournament_participants;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Combined SELECT policy: Fighters can view their own participations OR tournament creators can view their tournament's participants OR admins can view all
        EXECUTE 'CREATE POLICY "Authenticated and admins can view participants" ON tournament_participants
            FOR SELECT TO authenticated
            USING (
                fighter_id IN (
                    SELECT id FROM fighter_profiles 
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR is_admin_user()
            )';
    ELSE
        -- Combined SELECT policy: Fighters can view their own participations OR tournament creators can view their tournament's participants OR admins can view all
        EXECUTE 'CREATE POLICY "Authenticated and admins can view participants" ON tournament_participants
            FOR SELECT TO authenticated
            USING (
                fighter_id IN (
                    SELECT id FROM fighter_profiles 
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Admin policies for INSERT, UPDATE, DELETE (SELECT is handled by combined policy above)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Note: INSERT is handled by "Fighters and creators and admins can insert participants" policy above
        
        -- Note: UPDATE is handled by "Fighters and admins can update participations" policy above
        
        -- Combined DELETE policy: Tournament creators OR admins can delete participants
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Tournament creators and admins can delete participants" ON tournament_participants
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR is_admin_user()
            )';
    ELSE
        -- Note: INSERT is handled by "Fighters and creators and admins can insert participants" policy above
        
        -- Note: UPDATE is handled by "Fighters and admins can update participations" policy above
        
        -- Combined DELETE policy: Tournament creators OR admins can delete participants
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Tournament creators and admins can delete participants" ON tournament_participants
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM tournaments 
                    WHERE id = tournament_id AND created_by = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
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
    'Allows anonymous users to view tournament participants. Restricted to anon only to avoid multiple permissive policies.';
COMMENT ON POLICY "Fighters and creators and admins can insert participants" ON tournament_participants IS 
    'Allows fighters to join tournaments, tournament creators to insert participants for their tournaments, or admins to insert any. Combined policy to avoid multiple permissive policies.';
COMMENT ON POLICY "Authenticated and admins can view participants" ON tournament_participants IS 
    'Allows fighters to view their own tournament participations, tournament creators to view participants for their tournaments, or admins to view all. Combined policy to avoid multiple permissive policies.';
COMMENT ON POLICY "Fighters and admins can update participations" ON tournament_participants IS 
    'Allows fighters to update their own participations, tournament creators to update participants for their tournaments, or admins to update any. Combined policy to avoid multiple permissive policies.';
-- Note: "Admins can insert participants" policy has been merged into "Fighters and creators and admins can insert participants"
-- Note: "Admins can update participants" policy has been merged into "Fighters and admins can update participations"
COMMENT ON POLICY "Tournament creators and admins can delete participants" ON tournament_participants IS 
    'Allows tournament creators to delete participants from their tournaments or admins to delete any. Combined policy to avoid multiple permissive policies.';

