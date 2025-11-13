import { supabase } from './supabase';
import { getRankingsByWeightClass, getOverallRankings } from './rankingsService';
import { filterAdminFighters } from '../utils/filterAdmins';
import { schedulingService } from './schedulingService';

export interface CalloutRequest {
  id: string;
  caller_id: string;
  target_id: string;
  status: 'pending' | 'accepted' | 'declined' | 'expired' | 'scheduled';
  match_score: number | null;
  rank_difference: number | null;
  points_difference: number | null;
  weight_class: string;
  tier_match: boolean;
  message: string | null;
  expires_at: string;
  scheduled_fight_id: string | null;
  created_at: string;
  updated_at: string;
  caller?: any;
  target?: any;
}

export interface CreateCalloutRequest {
  target_user_id: string;
  message?: string;
}

export interface FairMatchValidation {
  isFair: boolean;
  score: number;
  reasons: string[];
  rank_difference: number;
  points_difference: number;
  tier_match: boolean;
}

class CalloutService {
  // Check if two fighters have fought before (rematch check)
  private async haveFoughtBefore(callerUserId: string, targetUserId: string, callerName: string, targetName: string): Promise<boolean> {
    try {
      // Check if caller has fought target (check caller's fight records for target's name)
      // Note: fight_records.fighter_id references fighter_profiles(user_id), so use user_id
      const { data: callerRecords, error: callerError } = await supabase
        .from('fight_records')
        .select('id')
        .eq('fighter_id', callerUserId)
        .ilike('opponent_name', targetName.trim())
        .limit(1);

      if (callerError) {
        console.error('Error checking caller fight records:', callerError);
      }

      // Check if target has fought caller (check target's fight records for caller's name)
      const { data: targetRecords, error: targetError } = await supabase
        .from('fight_records')
        .select('id')
        .eq('fighter_id', targetUserId)
        .ilike('opponent_name', callerName.trim())
        .limit(1);

      if (targetError) {
        console.error('Error checking target fight records:', targetError);
      }

      // They have fought if either fighter has a record against the other
      return !!(callerRecords && callerRecords.length > 0) || !!(targetRecords && targetRecords.length > 0);
    } catch (error) {
      console.error('Error checking fight history:', error);
      return false;
    }
  }

  // Validate if a callout is fair (REMATCH ONLY - fighters must have fought before)
  // STRICT REQUIREMENTS:
  // 1. Fighters MUST have fought before (REMATCH ONLY)
  // 2. Fighters MUST be in the same weight class
  // 3. Fighters MUST be in the same tier
  // 4. Rankings must be within 5 ranks
  // 5. Points must be within 30 points
  async validateFairMatch(
    callerUserId: string,
    targetUserId: string
  ): Promise<FairMatchValidation> {
    try {
      // Get both fighter profiles
      const { data: caller, error: callerError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .eq('user_id', callerUserId)
        .single();

      const { data: target, error: targetError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .eq('user_id', targetUserId)
        .single();

      if (callerError || !caller || targetError || !target) {
        return {
          isFair: false,
          score: 0,
          reasons: ['Fighter profiles not found'],
          rank_difference: 999,
          points_difference: 999,
          tier_match: false
        };
      }

      // REMATCH CHECK: Fighters MUST have fought before
      const haveFought = await this.haveFoughtBefore(caller.user_id, target.user_id, caller.name, target.name);
      if (!haveFought) {
        return {
          isFair: false,
          score: 0,
          reasons: ['Rematch only: You can only request a rematch with fighters you have already fought. Check your fight records on your profile.'],
          rank_difference: 999,
          points_difference: 999,
          tier_match: false
        };
      }

      // Must be same weight class (REQUIRED)
      if (caller.weight_class !== target.weight_class) {
        return {
          isFair: false,
          score: 0,
          reasons: ['Fighters must be in the same weight class. Same weight class is REQUIRED.'],
          rank_difference: 999,
          points_difference: 999,
          tier_match: false
        };
      }

      // Must be same tier (REQUIRED)
      if (caller.tier !== target.tier) {
        return {
          isFair: false,
          score: 0,
          reasons: [`Fighters must be in the same tier. Different tiers: ${caller.tier} vs ${target.tier}. Same tier is REQUIRED.`],
          rank_difference: 999,
          points_difference: 999,
          tier_match: false
        };
      }

      // Get rankings for weight class
      const rankings = await getRankingsByWeightClass(caller.weight_class, 100);
      const callerRank = rankings.find(r => r.fighter_id === caller.user_id);
      const targetRank = rankings.find(r => r.fighter_id === target.user_id);

      if (!callerRank || !targetRank) {
        return {
          isFair: false,
          score: 0,
          reasons: ['Fighters not found in rankings'],
          rank_difference: 999,
          points_difference: 999,
          tier_match: false
        };
      }

      const rankDiff = Math.abs(callerRank.rank - targetRank.rank);
      const pointsDiff = Math.abs(caller.points - target.points);
      const tierMatch = caller.tier === target.tier;

      const reasons: string[] = [];
      let score = 100;

      // Fair match criteria (STRICT REQUIREMENTS):
      // - Same weight class: REQUIRED (already checked above)
      // - Same tier: REQUIRED (already checked above)
      // - Rank difference: max 5 ranks (REQUIRED)
      // - Points difference: max 30 points (REQUIRED)

      if (rankDiff > 5) {
        return {
          isFair: false,
          score: 0,
          reasons: [`Rank difference too large: ${rankDiff} (max: 5). Similar rankings within 5 ranks is REQUIRED.`],
          rank_difference: rankDiff,
          points_difference: pointsDiff,
          tier_match: tierMatch
        };
      }

      if (pointsDiff > 30) {
        return {
          isFair: false,
          score: 0,
          reasons: [`Points difference too large: ${pointsDiff} (max: 30). Similar points within 30 points is REQUIRED.`],
          rank_difference: rankDiff,
          points_difference: pointsDiff,
          tier_match: tierMatch
        };
      }

      // Calculate score (bonuses for close matches)
      const rankPenalty = rankDiff * 5; // 5 points per rank difference
      score -= rankPenalty;
      if (rankDiff > 0) {
        reasons.push(`Rank difference: ${rankDiff}`);
      }

      const pointsPenalty = pointsDiff / 2; // 0.5 points per point difference
      score -= pointsPenalty;
      if (pointsDiff > 0) {
        reasons.push(`Points difference: ${pointsDiff}`);
      }

      // Same tier bonus (should always be true at this point since we check it above)
      if (tierMatch) {
        score += 10;
        reasons.push(`Same tier: ${caller.tier}`);
      }

      score = Math.max(0, Math.min(100, score));

      return {
        isFair: score >= 60, // Minimum 60% for fair match
        score: Math.round(score),
        reasons,
        rank_difference: rankDiff,
        points_difference: pointsDiff,
        tier_match: tierMatch
      };
    } catch (error) {
      console.error('Error validating fair match:', error);
      return {
        isFair: false,
        score: 0,
        reasons: ['Error validating match'],
        rank_difference: 999,
        points_difference: 999,
        tier_match: false
      };
    }
  }

  // Create a callout request
  async createCallout(
    callerUserId: string,
    request: CreateCalloutRequest
  ): Promise<CalloutRequest> {
    try {
      // Validate fair match
      const validation = await this.validateFairMatch(callerUserId, request.target_user_id);
      
      if (!validation.isFair) {
        throw new Error(`Unfair match: ${validation.reasons.join(', ')}`);
      }

      // Get fighter profile IDs
      const { data: caller, error: callerError } = await supabase
        .from('fighter_profiles')
        .select('id, name, weight_class')
        .eq('user_id', callerUserId)
        .single();

      const { data: target, error: targetError } = await supabase
        .from('fighter_profiles')
        .select('id, name')
        .eq('user_id', request.target_user_id)
        .single();

      if (callerError || !caller || targetError || !target) {
        throw new Error('Fighter profiles not found');
      }

      // REMATCH CHECK: Verify fighters have fought before (required for rematch)
      const haveFought = await this.haveFoughtBefore(callerUserId, request.target_user_id, caller.name, target.name);
      if (!haveFought) {
        throw new Error('Rematch only: You can only request a rematch with fighters you have already fought. Check your fight records on your profile.');
      }

      // Check if there's already a pending callout
      const { data: existingCallouts, error: checkError } = await supabase
        .from('callout_requests')
        .select('id')
        .eq('caller_id', caller.id)
        .eq('target_id', target.id)
        .eq('status', 'pending')
        .limit(1);
      
      const existingCallout = existingCallouts && existingCallouts.length > 0 ? existingCallouts[0] : null;

      if (existingCallout) {
        throw new Error('You have already sent a pending callout to this fighter');
      }

      // Calculate expiration (7 days from now)
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);

      // Create callout request
      const { data: callout, error: insertError } = await supabase
        .from('callout_requests')
        .insert({
          caller_id: caller.id,
          target_id: target.id,
          status: 'pending',
          match_score: validation.score,
          rank_difference: validation.rank_difference,
          points_difference: validation.points_difference,
          weight_class: caller.weight_class,
          tier_match: validation.tier_match,
          message: request.message || null,
          expires_at: expiresAt.toISOString()
        })
        .select(`
          *,
          caller:fighter_profiles!caller_id(*),
          target:fighter_profiles!target_id(*)
        `)
        .single();

      if (insertError) throw insertError;

      // Create notification for target
      await supabase
        .from('notifications')
        .insert({
          user_id: request.target_user_id,
          type: 'Callout',
          title: 'Rematch Request',
          message: `You have received a rematch request. Check your profile to accept or decline.`,
          action_url: '/profile'
        });

      return callout;
    } catch (error) {
      console.error('Error creating callout:', error);
      throw error;
    }
  }

  // Accept a callout request
  async acceptCallout(calloutId: string, targetUserId: string): Promise<CalloutRequest> {
    try {
      // Get callout
      const { data: callout, error: calloutError } = await supabase
        .from('callout_requests')
        .select(`
          *,
          caller:fighter_profiles!caller_id(*),
          target:fighter_profiles!target_id(*)
        `)
        .eq('id', calloutId)
        .single();

      if (calloutError || !callout) {
        throw new Error('Callout not found');
      }

      // Verify target
      if (callout.target?.user_id !== targetUserId) {
        throw new Error('Unauthorized: You are not the target');
      }

      // Check if callout is still valid
      if (callout.status !== 'pending') {
        throw new Error(`Callout is ${callout.status}`);
      }

      if (new Date(callout.expires_at) < new Date()) {
        throw new Error('Callout has expired');
      }

      // Schedule the fight
      // Use default timezone and platform (columns don't exist in current schema)
      const fighterTimezone = 'UTC';
      const fighterPlatform = 'PC';
      
      const scheduledFight = await schedulingService.scheduleFight({
        fighter1_id: callout.caller_id,
        fighter2_id: callout.target_id,
        weight_class: callout.weight_class,
        scheduled_date: this.getNextAvailableDate(fighterTimezone).toISOString(),
        timezone: fighterTimezone,
        platform: fighterPlatform,
        connection_notes: `Scheduled via Callout: ${callout.caller?.name} called out ${callout.target?.name}. Must be completed within 1 week.`,
        house_rules: 'Standard boxing rules apply. Fight must be completed within 7 days of scheduling.'
      });

      // Update scheduled_fight to mark as callout
      await supabase
        .from('scheduled_fights')
        .update({
          match_type: 'callout'
        })
        .eq('id', scheduledFight.id);

      // Update callout to scheduled
      const { data: updatedCallout, error: updateError } = await supabase
        .from('callout_requests')
        .update({
          status: 'scheduled',
          scheduled_fight_id: scheduledFight.id,
          updated_at: new Date().toISOString()
        })
        .eq('id', calloutId)
        .select(`
          *,
          caller:fighter_profiles!caller_id(*),
          target:fighter_profiles!target_id(*)
        `)
        .single();

      if (updateError) throw updateError;

      // Create notifications for both fighters
      await supabase
        .from('notifications')
        .insert([
          {
            user_id: callout.caller?.user_id,
            type: 'Callout',
            title: 'Rematch Accepted',
            message: `${callout.target?.name} has accepted your rematch request. Fight scheduled!`,
            action_url: '/profile'
          },
          {
            user_id: targetUserId,
            type: 'Callout',
            title: 'Rematch Accepted',
            message: `You have accepted ${callout.caller?.name}'s rematch request. Fight scheduled!`,
            action_url: '/profile'
          }
        ]);

      return updatedCallout;
    } catch (error) {
      console.error('Error accepting callout:', error);
      throw error;
    }
  }

  // Decline a callout request
  async declineCallout(calloutId: string, targetUserId: string): Promise<void> {
    try {
      // Get callout
      const { data: callout, error: calloutError } = await supabase
        .from('callout_requests')
        .select('*, caller:fighter_profiles!caller_id(*)')
        .eq('id', calloutId)
        .single();

      if (calloutError || !callout) {
        throw new Error('Callout not found');
      }

      // Verify target
      if (callout.target_id && (await this.getFighterUserId(callout.target_id)) !== targetUserId) {
        throw new Error('Unauthorized: You are not the target');
      }

      // Update callout to declined
      const { error: updateError } = await supabase
        .from('callout_requests')
        .update({
          status: 'declined',
          updated_at: new Date().toISOString()
        })
        .eq('id', calloutId);

      if (updateError) throw updateError;

      // Create notification for caller
      await supabase
        .from('notifications')
        .insert({
          user_id: callout.caller?.user_id,
          type: 'Callout',
          title: 'Rematch Declined',
          message: `Your rematch request has been declined.`,
          action_url: '/profile'
        });
    } catch (error) {
      console.error('Error declining callout:', error);
      throw error;
    }
  }

  // Get fighters that can have rematches with (fighters they've fought before)
  async getRematchableFighters(fighterUserId: string): Promise<any[]> {
    try {
      // Get fighter profile
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id, name, weight_class, tier, points, user_id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return [];
      }

      // Get fighter's fight records to find opponents they've fought
      // Note: fight_records.fighter_id references fighter_profiles(user_id), so use user_id
      const { data: fightRecords, error: recordsError } = await supabase
        .from('fight_records')
        .select('opponent_name')
        .eq('fighter_id', fighter.user_id);

      if (recordsError || !fightRecords || fightRecords.length === 0) {
        return [];
      }

      // Extract unique opponent names
      const opponentNames = Array.from(new Set(fightRecords.map(record => record.opponent_name?.trim()).filter(Boolean)));

      if (opponentNames.length === 0) {
        return [];
      }

      // Find fighter profiles matching these opponent names
      const { data: opponents, error: opponentsError } = await supabase
        .from('fighter_profiles')
        .select('id, name, weight_class, tier, points, user_id')
        .in('name', opponentNames)
        .not('user_id', 'is', null);

      if (opponentsError || !opponents) {
        return [];
      }

      // Filter to only same weight class and tier (rematch requirements)
      const rematchableFighters = opponents.filter(opponent => 
        opponent.weight_class === fighter.weight_class &&
        opponent.tier === fighter.tier &&
        opponent.user_id !== fighterUserId
      );

      // Get rankings to add rank information
      const rankings = await getRankingsByWeightClass(fighter.weight_class, 1000);
      
      // Filter by fair match criteria (rank difference <= 5, points difference <= 30)
      const eligibleRematchableFighters = rematchableFighters.filter(opponent => {
        const callerRank = rankings.find(r => r.fighter_id === fighter.user_id);
        const opponentRank = rankings.find(r => r.fighter_id === opponent.user_id);
        
        if (!callerRank || !opponentRank) {
          return false; // Skip if not in rankings
        }
        
        const rankDiff = Math.abs(callerRank.rank - opponentRank.rank);
        const pointsDiff = Math.abs(fighter.points - opponent.points);
        
        // Must meet fair match criteria
        return rankDiff <= 5 && pointsDiff <= 30;
      });
      
      return eligibleRematchableFighters.map(opponent => {
        const opponentRank = rankings.find(r => r.fighter_id === opponent.user_id);
        return {
          ...opponent,
          rank: opponentRank?.rank || null,
          rank_difference: opponentRank && rankings.find(r => r.fighter_id === fighter.user_id)
            ? Math.abs((rankings.find(r => r.fighter_id === fighter.user_id)?.rank || 0) - (opponentRank.rank || 0))
            : null,
          points_difference: Math.abs(fighter.points - opponent.points)
        };
      });
    } catch (error) {
      console.error('Error getting rematchable fighters:', error);
      return [];
    }
  }

  // Get pending callouts for a fighter (where they are the target)
  async getPendingCallouts(fighterUserId: string): Promise<CalloutRequest[]> {
    try {
      // Get fighter profile ID
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return [];
      }

      // Fetch callouts without joins
      const { data: callouts, error: calloutsError } = await supabase
        .from('callout_requests')
        .select('*')
        .eq('target_id', fighter.id)
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

      if (calloutsError) {
        console.error('Error fetching pending callouts:', calloutsError);
        return [];
      }

      if (!callouts || callouts.length === 0) {
        return [];
      }

      // Fetch fighter profiles separately
      const callerIds = Array.from(new Set(callouts.map(c => c.caller_id).filter(Boolean)));
      const targetIds = Array.from(new Set(callouts.map(c => c.target_id).filter(Boolean)));
      const allFighterIds = Array.from(new Set([...callerIds, ...targetIds]));

      const { data: fighters } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('id', allFighterIds);

      // Combine data
      return callouts.map(callout => ({
        ...callout,
        caller: fighters?.find(f => f.id === callout.caller_id) || null,
        target: fighters?.find(f => f.id === callout.target_id) || null,
      }));
    } catch (error) {
      console.error('Error in getPendingCallouts:', error);
      return [];
    }
  }

  // Get scheduled callouts (accepted callouts that are now scheduled fights)
  async getScheduledCallouts(fighterUserId?: string): Promise<Array<{
    id: string;
    scheduled_fight_id: string;
    caller: any;
    target: any;
    scheduled_date: string;
    weight_class: string;
    status: string;
    message: string | null;
  }>> {
    try {
      // First, get fighter profile ID if fighterUserId is provided
      let fighterProfileId: string | null = null;
      if (fighterUserId) {
        const { data: fighter } = await supabase
          .from('fighter_profiles')
          .select('id')
          .eq('user_id', fighterUserId)
          .single();

        if (fighter) {
          fighterProfileId = fighter.id;
        }
      }

      // Build query for scheduled callouts (without joins)
      let query = supabase
        .from('callout_requests')
        .select('*')
        .eq('status', 'scheduled')
        .order('created_at', { ascending: false });

      // If fighterProfileId is provided, filter to show only callouts involving this fighter
      if (fighterProfileId) {
        query = query.or(`caller_id.eq.${fighterProfileId},target_id.eq.${fighterProfileId}`);
      }

      const { data: callouts, error: calloutsError } = await query;

      if (calloutsError) {
        console.error('Error fetching scheduled callouts:', calloutsError);
        return [];
      }

      if (!callouts || callouts.length === 0) {
        return [];
      }

      // Get unique fighter profile IDs and scheduled fight IDs
      const callerIds = Array.from(new Set(callouts.map(c => c.caller_id).filter(Boolean)));
      const targetIds = Array.from(new Set(callouts.map(c => c.target_id).filter(Boolean)));
      const allProfileIds = Array.from(new Set([...callerIds, ...targetIds]));
      const scheduledFightIds = Array.from(new Set(callouts.map(c => c.scheduled_fight_id).filter(Boolean)));

      // Fetch fighter profiles separately
      const { data: profiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('id', allProfileIds);

      if (profilesError) {
        console.error('Error fetching fighter profiles:', profilesError);
      }

      // Fetch scheduled fights separately
      const { data: scheduledFights, error: fightsError } = scheduledFightIds.length > 0
        ? await supabase
            .from('scheduled_fights')
            .select('id, scheduled_date, status')
            .in('id', scheduledFightIds)
        : { data: [], error: null };

      if (fightsError) {
        console.error('Error fetching scheduled fights:', fightsError);
      }

      // Create maps for quick lookup
      const profileMap = new Map((profiles || []).map(p => [p.id, p]));
      const fightMap = new Map((scheduledFights || []).map(f => [f.id, f]));

      // Map to include scheduled date from scheduled_fights
      return callouts.map(callout => ({
        id: callout.id,
        scheduled_fight_id: callout.scheduled_fight_id,
        caller: callout.caller_id ? profileMap.get(callout.caller_id) : null,
        target: callout.target_id ? profileMap.get(callout.target_id) : null,
        scheduled_date: callout.scheduled_fight_id ? (fightMap.get(callout.scheduled_fight_id)?.scheduled_date || '') : '',
        weight_class: callout.weight_class,
        status: callout.status,
        message: callout.message
      }));
    } catch (error) {
      console.error('Error in getScheduledCallouts:', error);
      return [];
    }
  }

  // Get next available date for scheduling (1 week from now - fighters have 1 week to complete)
  // Uses the fighter's timezone to set the date correctly
  private getNextAvailableDate(timezone: string = 'UTC'): Date {
    const now = new Date();
    // Schedule for 1 week (7 days) from now
    const oneWeekFromNow = new Date(now);
    oneWeekFromNow.setDate(oneWeekFromNow.getDate() + 7);
    
    // Add some random hours (0-12) for variety in scheduling times
    oneWeekFromNow.setHours(oneWeekFromNow.getHours() + Math.floor(Math.random() * 12));
    
    return oneWeekFromNow;
  }

  // Helper to get fighter user_id from profile id
  private async getFighterUserId(profileId: string): Promise<string | null> {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select('user_id')
      .eq('id', profileId)
      .maybeSingle();

    if (error || !data) return null;
    return data.user_id || null;
  }
}

export const calloutService = new CalloutService();

