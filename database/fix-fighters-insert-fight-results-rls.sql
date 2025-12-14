-- Fix RLS Policy "Fighters insert fight results" on news_announcements
-- This ensures auth.uid() is evaluated once per query instead of once per row
-- Run this in Supabase SQL Editor

-- Drop the policy if it exists (handle both possible names)
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters insert fight results" ON news_announcements;
    DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Recreate the policy with the exact name mentioned in the issue
-- Using (select auth.uid()) ensures it's evaluated once per query, not once per row
CREATE POLICY "Fighters insert fight results" ON news_announcements
    FOR INSERT WITH CHECK (
        type = 'fight_result' AND
        EXISTS (
            SELECT 1 FROM fighter_profiles
            WHERE user_id = (select auth.uid())
        )
    );

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Fixed "Fighters insert fight results" RLS policy on news_announcements';
    RAISE NOTICE '   - Policy now uses (select auth.uid()) for optimal performance';
    RAISE NOTICE '   - This ensures auth.uid() is evaluated once per query instead of once per row';
END $$;

