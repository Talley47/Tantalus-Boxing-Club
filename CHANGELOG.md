# Changelog

All notable changes to Tantalus Boxing Club will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2025-01-XX

### 🎉 Major Features Added

#### Tantalus Ring Magazine Media Feature
- **Social Media Bio**: Fighters can add a custom bio for their media profile
- **Social Media Links**: Add and manage links to Twitter, Instagram, YouTube, Twitch, TikTok, Facebook
- **Shareable Media Page**: Public-facing media profile page at `/media/{user_id}`
- **Media Following Channel**: New sub-channel in Social page to browse fighters with media profiles
- **Location**: My Profile → Physical Information section

### 🔧 Bug Fixes

#### Notification System
- Fixed "New Fighter Joined" notifications navigating to Rankings instead of fighter profile
- Fixed "New Boxing Sanction Available" notifications navigation
- Improved action_url parsing and validation with multiple fallback mechanisms
- Enhanced error handling and logging

#### Performance
- Fixed notification handler performance issues (reduced from 455-460ms to <50ms)
- Added debouncing and batching for notification updates
- Optimized HomePage performance (reduced input delays and render times)
- Fixed news announcements 500 error

### ⚡ Performance Improvements
- Notification handlers: 90% faster processing
- HomePage: Reduced input delays and render times
- News queries: Fixed timeouts and errors
- React rendering: Added memoization and debouncing

### 📊 Technical Updates
- Added `social_media_bio` field to `fighter_profiles` table
- Created `FighterMedia.tsx` component for shareable media profiles
- Added `/media/:userId` route for public media profiles
- Enhanced `NotificationBell.tsx` with better error handling
- Updated `Social.tsx` with Media Following sub-channel
- Added `deleteSocialLink()` function to `mediaService.ts`

### 📁 Files Changed
- New: `src/components/FighterMedia/FighterMedia.tsx`
- New: `database/add-social-media-bio.sql`
- New: `database/fix-news-500-error-diagnostic.sql`
- Updated: `src/components/FighterProfile/FighterProfile.tsx`
- Updated: `src/components/Shared/NotificationBell.tsx`
- Updated: `src/components/HomePage/HomePage.tsx`
- Updated: `src/components/Social/Social.tsx`
- Updated: `src/services/mediaService.ts`
- Updated: `src/App.tsx`

## [1.1.1] - 2025-01-XX

### 🎉 Major Features Added

#### Boxing Sanctions Management System
- Fighters can join Boxing Sanctions and compete for rankings
- 6 available sanctions: TBCA, TBA, TBO, TBF, TBC, TRM
- Independent rankings per sanction
- Multi-sanction participation support

### 🔧 Bug Fixes
- Fixed 409 Conflict Error on championship_belts table
- Corrected points system (Loss: -2 instead of -3)
- Updated demotion system (5 losses instead of 4)

## [1.1.0] - 2025-01-XX

### 🎉 Major Features Added

#### Creative Fighter Image Upload
- **Feature**: Fighters can now upload pictures of their Creative Fighter (CAF)
- **Location**: My Profile → Physical Information section
- **Details**:
  - Upload button in edit mode
  - Image displays on right side of Physical Information when not editing
  - Images appear in Home Page Top 30 Fighters section
  - Images stored in Supabase Storage (`fight-submissions` bucket)
  - File validation: PNG, JPG, GIF, max 10MB
  - Database field: `creative_fighter_image_url` added to `fighter_profiles` table

#### Enhanced Top 30 Fighters Display
- **Redesign**: Complete visual overhaul of League Rankings section
- **3D Effects**: Added perspective transforms and multi-layered shadows
- **Physical Information**: Now displays ALL fighter physical information:
  - Height
  - Weight
  - Reach
  - Stance
  - Hometown
  - Trainer
  - Gym
  - Platform
  - Timezone
  - Birthday
- **Layout**: Improved grid system (max 3 columns) for better readability
- **Visual Enhancements**:
  - 3D card effects with perspective transforms
  - Multi-layered box shadows for depth
  - Enhanced hover animations
  - Improved rank badge styling with 3D effects
  - Creative Fighter images displayed prominently

#### Fight URL and Scorecard Submission
- **Feature**: Fighters can submit both fight URLs and scorecard screenshots
- **Location**: My Profile → Submit Fight URL and Scorecard section
- **Details**:
  - File upload for scorecard images
  - Admin review interface for both URL and scorecard
  - Scorecard thumbnails in submission list
  - Full-size image view in admin review dialog
  - Database field: `scorecard_url` added to `fight_url_submissions` table

### ✨ Enhancements

#### Rules and Guidelines Page
- **Background Image**: Added `AdobeStock_265779582.jpeg` as full-screen background
- **Content Updates**: Added new CAF Policy rules:
  - Attribute Budget Cap
  - All Creative Fighters Overall must be 85
  - No Traits
  - Hard Caps: Max 2 attributes > 90; no stat > 92
  - Body Metrics requirements
  - Cosmetics guidelines
  - Audit requirements
- **Organization**: Sections arranged alphabetically
- **Introduction**: Moved to top of the list
- **Styling**: Semi-transparent overlays for better text readability

#### Real-time Updates System
- **Comprehensive Real-time**: All pages now update in real-time when fighters enter records
- **Affected Pages**:
  - Home Page (Top Fighters, Scheduled Fights)
  - Rankings Page (Overall and Weight Class)
  - Weight Class Rankings
  - Demotion System
  - Tier Progression
  - Analytics (Fighter and Admin)
  - Points System
- **Automatic Updates**: Opponent loss records created automatically when fighter enters a win

#### Points and Demotion System
- **Point System**: Verified and fixed
  - Win = +5 points
  - Loss = -3 points
  - Draw = 0 points
  - KO/TKO Bonus = +3 points
- **Tiebreakers**: Head-to-head → KO% → Strength of Opponent → Recent Form
- **Demotion System**:
  - Automatic demotion after 5 consecutive losses
  - Promotion back after 5 consecutive wins post-demotion
  - Tier Progression: Amateur → Semi-Pro → Pro → Contender → Elite
  - Warning indicators for 3+ consecutive losses
- **Tier Thresholds**:
  - Amateur: 0-29 pts
  - Semi-Pro: 30-69 pts
  - Pro: 70-139 pts
  - Contender: 140-279 pts
  - Elite: 280+ pts

### 🐛 Bug Fixes

#### Notification System
- Fixed notification bell badge count display
- Fixed navigation to News and Announcements from notifications
- Improved notification sound handling
- Fixed `is_read` field usage (replaced deprecated `read` field)

#### Database Performance
- Fixed RLS policy issues causing 403/500 errors
- Simplified RLS policies for better performance
- Added performance indexes
- Fixed `challenger_id` column errors in `callout_requests` table
- Fixed `is_admin` column references (now uses `profiles.role = 'admin'`)
- Resolved statement timeout issues
- Fixed connection pool exhaustion

#### Image Loading
- Fixed Facebook image CORS errors with fallback component
- Improved error handling for external images
- Added `ImageWithFallback` component for blocked images

#### Emoji Reactions
- Fixed duplicate policy errors
- Improved real-time updates for reactions
- Enhanced UI for reaction display

### 🔧 Technical Improvements

#### Database Schema
- Added `creative_fighter_image_url` column to `fighter_profiles`
- Added `scorecard_url` column to `fight_url_submissions`
- Created Supabase Storage bucket for fight submissions
- Improved RLS policies for better security and performance

#### Code Quality
- Improved error handling throughout the application
- Better TypeScript type definitions
- Enhanced component structure and organization
- Improved real-time subscription management

#### Performance
- Client-side caching for admin status checks
- Optimized database queries
- Reduced unnecessary re-renders
- Improved image loading performance

### 📱 Mobile App Updates

#### Notification System
- Enhanced notification badge display
- Improved notification sound playback
- Better navigation handling
- Real-time notification updates

### 🗄️ Database Migrations

New migration scripts added:
- `add-creative-fighter-image.sql` - Adds Creative Fighter image URL field
- `add-scorecard-to-fight-url-submissions.sql` - Adds scorecard URL field
- `setup-scorecard-storage.sql` - Sets up Supabase Storage bucket
- Various RLS policy fixes and optimizations

### 📝 Documentation

- Created `CREATIVE-FIGHTER-IMAGE-FEATURE.md`
- Updated database schema documentation
- Enhanced inline code comments

---

## [1.0.0] - Previous Release

### Initial Release Features
- User authentication and registration
- Fighter profile management
- Fight record tracking
- Rankings system
- Matchmaking
- Tournament system
- News and announcements
- Admin panel
- Mobile app support

---

## Version History

- **1.1.0** - Current version with Creative Fighter images, enhanced rankings, and comprehensive updates
- **1.0.0** - Initial release

