-- Fix RLS Policies for dispute_messages table
-- This fixes the issue where fighters and admins cannot insert messages due to RLS policy failures

-- Drop all existing policies
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin can view all dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Fighters can view their dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Admin can insert dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Fighters can insert their dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Admin can update dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Fighters can update their dispute messages" ON dispute_messages;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Ensure RLS is enabled
ALTER TABLE dispute_messages ENABLE ROW LEVEL SECURITY;

-- Admin can view all messages
-- Use is_admin_user() function if available, otherwise check profiles table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admin can view all dispute messages" ON dispute_messages
            FOR SELECT USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admin can view all dispute messages" ON dispute_messages
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = ' || quote_literal('admin') || '
                )
            )';
    END IF;
END $$;

-- Fighters can view messages for their disputes
-- Simplified check: if they are the disputer or opponent in the dispute
CREATE POLICY "Fighters can view their dispute messages" ON dispute_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM disputes d
            JOIN fighter_profiles fp_disputer ON fp_disputer.id = d.disputer_id
            LEFT JOIN fighter_profiles fp_opponent ON fp_opponent.id = d.opponent_id
            WHERE d.id = dispute_messages.dispute_id
            AND (
                fp_disputer.user_id = auth.uid()
                OR (fp_opponent.id IS NOT NULL AND fp_opponent.user_id = auth.uid())
            )
        )
    );

-- Admin can insert messages
-- Use is_admin_user() function if available, otherwise check profiles table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admin can insert dispute messages" ON dispute_messages
            FOR INSERT WITH CHECK (
                is_admin_user()
                AND sender_type = ' || quote_literal('admin') || '
                AND sender_id = auth.uid()
            )';
    ELSE
        EXECUTE 'CREATE POLICY "Admin can insert dispute messages" ON dispute_messages
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = ' || quote_literal('admin') || '
                )
                AND sender_type = ' || quote_literal('admin') || '
                AND sender_id = auth.uid()
            )';
    END IF;
END $$;

-- Fighters can insert messages for their disputes
-- Simplified: check if dispute exists and user is part of it
CREATE POLICY "Fighters can insert their dispute messages" ON dispute_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM disputes d
            JOIN fighter_profiles fp_disputer ON fp_disputer.id = d.disputer_id
            LEFT JOIN fighter_profiles fp_opponent ON fp_opponent.id = d.opponent_id
            WHERE d.id = dispute_messages.dispute_id
            AND (
                fp_disputer.user_id = auth.uid()
                OR (fp_opponent.id IS NOT NULL AND fp_opponent.user_id = auth.uid())
            )
        )
        AND sender_type = 'fighter'
        AND sender_id = auth.uid()
    );

-- Admin can update messages (mark as read, etc.)
-- Use is_admin_user() function if available, otherwise check profiles table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admin can update dispute messages" ON dispute_messages
            FOR UPDATE USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admin can update dispute messages" ON dispute_messages
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = ' || quote_literal('admin') || '
                )
            )';
    END IF;
END $$;

-- Fighters can update their own messages (mark as read, etc.)
CREATE POLICY "Fighters can update their dispute messages" ON dispute_messages
    FOR UPDATE USING (
        sender_id = auth.uid()
        AND sender_type = 'fighter'
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON dispute_messages TO authenticated;
GRANT SELECT ON dispute_messages TO anon;

-- Add helpful comments
COMMENT ON POLICY "Admin can view all dispute messages" ON dispute_messages IS 
    'Allows admins to view all messages in all disputes';

COMMENT ON POLICY "Fighters can view their dispute messages" ON dispute_messages IS 
    'Allows fighters to view messages in disputes where they are the disputer or opponent';

COMMENT ON POLICY "Admin can insert dispute messages" ON dispute_messages IS 
    'Allows admins to send messages in any dispute';

COMMENT ON POLICY "Fighters can insert their dispute messages" ON dispute_messages IS 
    'Allows fighters to send messages in disputes where they are involved';

COMMENT ON POLICY "Admin can update dispute messages" ON dispute_messages IS 
    'Allows admins to update any message (e.g., mark as read)';

COMMENT ON POLICY "Fighters can update their dispute messages" ON dispute_messages IS 
    'Allows fighters to update their own messages (e.g., mark as read)';

DO $$ BEGIN RAISE NOTICE '✅ Dispute messages RLS policies fixed.'; END $$;

