-- News Reactions Schema
-- Allows fighters to react to news/announcements with emojis

-- News reactions table
CREATE TABLE IF NOT EXISTS news_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    news_id UUID NOT NULL REFERENCES news_announcements(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('like', 'dislike', 'love', 'laugh', 'angry', 'sad', 'wow', 'fire')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(news_id, user_id, reaction_type) -- One reaction type per user per news item
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_news_reactions_news_id ON news_reactions(news_id);
CREATE INDEX IF NOT EXISTS idx_news_reactions_user_id ON news_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_news_reactions_type ON news_reactions(reaction_type);
CREATE INDEX IF NOT EXISTS idx_news_reactions_news_user ON news_reactions(news_id, user_id);

-- Enable RLS
ALTER TABLE news_reactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (idempotent)
DROP POLICY IF EXISTS "Public read news reactions" ON news_reactions;
DROP POLICY IF EXISTS "Users insert own reactions" ON news_reactions;
DROP POLICY IF EXISTS "Users delete own reactions" ON news_reactions;
DROP POLICY IF EXISTS "Users update own reactions" ON news_reactions;

-- RLS Policies
-- Users can read all reactions (to see counts)
CREATE POLICY "Public read news reactions" ON news_reactions
    FOR SELECT
    USING (true);

-- Users can insert their own reactions
CREATE POLICY "Users insert own reactions" ON news_reactions
    FOR INSERT
    WITH CHECK ((select auth.uid()) = user_id);

-- Users can delete their own reactions
CREATE POLICY "Users delete own reactions" ON news_reactions
    FOR DELETE
    USING ((select auth.uid()) = user_id);

-- Users can update their own reactions (to change reaction type)
CREATE POLICY "Users update own reactions" ON news_reactions
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON news_reactions TO authenticated;
GRANT SELECT ON news_reactions TO anon;

-- Function to get reaction counts for a news item (idempotent - CREATE OR REPLACE)
CREATE OR REPLACE FUNCTION get_news_reaction_counts(p_news_id UUID)
RETURNS TABLE (
    reaction_type VARCHAR(20),
    count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        nr.reaction_type,
        COUNT(*)::BIGINT as count
    FROM news_reactions nr
    WHERE nr.news_id = p_news_id
    GROUP BY nr.reaction_type
    ORDER BY count DESC, nr.reaction_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's reaction for a news item (idempotent - CREATE OR REPLACE)
CREATE OR REPLACE FUNCTION get_user_news_reaction(p_news_id UUID, p_user_id UUID)
RETURNS TABLE (
    reaction_type VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT nr.reaction_type
    FROM news_reactions nr
    WHERE nr.news_id = p_news_id
    AND nr.user_id = p_user_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_news_reaction_counts TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_user_news_reaction TO authenticated, anon;

-- Enable real-time for reactions (idempotent - will skip if already added)
DO $$
BEGIN
    -- Try to add table to realtime publication
    -- This will fail silently if already added, which is fine
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE news_reactions;
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Table news_reactions already in realtime publication';
        WHEN OTHERS THEN
            RAISE NOTICE 'Could not add news_reactions to realtime: %', SQLERRM;
    END;
END $$;

