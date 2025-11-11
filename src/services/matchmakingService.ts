import { supabase } from './supabase';
import { FighterProfile, MatchmakingRequest, ScheduledFight } from '../types';
import { getOverallRankings, getRankingsByWeightClass, TIER_THRESHOLDS } from './rankingsService';
import { getAllowedWeightClasses } from '../utils/weightClassUtils';
import { filterAdminFighters } from '../utils/filterAdmins';

export interface MatchmakingCriteria {
  weight_class: string;
  min_rank?: number;
  max_rank?: number;
  min_points?: number;
  max_points?: number;
  timezone?: string;
  availability_window?: string;
  avoid_recent_opponents?: boolean;
}

export interface MatchmakingSuggestion {
  fighter: FighterProfile;
  compatibility_score: number;
  reasons: string[];
  last_fought?: string;
  timezone_match: boolean;
  rank_difference: number;
  points_difference: number;
}

export interface MatchmakingResult {
  suggestions: MatchmakingSuggestion[];
  total_available: number;
  criteria_used: MatchmakingCriteria;
}

class MatchmakingService {
  // Get available fighters for matchmaking
  async getAvailableFighters(criteria: MatchmakingCriteria): Promise<FighterProfile[]> {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select('*')
      .eq('weight_class', criteria.weight_class)
      .order('points', { ascending: false });

    if (error) throw error;
    const fighters = data || [];
    
    // Filter out admin users
    return await filterAdminFighters(fighters);
  }

  // Get recent opponents to avoid repeat matchups
  async getRecentOpponents(fighterId: string, limit: number = 5): Promise<string[]> {
    const { data, error } = await supabase
      .from('fight_records')
      .select('opponent_name')
      .eq('fighter_id', fighterId)
      .order('date', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data?.map(record => record.opponent_name) || [];
  }

  // Calculate compatibility score between two fighters
  // ⚠️ STRICT REQUIREMENTS - FIGHTERS WILL NOT BE MATCHED IF ANY REQUIREMENT IS NOT MET:
  // 1. ✅ Same weight class (REQUIRED)
  // 2. ✅ Same tier (REQUIRED)
  // 3. ✅ Rankings within 3 ranks (REQUIRED)
  // 4. ✅ Points within 30 points (REQUIRED)
  calculateCompatibilityScore(
    fighter: FighterProfile,
    target: FighterProfile,
    criteria: MatchmakingCriteria
  ): MatchmakingSuggestion {
    const reasons: string[] = [];
    let score = 100; // Start with perfect score

    // STRICT CHECK #1: Weight class must match (REQUIRED)
    if (fighter.weight_class !== target.weight_class) {
      console.warn(`[Matchmaking] REJECTED: Different weight classes - ${fighter.name} (${fighter.weight_class}) vs ${target.name} (${target.weight_class})`);
      return {
        fighter: target,
        compatibility_score: 0,
        reasons: [`REQUIRED: Same weight class. ${fighter.weight_class} ≠ ${target.weight_class}`],
        timezone_match: false,
        rank_difference: 999,
        points_difference: 999
      };
    }
    reasons.push(`✓ Same weight class: ${fighter.weight_class}`);

    // STRICT CHECK #2: Tier must match (REQUIRED)
    if (fighter.tier !== target.tier) {
      console.warn(`[Matchmaking] REJECTED: Different tiers - ${fighter.name} (${fighter.tier}) vs ${target.name} (${target.tier})`);
      return {
        fighter: target,
        compatibility_score: 0,
        reasons: [`REQUIRED: Same tier. ${fighter.tier} ≠ ${target.tier}`],
        timezone_match: false,
        rank_difference: 999,
        points_difference: 999
      };
    }
    score += 10; // Bonus for same tier
    reasons.push(`✓ Same tier: ${fighter.tier}`);

    // Rank difference calculation
    const fighterRank = fighter.rank ?? 999;
    const targetRank = target.rank ?? 999;
    const rankDiff = Math.abs(fighterRank - targetRank);
    
    // STRICT CHECK #3: Rank difference must be within 3 ranks (REQUIRED)
    if (rankDiff > 3) {
      console.warn(`[Matchmaking] REJECTED: Rank difference too large - ${fighter.name} (rank ${fighterRank}) vs ${target.name} (rank ${targetRank}), difference: ${rankDiff}`);
      return {
        fighter: target,
        compatibility_score: 0,
        reasons: [`Rank difference too large: ${rankDiff} (max allowed: 3)`],
        timezone_match: false,
        rank_difference: rankDiff,
        points_difference: Math.abs(fighter.points - target.points)
      };
    }
    
    const rankPenalty = rankDiff * 5; // 5 points per rank difference
    score -= rankPenalty;
    if (rankDiff > 0) {
      reasons.push(`Rank difference: ${rankDiff}`);
    } else {
      reasons.push(`✓ Same rank: ${fighterRank}`);
    }

    // Points difference calculation
    const pointsDiff = Math.abs(fighter.points - target.points);
    
    // STRICT CHECK #4: Points difference must be within 30 points (REQUIRED)
    if (pointsDiff > 30) {
      console.warn(`[Matchmaking] REJECTED: Points difference too large - ${fighter.name} (${fighter.points} pts) vs ${target.name} (${target.points} pts), difference: ${pointsDiff}`);
      return {
        fighter: target,
        compatibility_score: 0,
        reasons: [`Points difference too large: ${pointsDiff} (max allowed: 30)`],
        timezone_match: false,
        rank_difference: rankDiff,
        points_difference: pointsDiff
      };
    }
    
    const pointsPenalty = pointsDiff / 2; // 0.5 points per point difference
    score -= pointsPenalty;
    if (pointsDiff > 0) {
      reasons.push(`Points difference: ${pointsDiff}`);
    } else {
      reasons.push(`✓ Same points: ${fighter.points}`);
    }

    // Timezone compatibility bonus
    const timezoneMatch = this.checkTimezoneCompatibility(fighter.timezone, target.timezone);
    if (timezoneMatch) {
      score += 10;
      reasons.push('✓ Timezone compatible');
    }

    // Recent form consideration
    const formBonus = this.calculateFormBonus(fighter, target);
    score += formBonus;
    if (formBonus > 0) {
      reasons.push('✓ Good form match');
    }

    // Ensure score is within bounds
    score = Math.max(0, Math.min(100, score));

    return {
      fighter: target,
      compatibility_score: Math.round(score),
      reasons,
      timezone_match: timezoneMatch,
      rank_difference: rankDiff,
      points_difference: pointsDiff
    };
  }

  // Check timezone compatibility
  private checkTimezoneCompatibility(tz1: string, tz2: string): boolean {
    // Simple timezone compatibility check
    // In a real implementation, you'd use a proper timezone library
    const timezoneOffsets: { [key: string]: number } = {
      'UTC': 0,
      'EST': -5,
      'PST': -8,
      'CST': -6,
      'MST': -7,
      'GMT': 0,
      'CET': 1,
      'JST': 9,
      'AEST': 10
    };

    const offset1 = timezoneOffsets[tz1] || 0;
    const offset2 = timezoneOffsets[tz2] || 0;
    const diff = Math.abs(offset1 - offset2);
    
    return diff <= 4; // Within 4 hours is compatible
  }

  // Calculate form bonus based on recent performance
  private calculateFormBonus(fighter: FighterProfile, target: FighterProfile): number {
    // Analyze recent form from last_20_results
    const fighterForm = this.analyzeForm(fighter.last_20_results || []);
    const targetForm = this.analyzeForm(target.last_20_results || []);
    
    // Bonus for similar form (both on winning streaks, etc.)
    if (fighterForm === targetForm) {
      return 5;
    }
    
    return 0;
  }

  // Analyze fighter form from recent results
  private analyzeForm(lastResults: any[]): string {
    if (!lastResults || lastResults.length === 0) return 'unknown';
    
    const recent = lastResults.slice(0, 5);
    const wins = recent.filter(r => r === 'Win').length;
    const losses = recent.filter(r => r === 'Loss').length;
    
    if (wins >= 4) return 'hot';
    if (losses >= 4) return 'cold';
    if (wins > losses) return 'good';
    if (losses > wins) return 'poor';
    return 'average';
  }

  // Find matchmaking suggestions for a fighter
  async findMatchmakingSuggestions(
    fighterId: string,
    criteria: MatchmakingCriteria
  ): Promise<MatchmakingResult> {
    try {
      // Get the requesting fighter's profile
      // fighterId is always user_id, not the primary key id
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .eq('user_id', fighterId)
        .single();

      if (fighterError || !fighter) {
        throw new Error('Fighter not found');
      }

      // Use fighter's actual weight class if criteria doesn't match
      // This is expected during initialization, so we silently adjust
      const effectiveWeightClass = fighter.weight_class || criteria.weight_class;
      
      // Only warn if there's a persistent mismatch (not just initialization)
      // This happens when user manually changes weight class in criteria
      if (fighter.weight_class && criteria.weight_class && 
          fighter.weight_class !== criteria.weight_class &&
          fighter.weight_class !== 'Lightweight') { // Don't warn on default fallback
        console.log(`Using fighter's weight class (${fighter.weight_class}) instead of criteria (${criteria.weight_class})`);
      }

      // Get available fighters in the same weight class (use fighter's actual weight class)
      const effectiveCriteria = {
        ...criteria,
        weight_class: effectiveWeightClass
      };
      let availableFighters = await this.getAvailableFighters(effectiveCriteria);
      
      // Filter out admin users
      availableFighters = await filterAdminFighters(availableFighters);
      
      // Filter out the requesting fighter (by user_id, since fighterId is user_id)
      const otherFighters = availableFighters.filter(f => f.user_id !== fighter.user_id);
      
      // Get recent opponents to avoid (use user_id for fight_records)
      const recentOpponents = criteria.avoid_recent_opponents 
        ? await this.getRecentOpponents(fighter.user_id)
        : [];

      // Get rankings to check rank differences
      const rankings = await getRankingsByWeightClass(effectiveWeightClass, 100);
      const fighterRankEntry = rankings.find(r => r.fighter_id === fighter.user_id);
      const fighterRank = fighterRankEntry?.rank ?? 999;

      // Calculate compatibility scores
      const suggestions: MatchmakingSuggestion[] = otherFighters
        .filter(target => {
          // STRICT REQUIREMENT #1: Same tier (REQUIRED)
          if (fighter.tier !== target.tier) {
            return false;
          }
          
          // STRICT REQUIREMENT #2: Same weight class (should already be filtered, but double-check)
          if (fighter.weight_class !== target.weight_class) {
            return false;
          }
          
          // STRICT REQUIREMENT #3: Rank difference within 3 ranks
          const targetRankEntry = rankings.find(r => r.fighter_id === target.user_id);
          const targetRank = targetRankEntry?.rank ?? 999;
          const rankDiff = Math.abs(fighterRank - targetRank);
          if (rankDiff > 3) {
            return false;
          }
          
          // STRICT REQUIREMENT #4: Points difference within 30 points
          const pointsDiff = Math.abs(fighter.points - target.points);
          if (pointsDiff > 30) {
            return false;
          }
          
          // Avoid recent opponents
          if (recentOpponents.includes(target.name)) {
            return false;
          }
          
          // Apply rank window filter (if specified in criteria)
          if (criteria.min_rank && targetRank < criteria.min_rank) return false;
          if (criteria.max_rank && targetRank > criteria.max_rank) return false;
          
          // Apply points filter (if specified in criteria)
          if (criteria.min_points && target.points < criteria.min_points) return false;
          if (criteria.max_points && target.points > criteria.max_points) return false;
          
          return true;
        })
        .map(target => this.calculateCompatibilityScore(fighter, target, criteria))
        .filter(suggestion => suggestion.compatibility_score > 0) // Only include valid matches
        .sort((a, b) => b.compatibility_score - a.compatibility_score)
        .slice(0, 5); // Return top 5 suggestions

      return {
        suggestions,
        total_available: otherFighters.length,
        criteria_used: criteria
      };

    } catch (error) {
      console.error('Error finding matchmaking suggestions:', error);
      throw error;
    }
  }

  // Create a matchmaking request
  async createMatchmakingRequest(
    requesterUserId: string, // user_id from fighter_profiles
    targetUserId: string, // user_id from fighter_profiles
    criteria: MatchmakingCriteria
  ): Promise<MatchmakingRequest> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24); // 24 hour expiration

    // Get fighter profile IDs (primary key) from user_ids
    const { data: requesterProfile } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', requesterUserId)
      .single();
    
    const { data: targetProfile } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', targetUserId)
      .single();

    if (!requesterProfile || !targetProfile) {
      throw new Error('Fighter profiles not found');
    }

    const { data, error } = await supabase
      .from('matchmaking_requests')
      .insert({
        requester_id: requesterProfile.id, // Use primary key id
        target_id: targetProfile.id, // Use primary key id
        weight_class: criteria.weight_class,
        preferred_time: criteria.availability_window ? new Date(criteria.availability_window) : null,
        timezone: criteria.timezone || 'UTC',
        status: 'Pending',
        expires_at: expiresAt.toISOString()
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  // Accept a matchmaking request and auto-schedule the fight
  async acceptMatchmakingRequest(requestId: string): Promise<ScheduledFight> {
    // Get the request details
    const { data: request, error: requestError } = await supabase
      .from('matchmaking_requests')
      .select(`
        *,
        requester:fighter_profiles!requester_id(*),
        target:fighter_profiles!target_id(*)
      `)
      .eq('id', requestId)
      .single();

    if (requestError || !request) {
      throw new Error('Matchmaking request not found');
    }

    // Determine scheduled date - use preferred_time if available, otherwise schedule for 24-48 hours from now
    let scheduledDate = new Date();
    if (request.preferred_time) {
      scheduledDate = new Date(request.preferred_time);
    } else {
      // Schedule for 24-48 hours from now (default window)
      scheduledDate.setHours(scheduledDate.getHours() + 24);
      // Add random 0-24 hours for variety
      scheduledDate.setHours(scheduledDate.getHours() + Math.floor(Math.random() * 24));
    }

    // Get platform from requester
    const requesterPlatform = request.requester?.platform || 'PC';

    // Create scheduled fight using Smart Matchmaking system
    const { data: fight, error: fightError } = await supabase
      .from('scheduled_fights')
      .insert({
        fighter1_id: request.requester_id,
        fighter2_id: request.target_id,
        weight_class: request.weight_class,
        scheduled_date: scheduledDate.toISOString(),
        timezone: request.timezone || 'UTC',
        platform: requesterPlatform,
        status: 'Scheduled',
        connection_notes: 'Scheduled via Smart Matchmaking',
        house_rules: 'Follow standard boxing rules'
      })
      .select(`
        *,
        fighter1:fighter_profiles!fighter1_id(*),
        fighter2:fighter_profiles!fighter2_id(*)
      `)
      .single();

    if (fightError) throw fightError;

    // Update request status
    await supabase
      .from('matchmaking_requests')
      .update({ status: 'Accepted' })
      .eq('id', requestId);

    // Create notifications for both fighters
    await this.createScheduledFightNotifications(fight);

    return fight;
  }

  // Create notifications when a fight is scheduled via matchmaking
  private async createScheduledFightNotifications(fight: ScheduledFight): Promise<void> {
    const fighters = [
      { id: fight.fighter1_id, opponent: (fight as any).fighter2?.name || 'Opponent' },
      { id: fight.fighter2_id, opponent: (fight as any).fighter1?.name || 'Opponent' }
    ];

    for (const fighterInfo of fighters) {
      const { data: fighter, error } = await supabase
        .from('fighter_profiles')
        .select('user_id, name')
        .eq('id', fighterInfo.id)
        .single();

      if (!error && fighter) {
        await supabase
          .from('notifications')
          .insert({
            user_id: fighter.user_id,
            type: 'Match',
            title: 'Fight Scheduled via Smart Matchmaking!',
            message: `Your fight with ${fighterInfo.opponent} has been scheduled for ${new Date(fight.scheduled_date).toLocaleDateString()}`,
            action_url: '/profile'
          });
      }
    }
  }

  // Decline a matchmaking request
  async declineMatchmakingRequest(requestId: string): Promise<void> {
    const { error } = await supabase
      .from('matchmaking_requests')
      .update({ status: 'Declined' })
      .eq('id', requestId);

    if (error) throw error;
  }

  // Get pending matchmaking requests for a fighter
  async getPendingRequests(fighterId: string): Promise<MatchmakingRequest[]> {
    const { data, error } = await supabase
      .from('matchmaking_requests')
      .select(`
        *,
        requester:fighter_profiles!requester_id(*),
        target:fighter_profiles!target_id(*)
      `)
      .or(`requester_id.eq.${fighterId},target_id.eq.${fighterId}`)
      .eq('status', 'Pending')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  // Get scheduled fights for a fighter
  async getScheduledFights(fighterId: string): Promise<ScheduledFight[]> {
    const { data, error } = await supabase
      .from('scheduled_fights')
      .select(`
        *,
        fighter1:fighter_profiles!fighter1_id(*),
        fighter2:fighter_profiles!fighter2_id(*)
      `)
      .or(`fighter1_id.eq.${fighterId},fighter2_id.eq.${fighterId}`)
      .eq('status', 'Scheduled')
      .order('scheduled_date', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  // Cancel a scheduled fight
  async cancelScheduledFight(fightId: string): Promise<void> {
    const { error } = await supabase
      .from('scheduled_fights')
      .update({ status: 'Cancelled' })
      .eq('id', fightId);

    if (error) throw error;
  }

  // Auto-assign opponent using Smart Matchmaking based on Rankings, Tier, and Weight Class
  async autoAssignOpponent(fighterId: string): Promise<MatchmakingSuggestion | null> {
    try {
      // Get fighter profile with rankings
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .eq('user_id', fighterId)
        .single();

      if (fighterError || !fighter) {
        throw new Error('Fighter not found');
      }

      // Get rankings for fighter's weight class
      const weightClass = fighter.weight_class || 'Lightweight';
      const rankings = await getRankingsByWeightClass(weightClass, 100);
      
      // Find fighter's rank
      const fighterRankEntry = rankings.find(r => r.fighter_id === fighter.user_id);
      if (!fighterRankEntry) {
        throw new Error('Fighter not found in rankings');
      }
      
      const fighterRankNumber = fighterRankEntry.rank;
      const fighterTier = fighter.tier || 'Amateur';
      
      // Find fair matches within same tier and similar rank (±3 ranks)
      const minRank = Math.max(1, fighterRankNumber - 3);
      const maxRank = fighterRankNumber + 3;
      
      // Get candidates within rank range and same tier
      const candidates = rankings.filter(r => {
        const rank = r.rank;
        const tierMatch = r.tier === fighterTier;
        const rankInRange = rank >= minRank && rank <= maxRank;
        const notSelf = r.fighter_id !== fighter.user_id;
        
        // Also consider fighters within same tier but slightly outside rank range (±5)
        const closeRankRange = Math.abs(rank - fighterRankNumber) <= 5;
        
        return notSelf && tierMatch && (rankInRange || closeRankRange);
      });
      
      if (candidates.length === 0) {
        // If no same-tier matches, look for adjacent tiers
        const tierIndex = TIER_THRESHOLDS.findIndex(t => t.tier === fighterTier);
        const adjacentTiers: string[] = [];
        
        if (tierIndex > 0) {
          adjacentTiers.push(TIER_THRESHOLDS[tierIndex - 1].tier);
        }
        if (tierIndex < TIER_THRESHOLDS.length - 1) {
          adjacentTiers.push(TIER_THRESHOLDS[tierIndex + 1].tier);
        }
        
        const adjacentTierCandidates = rankings.filter(r => {
          const rank = r.rank;
          const rankInRange = rank >= minRank && rank <= maxRank;
          const notSelf = r.fighter_id !== fighter.user_id;
          return notSelf && adjacentTiers.includes(r.tier) && rankInRange;
        });
        
        candidates.push(...adjacentTierCandidates);
      }
      
      // Get fighter profiles for candidates
      const candidateIds = candidates.map(c => c.fighter_id);
      const { data: candidateProfiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('user_id', candidateIds);
      
      if (profilesError || !candidateProfiles || candidateProfiles.length === 0) {
        return null;
      }
      
      // Get recent opponents to avoid
      const recentOpponents = await this.getRecentOpponents(fighterId);
      
      // Score and rank candidates
      const scoredCandidates = candidateProfiles
        .filter(p => !recentOpponents.includes(p.name))
        .map(candidate => {
          const candidateRank = rankings.find(r => r.fighter_id === candidate.user_id);
          const rankDiff = candidateRank ? Math.abs(candidateRank.rank - fighterRankNumber) : 999;
          const pointsDiff = Math.abs(candidate.points - fighter.points);
          const tierMatch = candidate.tier === fighterTier;
          
          // Score: lower is better (closer match)
          let score = rankDiff * 10; // Rank difference weighted heavily
          score += pointsDiff / 10; // Points difference
          if (!tierMatch) score += 50; // Penalty for different tier
          
          return {
            candidate,
            score,
            rankDiff,
            pointsDiff,
            tierMatch
          };
        })
        .sort((a, b) => a.score - b.score)
        .slice(0, 3); // Top 3 candidates
      
      if (scoredCandidates.length === 0) {
        return null;
      }
      
      // Return best match
      const bestMatch = scoredCandidates[0].candidate;
      const bestMatchRank = rankings.find(r => r.fighter_id === bestMatch.user_id);
      
      return this.calculateCompatibilityScore(fighter, bestMatch, {
        weight_class: weightClass,
        min_rank: bestMatchRank ? bestMatchRank.rank - 2 : undefined,
        max_rank: bestMatchRank ? bestMatchRank.rank + 2 : undefined,
      });
      
    } catch (error) {
      console.error('Error auto-assigning opponent:', error);
      return null;
    }
  }

  // Training Camp: Auto-assign sparring partner
  async autoAssignSparringPartner(fighterId: string): Promise<MatchmakingSuggestion | null> {
    try {
      // Get fighter profile
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .eq('user_id', fighterId)
        .single();

      if (fighterError || !fighter) {
        throw new Error('Fighter not found');
      }

      const weightClass = fighter.weight_class || 'Lightweight';
      const fighterTier = fighter.tier || 'Amateur';
      
      // Get rankings for weight class
      const rankings = await getRankingsByWeightClass(weightClass, 100);
      const fighterRankEntry = rankings.find(r => r.fighter_id === fighter.user_id);
      
      if (!fighterRankEntry) {
        throw new Error('Fighter not found in rankings');
      }
      
      const fighterRankNumber = fighterRankEntry.rank;
      
      // For sparring, we're more flexible - look for similar skill level
      // Same tier preferred, but adjacent tiers are okay
      // Rank range: ±5 ranks
      const minRank = Math.max(1, fighterRankNumber - 5);
      const maxRank = fighterRankNumber + 5;
      
      const tierIndex = TIER_THRESHOLDS.findIndex(t => t.tier === fighterTier);
      const allowedTiers: string[] = [fighterTier];
      
      if (tierIndex > 0) allowedTiers.push(TIER_THRESHOLDS[tierIndex - 1].tier);
      if (tierIndex < TIER_THRESHOLDS.length - 1) allowedTiers.push(TIER_THRESHOLDS[tierIndex + 1].tier);
      
      // Get candidates
      const candidates = rankings.filter(r => {
        const rank = r.rank;
        const notSelf = r.fighter_id !== fighter.user_id;
        const tierMatch = allowedTiers.includes(r.tier);
        const rankInRange = rank >= minRank && rank <= maxRank;
        
        return notSelf && tierMatch && rankInRange;
      });
      
      if (candidates.length === 0) {
        return null;
      }
      
      // Get fighter profiles
      const candidateIds = candidates.map(c => c.fighter_id);
      const { data: candidateProfiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .in('user_id', candidateIds);
      
      if (profilesError || !candidateProfiles || candidateProfiles.length === 0) {
        return null;
      }
      
      // Get recent sparring partners to avoid (can be same as recent opponents)
      const recentOpponents = await this.getRecentOpponents(fighterId);
      
      // Score candidates (sparring is more about practice, so points matter less)
      const scoredCandidates = candidateProfiles
        .filter(p => !recentOpponents.includes(p.name))
        .map(candidate => {
          const candidateRank = rankings.find(r => r.fighter_id === candidate.user_id);
          const rankDiff = candidateRank ? Math.abs(candidateRank.rank - fighterRankNumber) : 999;
          const tierMatch = candidate.tier === fighterTier;
          
          // Sparring score: prioritize same tier, then rank proximity
          let score = rankDiff * 5; // Less weight on rank for sparring
          if (!tierMatch) score += 20; // Smaller penalty for different tier
          
          return {
            candidate,
            score,
            rankDiff,
            tierMatch
          };
        })
        .sort((a, b) => a.score - b.score);
      
      if (scoredCandidates.length === 0) {
        return null;
      }
      
      // Return best match
      const bestMatch = scoredCandidates[0].candidate;
      const bestMatchRank = rankings.find(r => r.fighter_id === bestMatch.user_id);
      
      return this.calculateCompatibilityScore(fighter, bestMatch, {
        weight_class: weightClass,
        min_rank: bestMatchRank ? bestMatchRank.rank - 3 : undefined,
        max_rank: bestMatchRank ? bestMatchRank.rank + 3 : undefined,
      });
      
    } catch (error) {
      console.error('Error auto-assigning sparring partner:', error);
      return null;
    }
  }

  // Get matchmaking statistics
  async getMatchmakingStats(): Promise<{
    total_requests: number;
    accepted_requests: number;
    declined_requests: number;
    expired_requests: number;
    average_response_time: number;
  }> {
    const { data, error } = await supabase
      .from('matchmaking_requests')
      .select('status, created_at, updated_at');

    if (error) throw error;

    const stats = {
      total_requests: data.length,
      accepted_requests: data.filter(r => r.status === 'Accepted').length,
      declined_requests: data.filter(r => r.status === 'Declined').length,
      expired_requests: data.filter(r => r.status === 'Expired').length,
      average_response_time: 0
    };

    // Calculate average response time for accepted requests
    const acceptedRequests = data.filter(r => r.status === 'Accepted');
    if (acceptedRequests.length > 0) {
      const totalResponseTime = acceptedRequests.reduce((sum, request) => {
        const responseTime = new Date(request.updated_at).getTime() - new Date(request.created_at).getTime();
        return sum + responseTime;
      }, 0);
      
      stats.average_response_time = totalResponseTime / acceptedRequests.length / (1000 * 60 * 60); // Convert to hours
    }

    return stats;
  }
}

export const matchmakingService = new MatchmakingService();
export {};