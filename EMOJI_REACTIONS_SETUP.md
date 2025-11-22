# Emoji Reactions Feature Setup Guide

## Overview
The emoji reactions feature allows fighters to react to News and Announcements posts with 8 different emoji reactions: 👍 Like, 👎 Dislike, ❤️ Love, 😂 Laugh, 😠 Angry, 😢 Sad, 😮 Wow, and 🔥 Fire.

## Database Setup

### Step 1: Run the Database Schema
1. Open your Supabase SQL Editor
2. Copy and paste the contents of `database/news-reactions-schema.sql`
3. Run the SQL script
4. Verify the table was created:
   ```sql
   SELECT * FROM news_reactions LIMIT 1;
   ```

### Step 2: Verify Real-time is Enabled
The schema includes real-time enablement, but verify it's working:
1. Go to Supabase Dashboard → Database → Replication
2. Ensure `news_reactions` table is listed
3. If not, manually enable it or re-run the schema script

## Features

### For Fighters:
- **Quick Reactions**: See top 3 most popular reactions on each post
- **React Button**: Click "React" to see all 8 emoji options
- **Toggle Reactions**: Click the same emoji again to remove your reaction
- **Change Reactions**: Click a different emoji to change your reaction
- **Real-time Updates**: See reactions update live as other fighters react

### Available Reactions:
- 👍 **Like** (Blue) - Show appreciation
- 👎 **Dislike** (Gray) - Express disagreement
- ❤️ **Love** (Pink) - Show love and support
- 😂 **Laugh** (Yellow) - Find it funny
- 😠 **Angry** (Red) - Express anger
- 😢 **Sad** (Purple) - Show sadness
- 😮 **Wow** (Orange) - Express surprise
- 🔥 **Fire** (Orange-Red) - Show it's hot/amazing

## How to Use

1. **Navigate to Home Page** → Click on "News & Announcements" tab
2. **Find a News Post** you want to react to
3. **Click "React" button** (blue button at the bottom of the post)
4. **Choose an emoji** from the popover
5. **Your reaction appears** with a colored border
6. **Click the same emoji again** to remove your reaction
7. **Click a different emoji** to change your reaction

## Troubleshooting

### Reactions Not Showing?
1. **Check Database**: Ensure `news_reactions` table exists
   ```sql
   SELECT * FROM information_schema.tables WHERE table_name = 'news_reactions';
   ```

2. **Check Console**: Open browser console (F12) and look for errors
   - If you see "relation does not exist", run the database schema
   - If you see permission errors, check RLS policies

3. **Check Real-time**: Verify real-time is enabled for `news_reactions` table

### "React" Button Not Visible?
- Make sure you're logged in (button is disabled for guests)
- Check that you're viewing the "News & Announcements" tab
- Refresh the page if the component doesn't load

### Reactions Not Updating in Real-time?
- Check Supabase real-time is enabled
- Check browser console for subscription errors
- Verify your Supabase connection is active

## Testing

1. **As Admin**: Create a News/Announcement post
2. **As Fighter**: 
   - Navigate to Home Page → News & Announcements tab
   - Find the post you created
   - Click "React" button
   - Select an emoji (e.g., 👍 Like)
   - Verify the count appears
   - Click the same emoji again to remove
   - Click a different emoji to change reaction
3. **Real-time Test**:
   - Open the same post in two different browsers/tabs
   - React in one tab
   - Verify the reaction appears in the other tab automatically

## Database Functions

The schema includes two helper functions:
- `get_news_reaction_counts(news_id)` - Returns reaction counts for a news item
- `get_user_news_reaction(news_id, user_id)` - Returns user's reaction for a news item

These are used by the service layer and don't need to be called directly.

