-- Database tables for the redesigned HomePage
-- Run this SQL in your Supabase SQL Editor

-- 1. Scheduled Fights Table
CREATE TABLE IF NOT EXISTS scheduled_fights (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter1_id UUID REFERENCES fighter_profiles(user_id) ON DELETE CASCADE,
  fighter2_id UUID REFERENCES fighter_profiles(user_id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME NOT NULL,
  timezone VARCHAR(50) DEFAULT 'UTC',
  venue VARCHAR(255) NOT NULL,
  weight_class VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. News and Announcements Table
CREATE TABLE IF NOT EXISTS news_announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  author VARCHAR(100) NOT NULL,
  type VARCHAR(20) DEFAULT 'news' CHECK (type IN ('news', 'announcement')),
  priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. RLS Policies for scheduled_fights
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read scheduled fights
-- Drop old policies that cause conflicts
DROP POLICY IF EXISTS "Anyone can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Only admins can manage scheduled fights" ON scheduled_fights;

-- Note: Public read access is handled by "Public can view scheduled fights" policy (restricted TO anon)
-- Note: Authenticated read access should be handled by "Authenticated can view scheduled fights" policy (restricted TO authenticated)

-- Only admins can update/delete scheduled fights (restricted to authenticated to avoid conflicts with anon SELECT policies)
-- Note: INSERT is handled by "Fighters and admins can create scheduled fights" policy (created in other files)
-- This avoids multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Admin insert scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Admin update scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Admin delete scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Admins can delete scheduled fights" ON scheduled_fights;

DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin_user') THEN
        -- Admin can update scheduled fights
        EXECUTE 'CREATE POLICY "Admin update scheduled fights" ON scheduled_fights
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        -- Admin can delete scheduled fights (using consistent naming)
        EXECUTE 'CREATE POLICY "Admins can delete scheduled fights" ON scheduled_fights
            FOR DELETE TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback if is_admin_user doesn't exist
        EXECUTE 'CREATE POLICY "Admin update scheduled fights" ON scheduled_fights
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admins can delete scheduled fights" ON scheduled_fights
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
    END IF;
END $$;

-- 4. RLS Policies for news_announcements
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read news and announcements
-- Drop old policies that cause conflicts
DROP POLICY IF EXISTS "Anyone can view news and announcements" ON news_announcements;
DROP POLICY IF EXISTS "Only admins can manage news and announcements" ON news_announcements;

-- Note: Public read access is handled by "Public read published news" policy (restricted TO anon)
-- Note: Authenticated read access should be handled by "Authenticated and admins can read news" policy (restricted TO authenticated)

-- Only admins can update/delete news and announcements (restricted to authenticated to avoid conflicts with anon SELECT policies)
-- Note: INSERT is handled by "Authenticated and admins can insert news" policy (created in other files)
-- This avoids multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Admin insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;

DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin_user') THEN
        -- Admin can update news
        EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        -- Admin can delete news
        EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
            FOR DELETE TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback if is_admin_user doesn't exist
        EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
    END IF;
END $$;

-- 5. RLS Policies for fighter_profiles (for public rankings)
-- Make sure fighter_profiles table has RLS enabled
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read fighter profiles (for rankings, leaderboards, etc.)
-- Drop duplicate policies
DROP POLICY IF EXISTS "Anyone can view fighter profiles" ON fighter_profiles;
DROP POLICY IF EXISTS "Public can view all fighter profiles" ON fighter_profiles;

-- Public can view all fighter profiles - restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public can view all fighter profiles" ON fighter_profiles
  FOR SELECT TO anon
  USING (true);

-- Users can only update their own fighter profile
DROP POLICY IF EXISTS "Users can update own fighter profile" ON fighter_profiles;
CREATE POLICY "Users can update own fighter profile" ON fighter_profiles
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- Users can insert their own fighter profile
-- Use combined policy to avoid multiple permissive policies
DROP POLICY IF EXISTS "Users can insert own fighter profile" ON fighter_profiles;
DROP POLICY IF EXISTS "Users and admins can insert fighter profiles" ON fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                (select auth.uid()) = user_id 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                (select auth.uid()) = user_id 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 6. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_date ON scheduled_fights(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_status ON scheduled_fights(status);
CREATE INDEX IF NOT EXISTS idx_news_announcements_created_at ON news_announcements(created_at);
-- Drop duplicate index if it exists (idx_news_type is duplicate of idx_news_announcements_type)
DROP INDEX IF EXISTS idx_news_type;

-- Create index with consistent naming (idx_news_announcements_type)
CREATE INDEX IF NOT EXISTS idx_news_announcements_type ON news_announcements(type);
CREATE INDEX IF NOT EXISTS idx_news_announcements_priority ON news_announcements(priority);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_points ON fighter_profiles(points DESC);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_user_id ON fighter_profiles(user_id);
