# Creative Fighter Image Upload Feature

## Overview
This feature allows fighters to upload a picture of their Creative Fighter (CAF) that displays on their profile and in the Home Page Top 30 Fighters section.

## Implementation Details

### 1. Database Schema
- **File**: `tantalus-boxing-club/database/add-creative-fighter-image.sql`
- **Column**: `creative_fighter_image_url` (TEXT) added to `fighter_profiles` table
- **Storage**: Uses existing `fight-submissions` Supabase Storage bucket

### 2. TypeScript Types
- **File**: `tantalus-boxing-club/src/types/index.ts`
- Added `creative_fighter_image_url?: string` to `FighterProfile` interface

### 3. Service Updates
- **File**: `tantalus-boxing-club/src/services/homePageService.ts`
- Updated `Fighter` interface to include `creative_fighter_image_url`
- Updated `getTopFighters()` to fetch and map `creative_fighter_image_url`

### 4. Fighter Profile Component
- **File**: `tantalus-boxing-club/src/components/FighterProfile/FighterProfile.tsx`
- **Features**:
  - Upload button in Physical Information section (when editing)
  - Image display on right side of Physical Information section (when not editing)
  - Two-column layout: Left = Physical Info, Right = Creative Fighter Image
  - File validation (image types only, max 10MB)
  - Preview of current image when editing

### 5. Home Page Component
- **File**: `tantalus-boxing-club/src/components/HomePage/HomePage.tsx`
- **Features**:
  - Displays Creative Fighter image at the top of each fighter card in Top 30 Fighters section
  - Image appears above fighter name and stats
  - Special border styling for top 3 fighters (gold border)

## Setup Instructions

1. **Run Database Migration**:
   ```sql
   -- Execute in Supabase SQL Editor
   -- File: tantalus-boxing-club/database/add-creative-fighter-image.sql
   ```

2. **Storage Bucket**:
   - The feature uses the existing `fight-submissions` bucket
   - Ensure the bucket exists and has proper RLS policies (see `setup-scorecard-storage.sql`)

3. **Usage**:
   - Fighters can upload their Creative Fighter image from the My Profile page
   - Navigate to Physical Information section
   - Click Edit button
   - Click "Upload Creative Fighter Image" button
   - Select an image file (PNG, JPG, GIF, max 10MB)
   - Click Save
   - The image will appear on the right side of Physical Information and in the Home Page Top 30 Fighters section

## File Structure
```
tantalus-boxing-club/
├── database/
│   └── add-creative-fighter-image.sql
├── src/
│   ├── types/
│   │   └── index.ts (updated)
│   ├── services/
│   │   └── homePageService.ts (updated)
│   └── components/
│       ├── FighterProfile/
│       │   └── FighterProfile.tsx (updated)
│       └── HomePage/
│           └── HomePage.tsx (updated)
```

## Notes
- Images are stored in Supabase Storage under `{fighter_id}/{timestamp}_{random}.{ext}`
- Images are publicly accessible via the generated public URL
- The feature reuses the existing `fight-submissions` storage bucket for consistency

