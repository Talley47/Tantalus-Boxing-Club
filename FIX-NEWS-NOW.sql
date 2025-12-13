-- FIX NEWS NOT SHOWING - Run in Supabase SQL Editor
-- Copy and paste each section ONE AT A TIME

-- ============================================
-- STEP 1: Create Function (Run this first)
-- ============================================
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid()
        AND (email = 'tantalusboxingclub@gmail.com' OR email LIKE '%@admin.tantalus%')
    );
END;
$$;

-- ============================================
-- STEP 2: Grant Permissions (Run this second)
-- ============================================
GRANT EXECUTE ON FUNCTION is_admin_user() TO authenticated, anon;

-- ============================================
-- STEP 3: Drop Old Policies (Run this third)
-- ============================================
DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;

-- ============================================
-- STEP 4: Create Public Policy (Run this fourth)
-- ============================================
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT USING (is_published = TRUE);

-- ============================================
-- STEP 5: Create Admin Policy (Run this fifth)
-- ============================================
CREATE POLICY "Admin manage news" ON news_announcements
    FOR ALL
    USING (is_admin_user())
    WITH CHECK (is_admin_user());










