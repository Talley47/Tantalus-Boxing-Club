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
CREATE POLICY "Anyone can view scheduled fights" ON scheduled_fights
  FOR SELECT USING (true);

-- Only admins can insert/update/delete scheduled fights
CREATE POLICY "Only admins can manage scheduled fights" ON scheduled_fights
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 4. RLS Policies for news_announcements
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read news and announcements
CREATE POLICY "Anyone can view news and announcements" ON news_announcements
  FOR SELECT USING (true);

-- Only admins can insert/update/delete news and announcements
CREATE POLICY "Only admins can manage news and announcements" ON news_announcements
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 5. RLS Policies for fighter_profiles (for public rankings)
-- Make sure fighter_profiles table has RLS enabled
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read fighter profiles (for rankings, leaderboards, etc.)
DROP POLICY IF EXISTS "Anyone can view fighter profiles" ON fighter_profiles;
CREATE POLICY "Anyone can view fighter profiles" ON fighter_profiles
  FOR SELECT USING (true);

-- Users can only update their own fighter profile
DROP POLICY IF EXISTS "Users can update own fighter profile" ON fighter_profiles;
CREATE POLICY "Users can update own fighter profile" ON fighter_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own fighter profile
DROP POLICY IF EXISTS "Users can insert own fighter profile" ON fighter_profiles;
CREATE POLICY "Users can insert own fighter profile" ON fighter_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_date ON scheduled_fights(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_status ON scheduled_fights(status);
CREATE INDEX IF NOT EXISTS idx_news_announcements_created_at ON news_announcements(created_at);
CREATE INDEX IF NOT EXISTS idx_news_announcements_type ON news_announcements(type);
CREATE INDEX IF NOT EXISTS idx_news_announcements_priority ON news_announcements(priority);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_points ON fighter_profiles(points DESC);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_user_id ON fighter_profiles(user_id);
