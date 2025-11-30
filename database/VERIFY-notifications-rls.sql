-- VERIFY: Check if notifications RLS policies are correct
-- Run this in Supabase SQL Editor to verify the fix worked

SELECT 
    policyname,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'notifications'
ORDER BY cmd, policyname;

-- Expected output:
-- You should see an INSERT policy named "Authenticated users can create notifications"
-- with with_check_expression containing "auth.role() = 'authenticated'"

