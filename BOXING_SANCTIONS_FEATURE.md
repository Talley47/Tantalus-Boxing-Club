# Boxing Sanctions Feature

## Overview

The Boxing Sanctions feature allows fighters to join different boxing sanctioning bodies and view rankings within each sanction. Fighters are ranked based on points, tier, demotions, and win records.

## Features Implemented

### 1. Fighter Sanctions Database
- **Table**: `fighter_sanctions`
- Tracks which fighters have joined which sanctions
- Prevents duplicate memberships (unique constraint on fighter_id + sanction_acronym)
- Includes RLS policies for security

### 2. Join/Leave Functionality
- Fighters can join any of the 6 active sanctions
- Fighters can leave sanctions they've joined
- Real-time updates when joining/leaving

### 3. Sanction Rankings
Fighters within each sanction are ranked based on:
1. **Points** (primary) - Higher points = better rank
2. **Tier** (secondary) - Elite > Contender > Pro > Semi-Pro > Amateur
3. **Demotions** (tertiary) - Fewer demotions = better rank
4. **Wins** (quaternary) - More wins = better rank

### 4. Active Sanctions
All 6 sanctions are now marked as **Active**:
- **TBCA** - Tantalus Boxing Club Amateur Association
- **TBA** - Tantalus Boxing Association
- **TBO** - Tantalus Boxing Organization
- **TBF** - Tantalus Boxing Federation
- **TBC** - Tantalus Boxing Council
- **TRM** - Tantalus Ring Magazine

### 5. UI Updates
- Changed "View Details" button to "Join" button
- Shows "View Fighters" and "Leave" buttons for joined sanctions
- Dialog displays all fighters who joined a sanction with:
  - Rank (#1, #2, etc.)
  - Fighter name and handle
  - Tier (color-coded chips)
  - Points
  - Win-Loss-Draw record
  - Number of demotions

## Database Setup

Run the following SQL script in your Supabase SQL Editor:

```sql
-- File: database/create-fighter-sanctions-table.sql
```

This creates:
- `fighter_sanctions` table
- RLS policies (public can view, fighters can join/leave their own, admins can manage all)
- Indexes for performance

## Service

The `fighterSanctionService` provides:
- `joinSanction(sanctionAcronym, userId)` - Join a sanction
- `leaveSanction(sanctionAcronym, userId)` - Leave a sanction
- `hasJoinedSanction(sanctionAcronym, userId)` - Check membership
- `getFightersBySanction(sanctionAcronym)` - Get ranked fighters
- `getSanctionsByFighter(userId)` - Get all sanctions a fighter joined

## Usage

1. Navigate to Home Page > Boxing Sanctions tab
2. Click "Join" on any sanction card
3. Click "View Fighters" to see all members ranked
4. Click "Leave" to leave a sanction

## Ranking Algorithm

Fighters are sorted by:
1. **Points** (descending) - Primary ranking factor
2. **Tier** (descending) - Elite > Contender > Pro > Semi-Pro > Amateur
3. **Demotions** (ascending) - Fewer demotions is better
4. **Wins** (descending) - More wins is better

Demotions are calculated by counting consecutive losses:
- 5 consecutive losses = 1 demotion
- Demotions reset after a win

## Files Created/Modified

### New Files:
- `database/create-fighter-sanctions-table.sql` - Database schema
- `src/services/fighterSanctionService.ts` - Service for managing sanctions

### Modified Files:
- `src/components/HomePage/HomePage.tsx` - Added sanctions UI and functionality

## Notes

- Fighters must have a fighter profile to join sanctions
- Rankings are calculated in real-time when viewing fighters
- The #1 ranked fighter is highlighted in gold
- Clicking on a fighter row in the dialog navigates to their profile

