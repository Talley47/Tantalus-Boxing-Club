-- Fix notifications INSERT RLS policy
-- This allows users to create notifications for other users (e.g., system notifications)

-- Drop existing INSERT policy if it exists
DROP POLICY IF EXISTS "Users can insert notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
DROP POLICY IF EXISTS "Admins can insert notifications" ON notifications;

-- Allow authenticated users to insert notifications
-- This is needed for system notifications (training camp invitations, callouts, etc.)
-- Note: This policy allows any authenticated user to create notifications for any user
-- This is necessary for the system to send notifications when users interact (callouts, invitations, etc.)
CREATE POLICY "Users can insert notifications" ON notifications
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Also ensure admins can insert notifications
CREATE POLICY "Admins can insert notifications" ON notifications
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

