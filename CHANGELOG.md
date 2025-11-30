# Changelog

All notable changes to Tantalus Boxing Club will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.3] - 2025-01-XX

### 🎉 Major Features Added

#### Admin Direct Messages System
- **Feature**: Admins can send direct messages to fighters to notify them of event selections
- **Location**: Admin Panel → System Settings → Admin Direct Messages
- **Details**:
  - Send single or bulk messages to selected fighters
  - Message types: Event Selection, General Announcement, Tournament Invitation
  - Event name field (free text) for event-specific notifications
  - Read/unread status tracking
  - Message history with delete functionality
  - Messages appear in fighter's "My Profile" → "Messages from TBC Promotions" section

#### Fighter-to-Fighter Direct Messaging
- **Feature**: Fighters can send personal direct messages to each other
- **Location**: My Profile → Messages section
- **Details**:
  - Conversation-based messaging system
  - Real-time message updates
  - Unread message indicators
  - Auto-scrolling to latest messages
  - Start new conversations with any fighter
  - View conversation history
  - Delete messages functionality

#### @Mention Notifications in Club Chat
- **Feature**: Fighters receive notifications when mentioned in Club Chat
- **Location**: Social page → Club Chat
- **Details**:
  - Mention fighters using @username or @fighter_name
  - Automatic notification sent to mentioned fighters
  - Notification includes message preview and link to the message
  - Real-time notification delivery

#### Enhanced Profile Page Organization
- **Feature**: Complete reorganization of My Profile page for better usability
- **Location**: My Profile page
- **Details**:
  - Organized into 6 clear sections with yellow headers:
    1. **TBCREC** (formerly Overview) - Fighter statistics and overview
    2. **Fighter Information** (formerly Profile Information) - Personal details, physical info, social media
    3. **Training & Matchmaking** - Training camps, matchmaking, mandatory fight requests
    4. **Resume** (formerly Fighting) - Fight records, fight URL submissions, scheduled fights
    5. **Submissions & Disputes** - Dispute resolution, fight URL submissions
    6. **Messages** - Admin messages and fighter-to-fighter messages
  - Mandatory Fight Requests moved from Resume to Training & Matchmaking section
  - Improved visual hierarchy and navigation

#### Enhanced Admin Panel
- **Feature**: Complete redesign and organization of Admin Panel
- **Location**: Admin Panel
- **Details**:
  - Background image: `Analytics page.png` with dark overlay
  - Clickable Accordion categories for easy navigation:
    - User Management
    - Content Management
    - Fight Management
    - Training & Matchmaking
    - Communication
    - Disputes & Moderation
    - Analytics & Reports
    - System Settings
  - Improved visual design with better spacing and organization
  - White title text for better contrast

#### Social Page Admin Identification
- **Feature**: Admin users display as "TBC Promoter" in Club Chat
- **Location**: Social page → Club Chat
- **Details**:
  - Admin messages show "TBC Promoter" instead of "Unknown User"
  - Automatic detection based on user ID, email, or app metadata role
  - Consistent branding across the platform

### ⚡ Performance Improvements

#### Removed Polling Intervals
- **Issue**: 3-second polling interval in FighterProfile causing constant data loading
- **Fix**: Removed polling interval; real-time subscriptions handle all updates
- **Impact**: ~90% reduction in unnecessary API calls

#### Debounced Real-time Handlers
- **Issue**: Immediate reloads on every real-time event causing performance issues
- **Fix**: Added debouncing (200-300ms) to all real-time subscription handlers
- **Impact**: Prevents excessive API calls during rapid events

#### Optimized Window Focus Handler
- **Issue**: Window focus handler reloading data on every focus event
- **Fix**: Added 2-second debounce to focus handler
- **Impact**: Reduces unnecessary reloads when switching tabs

#### Removed Multiple Reload Calls
- **Issue**: DELETE events triggering 3 separate reloads (100ms, 500ms, 1500ms)
- **Fix**: Single debounced reload (300ms) per event type
- **Impact**: 66% reduction in reload operations

#### Removed Excessive Console Logging
- **Issue**: 768+ console.log statements across codebase causing performance overhead
- **Fix**: Removed non-essential console.log statements from FighterProfile and other components
- **Impact**: Improved runtime performance and cleaner console output

#### Optimized Data Loading
- **Issue**: Real-time handlers reloading data even for insignificant changes
- **Fix**: Added change detection - only reload when significant changes occur (points, tier, weight class)
- **Impact**: Smarter data loading reduces unnecessary API calls

### 🔧 Bug Fixes

#### Notification Sound System
- **Issue**: Notification sound not playing when new notifications arrive
- **Fix**: 
  - Changed from continuous looping to one-time play on new notification
  - Sound plays immediately when new unread notification arrives via real-time subscription
  - Removed continuous sound loop that was playing while unread notifications existed
- **Impact**: Better user experience with proper notification alerts

#### @Mention Notification RLS Policy
- **Issue**: 403 Forbidden errors when creating notifications for mentioned fighters
- **Fix**: 
  - Created `create_notification_rpc` PostgreSQL function with SECURITY DEFINER
  - Function bypasses RLS policies to allow system-generated notifications
  - Updated notificationService to use RPC function instead of direct INSERT
- **Impact**: @Mention notifications now work correctly

#### Automatic Loss System Points
- **Issue**: Losing fighter receiving +1 point instead of -3 points
- **Fix**: 
  - Updated `auto_create_opponent_loss` function to explicitly set `points_earned = -3`
  - Ensured `update_fighter_stats_after_fight` trigger always recalculates points
  - Recalculated all existing fight records and fighter profiles
- **Impact**: Correct point calculations for all fights

#### Admin Name Display
- **Issue**: Admin showing as "Unknown User" in Club Chat
- **Fix**: 
  - Added admin user ID tracking in Social component
  - Updated `getDisplayName` function to check admin status
  - Displays "TBC Promoter" for admin users
- **Impact**: Proper branding and identification of admin messages

### 📊 System Updates

#### Tier System Enhancement
- **Added**: "Hall of famer" tier (560+ points)
- **Updated Tier Thresholds**:
  - Amateur: 0-29 points
  - Semi-Pro: 30-69 points
  - Pro: 70-139 points
  - Contender: 140-279 points
  - Elite: 280-559 points
  - **Hall of famer: 560+ points** (NEW)

#### Point System Verification
- **Verified and Fixed**:
  - Win = +5 points
  - Loss = -3 points (verified and fixed)
  - Draw = 0 points
  - KO/TKO Bonus = +3 points (only for winners)

#### Database Schema Updates
- **New Tables**:
  - `admin_direct_messages` - Admin-to-fighter messaging
  - `fighter_direct_messages` - Fighter-to-fighter messaging
- **New Functions**:
  - `create_notification_rpc` - RPC function for creating notifications (bypasses RLS)
- **Updated Functions**:
  - `auto_create_opponent_loss` - Fixed to set -3 points for losses
  - `calculate_fight_points` - Verified correct point calculations
  - `update_fighter_stats_after_fight` - Always recalculates points

#### Rules and Guidelines Updates
- **Added Section**: TBC Promotions Fight Calendar
  - Admin posts Fight Cards and Tournament schedules
  - Admin selects fighters for Live Events and Tournaments based on performance
  - All Admin updates display in News and Announcements
- **Updated**: Point System table to show Loss = -3
- **Updated**: Tier Thresholds to include Hall of famer (560+)
- **Updated**: Version header to v1.1.3

### 📁 Files Changed

#### New Files
- `src/components/Admin/AdminDirectMessages.tsx` - Admin messaging interface
- `src/components/FighterProfile/FighterDirectMessages.tsx` - Fighter-to-fighter messaging
- `src/services/adminMessageService.ts` - Admin message service
- `src/services/fighterMessageService.ts` - Fighter message service
- `database/admin-direct-messages-schema.sql` - Admin messages table schema
- `database/fighter-direct-messages-schema.sql` - Fighter messages table schema
- `database/create-notification-function-rpc.sql` - Notification RPC function
- `database/CRITICAL-FIX-AUTOMATIC-LOSS-POINTS.sql` - Point system fix
- `database/fix-notifications-mention-rls.sql` - RLS policy fix

#### Updated Files
- `src/components/FighterProfile/FighterProfile.tsx` - Profile reorganization, performance optimizations
- `src/components/Admin/AdminPanel.tsx` - Redesign with background and accordions
- `src/components/Social/Social.tsx` - Admin name display, @mention notifications
- `src/components/Shared/NotificationBell.tsx` - Sound fix, performance improvements
- `src/components/RulesGuidelines/RulesGuidelines.tsx` - Version 1.1.3 updates
- `src/services/notificationService.ts` - RPC function integration
- `src/services/chatService.ts` - @mention notification logic
- `src/services/rankingsService.ts` - Hall of famer tier support
- `src/types/index.ts` - Hall of famer tier type definition
- `package.json` - Version 1.1.3

### 🎯 Key Improvements Summary

1. **Communication**: Two new messaging systems (Admin-to-Fighter and Fighter-to-Fighter)
2. **Performance**: 90% reduction in unnecessary API calls through optimizations
3. **User Experience**: Better organized profile page and admin panel
4. **Notifications**: Fixed sound system and added @mention support
5. **System Integrity**: Fixed point calculations and verified tier system
6. **Branding**: Consistent "TBC Promoter" display for admin messages

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

