-- News & Announcements Schema for TBC Promotions
-- Supports News, Announcements, Blogs with unlimited text and images

-- News and Announcements table
CREATE TABLE IF NOT EXISTS news_announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL, -- Unlimited text support
    author VARCHAR(100) NOT NULL DEFAULT 'Mike Glove',
    author_title VARCHAR(100) DEFAULT 'TBC News Reporter',
    type VARCHAR(20) NOT NULL CHECK (type IN ('news', 'announcement', 'blog', 'fight_result')),
    priority VARCHAR(10) DEFAULT 'low' CHECK (priority IN ('high', 'medium', 'low')),
    images JSONB DEFAULT '[]', -- Array of image URLs/paths
    featured_image TEXT, -- Main featured image URL
    tags TEXT[], -- Array of tags for categorization
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fight results for news posts
CREATE TABLE IF NOT EXISTS news_fight_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    news_id UUID REFERENCES news_announcements(id) ON DELETE CASCADE,
    fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL,
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    result_method VARCHAR(50), -- KO, Decision, etc.
    round INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_news_announcements_type ON news_announcements(type);
CREATE INDEX IF NOT EXISTS idx_news_announcements_published ON news_announcements(is_published, published_at);
CREATE INDEX IF NOT EXISTS idx_news_announcements_featured ON news_announcements(is_featured);
-- Drop duplicate indexes if they exist
DROP INDEX IF EXISTS idx_news_announcements_created;
DROP INDEX IF EXISTS idx_news_created_at;

-- Create index with consistent naming (idx_news_announcements_created_at)
CREATE INDEX IF NOT EXISTS idx_news_announcements_created_at ON news_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_fight_results_news ON news_fight_results(news_id);

-- RLS Policies
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_fight_results ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
    DROP POLICY IF EXISTS "Public read fight results" ON news_fight_results;
    DROP POLICY IF EXISTS "Admin manage fight results" ON news_fight_results;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Public read access for published news
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT TO anon
    USING (is_published = TRUE);

-- Admin write access for news (UPDATE and DELETE only - INSERT is handled by combined policy, SELECT by separate policy)
-- Split into separate policies to avoid multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;

CREATE POLICY "Admin update news" ON news_announcements
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM fighter_profiles fp
            JOIN auth.users u ON fp.user_id = u.id
            WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()) LIMIT 1)
            AND u.email LIKE '%@admin.tantalus%'
        )
    );

CREATE POLICY "Admin delete news" ON news_announcements
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM fighter_profiles fp
            JOIN auth.users u ON fp.user_id = u.id
            WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()) LIMIT 1)
            AND u.email LIKE '%@admin.tantalus%'
        )
    );

-- Public read access for fight results
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read fight results" ON news_fight_results
    FOR SELECT TO anon
    USING (true);

-- Combined INSERT policy: Fighters can insert fight results data OR admins can insert any
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Fighters can insert fight results data" ON news_fight_results;
DROP POLICY IF EXISTS "Fighters and admins can insert fight results data" ON news_fight_results;
DROP POLICY IF EXISTS "Admin can view fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Authenticated can read fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Admin can update fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Admin can delete fight results" ON news_fight_results;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Combined INSERT policy
        EXECUTE 'CREATE POLICY "Fighters and admins can insert fight results data" ON news_fight_results
            FOR INSERT TO authenticated
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM fighter_profiles
                    WHERE user_id = (select auth.uid())
                )
                OR is_admin_user()
            )';
        
        -- Admin policies for SELECT, UPDATE, DELETE
        -- Combined SELECT policy: All authenticated users can read fight results (admins have additional privileges via other policies)
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Authenticated can read fight results" ON news_fight_results
            FOR SELECT TO authenticated
            USING (true)';
        
        EXECUTE 'CREATE POLICY "Admin can update fight results" ON news_fight_results
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admin can delete fight results" ON news_fight_results
            FOR DELETE TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table and email for admin role
        EXECUTE 'CREATE POLICY "Fighters and admins can insert fight results data" ON news_fight_results
            FOR INSERT TO authenticated
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM fighter_profiles
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM fighter_profiles fp
                    JOIN auth.users u ON fp.user_id = u.id
                    WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()) LIMIT 1)
                    AND u.email LIKE ''%@admin.tantalus%''
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        
        -- Combined SELECT policy: All authenticated users can read fight results (admins have additional privileges via other policies)
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Authenticated can read fight results" ON news_fight_results
            FOR SELECT TO authenticated
            USING (true)';
        
        EXECUTE 'CREATE POLICY "Admin can update fight results" ON news_fight_results
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM fighter_profiles fp
                    JOIN auth.users u ON fp.user_id = u.id
                    WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()) LIMIT 1)
                    AND u.email LIKE ''%@admin.tantalus%''
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin can delete fight results" ON news_fight_results
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM fighter_profiles fp
                    JOIN auth.users u ON fp.user_id = u.id
                    WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()) LIMIT 1)
                    AND u.email LIKE ''%@admin.tantalus%''
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_news_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_news_updated_at_trigger ON news_announcements;
CREATE TRIGGER update_news_updated_at_trigger
    BEFORE UPDATE ON news_announcements
    FOR EACH ROW
    EXECUTE FUNCTION update_news_updated_at();

-- Function to auto-publish when created (if not specified)
CREATE OR REPLACE FUNCTION set_news_published_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.published_at IS NULL AND NEW.is_published = TRUE THEN
        NEW.published_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-set published_at
DROP TRIGGER IF EXISTS set_news_published_at_trigger ON news_announcements;
CREATE TRIGGER set_news_published_at_trigger
    BEFORE INSERT ON news_announcements
    FOR EACH ROW
    EXECUTE FUNCTION set_news_published_at();

