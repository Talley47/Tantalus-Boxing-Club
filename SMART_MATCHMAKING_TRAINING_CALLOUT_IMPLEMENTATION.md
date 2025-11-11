# Smart Matchmaking, Training Camp, and Callout System Implementation

## Overview

This document describes the implementation of three major systems:
1. **Smart Matchmaking System** - Automatically matches fighters based on rankings, weight class, tier, and points
2. **Training Camp System** - Allows fighters to invite others for 72-hour training camps
3. **Callout System** - Enables fighters to callout other fighters with fair matching validation

## Database Setup

### Step 1: Run the SQL Schema

Run the following SQL file in your Supabase SQL Editor:

```
database/smart-matchmaking-training-callout-schema.sql
```

This will create:
- New columns in `scheduled_fights` table (match_type, auto_matched_at, match_score)
- `training_camp_invitations` table`
- `callout_requests` table
- RLS policies for all new tables
- Helper functions for expiration and validation

## Features Implemented

### 1. Smart Matchmaking System

**Location**: `src/services/smartMatchmakingService.ts`

**Features**:
- Automatically matches fighters based on:
  - Rankings (max 3 rank difference)
  - Weight class (must match)
  - Tier (preferred same tier)
  - Points (max 30 points difference)
- Creates mandatory scheduled fights
- Fair matching algorithm ensures no unskilled vs skilled matchups
- Minimum 60% compatibility score required

**Usage**:
```typescript
import { smartMatchmakingService } from './services/smartMatchmakingService';

// Auto-match all fighters
const matches = await smartMatchmakingService.autoMatchFighters();

// Get mandatory fights for a fighter
const mandatoryFights = await smartMatchmakingService.getMandatoryFights(fighterUserId);
```

### 2. Training Camp System

**Location**: `src/services/trainingCampService.ts`

**Features**:
- Fighters can send training camp invitations
- Invited fighters receive notifications
- 72-hour duration from acceptance
- Cannot start training camp within 3 days of a scheduled fight
- Accept/decline functionality

**Usage**:
```typescript
import { trainingCampService } from './services/trainingCampService';

// Check if fighter can start training camp
const canStart = await trainingCampService.canStartTrainingCamp(fighterUserId);

// Create invitation
const invitation = await trainingCampService.createInvitation(inviterUserId, {
  invitee_user_id: targetUserId,
  message: 'Optional message'
});

// Accept invitation
await trainingCampService.acceptInvitation(invitationId, inviteeUserId);

// Get pending invitations
const invitations = await trainingCampService.getPendingInvitations(fighterUserId);
```

### 3. Callout System

**Location**: `src/services/calloutService.ts`

**Features**:
- Fair matching validation:
  - Same weight class required
  - Max 5 rank difference
  - Max 50 points difference
  - Same tier preferred
- Prevents unskilled vs skilled matchups
- 7-day expiration
- Auto-schedules fight when accepted

**Usage**:
```typescript
import { calloutService } from './services/calloutService';

// Validate fair match before creating callout
const validation = await calloutService.validateFairMatch(callerUserId, targetUserId);

// Create callout
const callout = await calloutService.createCallout(callerUserId, {
  target_user_id: targetUserId,
  message: 'Optional message'
});

// Accept callout (auto-schedules fight)
await calloutService.acceptCallout(calloutId, targetUserId);

// Get pending callouts
const callouts = await calloutService.getPendingCallouts(fighterUserId);
```

## UI Components

### FighterProfile Component

**Location**: `src/components/FighterProfile/FighterProfile.tsx`

**New Sections**:
1. **Mandatory Fights (Auto-Matched)** - Displays automatically matched fights that fighters must complete
2. **Training Camp Invitations** - Shows pending invitations with accept/decline buttons
3. **Callout Requests** - Displays callout requests with fair match scores and accept/decline buttons

### HomePage Component

**Location**: `src/components/HomePage/HomePage.tsx`

**Updated**:
- Now displays ALL scheduled fights in the league (not just user's fights)
- Filters out admin accounts
- Shows match type (auto_mandatory, callout, training_camp, manual)

## Fair Matching Rules

### Smart Matchmaking
- **Rank Difference**: Max 3 ranks
- **Points Difference**: Max 30 points
- **Weight Class**: Must match
- **Tier**: Same tier preferred (+10 score), different tier (-15 score)
- **Minimum Score**: 60% compatibility required

### Callout System
- **Rank Difference**: Max 5 ranks
- **Points Difference**: Max 50 points
- **Weight Class**: Must match
- **Tier**: Same tier preferred (+10 score), different tier (-10 score)
- **Minimum Score**: 60% compatibility required

## Database Schema Details

### scheduled_fights Table Updates
- `match_type`: 'manual' | 'auto_mandatory' | 'callout' | 'training_camp'
- `auto_matched_at`: Timestamp when auto-matched
- `match_score`: Compatibility score (0-100)

### training_camp_invitations Table
- `inviter_id`: Fighter who sent invitation
- `invitee_id`: Fighter who received invitation
- `status`: 'pending' | 'accepted' | 'declined' | 'expired' | 'completed'
- `started_at`: When training camp started (72 hours from here)
- `expires_at`: When invitation/training camp expires

### callout_requests Table
- `caller_id`: Fighter who called out
- `target_id`: Fighter being called out
- `status`: 'pending' | 'accepted' | 'declined' | 'expired' | 'scheduled'
- `match_score`: Fair match score (0-100)
- `rank_difference`: Difference in rankings
- `points_difference`: Difference in points
- `tier_match`: Whether fighters are in same tier
- `scheduled_fight_id`: Link to scheduled fight if accepted

## Next Steps

1. **Run the SQL schema** in Supabase SQL Editor
2. **Test Smart Matchmaking**: Call `autoMatchFighters()` to create automatic matches
3. **Test Training Camp**: Send invitations and verify 3-day restriction works
4. **Test Callout**: Create callouts and verify fair matching validation

## Notes

- All systems filter out admin accounts
- Real-time updates are supported via Supabase subscriptions
- Notifications are created for all important events
- Expired invitations and callouts are automatically marked as expired
- Fighters have 1 week to complete fights, so training camps are blocked within 3 days of a fight

