import { supabase } from './supabase';
import { getOverallRankings, getRankingsByWeightClass } from './rankingsService';
import { filterAdminFighters } from '../utils/filterAdmins';
import { schedulingService } from './schedulingService';

export interface AutoMatchResult {
  fight_id: string;
  fighter1_id: string;
  fighter2_id: string;
  match_score: number;
  reasons: string[];
}

export interface FairMatchCriteria {
  max_rank_difference: number; // Maximum rank difference (default: 3) - Rank window (±N positions)
  max_points_difference: number; // Maximum points difference (default: 30) - MMR-like guardrail
  same_tier_required: boolean; // Must be same tier (REQUIRED, not just preferred)
  same_weight_class_required: boolean; // Must be same weight class (REQUIRED)
  avoid_recent_opponents_count: number; // Avoid repeat within last X matches (default: 5)
  require_timezone_overlap: boolean; // Require timezone overlap (default: false, preferred but not required)
  require_availability_window: boolean; // Require availability window match (default: false)
  points_gap_consent_threshold: number; // Points gap requiring consent (default: 50)
}

class SmartMatchmakingService {
  // Automatically match fighters based on rankings, weight class, tier, points, demotion status, and timezone
  // 
  // ⚠️ STRICT MATCHING REQUIREMENTS - FIGHTERS WILL NOT BE MATCHED IF ANY REQUIREMENT IS NOT MET:
  // 
  // 1. ✅ Same weight class (REQUIRED) - Fighters with different weight classes will NEVER be matched
  // 2. ✅ Same tier (REQUIRED) - Fighters with different tiers will NEVER be matched
  // 3. ✅ Rankings within max_rank_difference (default: 3) - Rank difference > 3 will REJECT the match
  // 4. ✅ Points within max_points_difference (default: 30) - Points difference > 30 will REJECT the match
  // 5. ✅ Compatible timezones (REQUIRED) - Fighters with incompatible timezones (>4 hours difference) will NEVER be matched
  // 6. ✅ Demotion status - Recently demoted fighters (within 30 days) are preferred to match with each other
  // 
  // The algorithm:
  // - Groups fighters by weight class first
  // - Then groups by tier within each weight class
  // - Only compares fighters within the same weight class AND tier
  // - Validates rankings, points, timezone compatibility, and demotion status before matching
  // - Uses fighter's actual timezone from their profile physical information section
  // - Performs final validation before creating scheduled fights
  async autoMatchFighters(
    criteria?: Partial<FairMatchCriteria>
  ): Promise<AutoMatchResult[]> {
    const matchCriteria: FairMatchCriteria = {
      max_rank_difference: criteria?.max_rank_difference || 3, // Rank window (±N positions)
      max_points_difference: criteria?.max_points_difference || 30, // MMR-like guardrail
      same_tier_required: criteria?.same_tier_required ?? true, // REQUIRED by default
      same_weight_class_required: criteria?.same_weight_class_required ?? true, // REQUIRED by default
      avoid_recent_opponents_count: criteria?.avoid_recent_opponents_count || 5, // Avoid repeat within last X matches
      require_timezone_overlap: criteria?.require_timezone_overlap ?? true, // REQUIRED by default - fighters must have compatible timezones
      require_availability_window: criteria?.require_availability_window ?? false, // Preferred but not required by default
      points_gap_consent_threshold: criteria?.points_gap_consent_threshold || 50, // >50 pts gap requires consent
    };

    try {
      // Get all fighters (excluding admins) - include timezone for overlap checking
      const { data: allFighters, error: fightersError } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, weight_class, tier, points, wins, losses, draws, timezone')
        .not('user_id', 'is', null);

      if (fightersError || !allFighters) {
        throw new Error('Failed to fetch fighters');
      }

      // Filter out admin accounts
      const fighters = await filterAdminFighters(allFighters);

      // Get rankings for each weight class
      const weightClasses = Array.from(new Set(fighters.map(f => f.weight_class)));
      const matches: AutoMatchResult[] = [];
      const matchedFighterIds = new Set<string>();

      for (const weightClass of weightClasses) {
        // Get rankings for this weight class
        const rankings = await getRankingsByWeightClass(weightClass, 100);
        
        // Get fighters in this weight class
        const weightClassFighters = fighters.filter(f => f.weight_class === weightClass);
        
        // Group fighters by tier within this weight class
        const fightersByTier = new Map<string, typeof weightClassFighters>();
        for (const fighter of weightClassFighters) {
          const tier = fighter.tier || 'Amateur';
          if (!fightersByTier.has(tier)) {
            fightersByTier.set(tier, []);
          }
          fightersByTier.get(tier)!.push(fighter);
        }
        
        // Match fighters within each tier
        for (const [tier, tierFighters] of Array.from(fightersByTier.entries())) {
          // Create pairs of fighters within the same tier
          for (let i = 0; i < tierFighters.length; i++) {
            const fighter1 = tierFighters[i];
            
            // Skip if already matched
            if (matchedFighterIds.has(fighter1.id)) continue;

            // Find best match for fighter1 (only within same tier)
            let bestMatch: typeof fighter1 | null = null;
            let bestScore = 0;
            let bestReasons: string[] = [];

            for (let j = i + 1; j < tierFighters.length; j++) {
              const fighter2 = tierFighters[j];
              
              // Skip if already matched
              if (matchedFighterIds.has(fighter2.id)) continue;

              // STRICT CHECK: Ensure same tier (should already be true, but double-check)
              if (fighter1.tier !== fighter2.tier) {
                console.warn(`Tier mismatch detected: ${fighter1.tier} vs ${fighter2.tier}. Skipping match.`);
                continue;
              }

              // STRICT CHECK: Ensure same weight class (should already be true, but double-check)
              if (fighter1.weight_class !== fighter2.weight_class) {
                console.warn(`Weight class mismatch detected: ${fighter1.weight_class} vs ${fighter2.weight_class}. Skipping match.`);
                continue;
              }

              // Check if fighters already have a scheduled fight
              const hasExistingFight = await this.hasScheduledFight(fighter1.id, fighter2.id);
              if (hasExistingFight) continue;

              // Check if fighters have fought recently (avoid repeat within last X matches)
              const hasRecentFight = await this.hasRecentFight(fighter1.user_id, fighter2.user_id, matchCriteria.avoid_recent_opponents_count);
              if (hasRecentFight) continue;

              // REQUIRED: Check timezone overlap - fighters must have compatible timezones
              if (matchCriteria.require_timezone_overlap) {
                const timezoneCompatible = this.checkTimezoneOverlap(fighter1.timezone, fighter2.timezone);
                if (!timezoneCompatible) {
                  continue; // Skip if timezone overlap is required but not present
                }
              } else {
                // Even if not explicitly required, prefer timezone compatibility
                const timezoneCompatible = this.checkTimezoneOverlap(fighter1.timezone, fighter2.timezone);
                if (!timezoneCompatible) {
                  continue; // Skip fighters with incompatible timezones
                }
              }
              
              // Check if either fighter was recently demoted (prefer matching demoted fighters together)
              const fighter1RecentlyDemoted = await this.wasRecentlyDemoted(fighter1.user_id);
              const fighter2RecentlyDemoted = await this.wasRecentlyDemoted(fighter2.user_id);
              
              // If one fighter was demoted and the other wasn't, prefer matching demoted fighters together
              // This helps demoted fighters get fair matches at their new tier
              if (fighter1RecentlyDemoted && !fighter2RecentlyDemoted) {
                continue; // Prefer matching demoted fighters with other demoted fighters
              }
              if (fighter2RecentlyDemoted && !fighter1RecentlyDemoted) {
                continue; // Prefer matching demoted fighters with other demoted fighters
              }

              // Calculate match score (now async to check demotion status)
              const matchResult = await this.calculateFairMatchScore(
                fighter1,
                fighter2,
                rankings,
                matchCriteria
              );

              // Check fairness rules: >50 pts gap requires consent (warn but don't block)
              const pointsDiff = Math.abs(fighter1.points - fighter2.points);
              if (pointsDiff > matchCriteria.points_gap_consent_threshold) {
                matchResult.reasons.push(`⚠️ Large points gap (${pointsDiff} pts) - Admin consent recommended`);
                // Still allow match but flag it
              }

              if (matchResult.isFair && matchResult.score > bestScore) {
                bestMatch = fighter2;
                bestScore = matchResult.score;
                bestReasons = matchResult.reasons;
              }
            }

            // If we found a fair match, create the scheduled fight
            if (bestMatch && bestScore >= 60) { // Minimum 60% compatibility
              // FINAL VALIDATION: Ensure all requirements are met before creating scheduled fight
              if (fighter1.weight_class !== bestMatch.weight_class) {
                console.error(`[Smart Matchmaking] CRITICAL: Weight class mismatch detected before fight creation - ${fighter1.name} (${fighter1.weight_class}) vs ${bestMatch.name} (${bestMatch.weight_class}). Skipping match.`);
                continue;
              }
              
              if (fighter1.tier !== bestMatch.tier) {
                console.error(`[Smart Matchmaking] CRITICAL: Tier mismatch detected before fight creation - ${fighter1.name} (${fighter1.tier}) vs ${bestMatch.name} (${bestMatch.tier}). Skipping match.`);
                continue;
              }
              
              try {
                // Use fighter's actual timezone from profile (prefer fighter1's timezone, fallback to fighter2's, then UTC)
                const fighterTimezone = fighter1.timezone || bestMatch.timezone || 'UTC';
                const fighterPlatform = (fighter1 as any).platform || (bestMatch as any).platform || 'PC';
                
                console.log(`[Smart Matchmaking] Creating match: ${fighter1.name} (${fighter1.weight_class}, ${fighter1.tier}, TZ: ${fighterTimezone}) vs ${bestMatch.name} (${bestMatch.weight_class}, ${bestMatch.tier}, TZ: ${bestMatch.timezone || 'UTC'}) - Score: ${bestScore}%`);
                
                const scheduledFight = await schedulingService.scheduleFight({
                  fighter1_id: fighter1.id,
                  fighter2_id: bestMatch.id,
                  weight_class: weightClass,
                  scheduled_date: this.getNextAvailableDate(fighterTimezone).toISOString(),
                  timezone: fighterTimezone,
                  platform: fighterPlatform,
                  connection_notes: 'Auto-matched via Smart Matchmaking based on Rankings, Tier, Weight Class, Points, Demotion status, and Timezone. Must be completed within 1 week.',
                  house_rules: 'Standard boxing rules apply. Fight must be completed within 7 days of scheduling.'
                }, {
                  isAutoMatched: true,
                  matchType: 'auto_mandatory',
                  matchScore: bestScore
                });

                // The match_type and match_score are already set by the function, but update if needed
                if (scheduledFight.id) {
                  await supabase
                    .from('scheduled_fights')
                    .update({
                      match_type: 'auto_mandatory',
                      auto_matched_at: new Date().toISOString(),
                      match_score: bestScore
                    })
                    .eq('id', scheduledFight.id);
                }

                matches.push({
                  fight_id: scheduledFight.id,
                  fighter1_id: fighter1.id,
                  fighter2_id: bestMatch.id,
                  match_score: bestScore,
                  reasons: bestReasons
                });

                // Mark both fighters as matched
                matchedFighterIds.add(fighter1.id);
                matchedFighterIds.add(bestMatch.id);
              } catch (error) {
                console.error(`Error creating scheduled fight for ${fighter1.name} vs ${bestMatch.name}:`, error);
              }
            }
          }
        }
      }

      return matches;
    } catch (error) {
      console.error('Error in autoMatchFighters:', error);
      throw error;
    }
  }

  // Calculate fair match score between two fighters
  // 
  // ⚠️ STRICT REQUIREMENTS - FIGHTERS WILL NOT BE MATCHED IF ANY REQUIREMENT IS NOT MET:
  // 
  // 1. ✅ Same weight class (REQUIRED) - Fighters with different weight classes will NEVER be matched
  // 2. ✅ Same tier (REQUIRED) - Fighters with different tiers will NEVER be matched  
  // 3. ✅ Rankings within max_rank_difference (default: 3) - Rank difference > 3 will REJECT the match
  // 4. ✅ Points within max_points_difference (default: 30) - Points difference > 30 will REJECT the match
  // 5. ✅ Timezone compatibility (REQUIRED) - Fighters with incompatible timezones will NEVER be matched
  // 6. ✅ Demotion status - Recently demoted fighters are preferred to match with each other
  // 
  // If ANY of these requirements are not met, the function returns isFair: false and score: 0
  // Only fighters meeting ALL requirements will be considered for matching
  private async calculateFairMatchScore(
    fighter1: any,
    fighter2: any,
    rankings: any[],
    criteria: FairMatchCriteria
  ): Promise<{ isFair: boolean; score: number; reasons: string[] }> {
    const reasons: string[] = [];
    let score = 100;

    // STRICT CHECK #1: Weight class must match (REQUIRED - checked first)
    // FIGHTERS WITH DIFFERENT WEIGHT CLASSES WILL NEVER BE MATCHED
    if (criteria.same_weight_class_required) {
      if (fighter1.weight_class !== fighter2.weight_class) {
        console.warn(`[Smart Matchmaking] REJECTED: Different weight classes - ${fighter1.name} (${fighter1.weight_class}) vs ${fighter2.name} (${fighter2.weight_class})`);
        return { 
          isFair: false, 
          score: 0, 
          reasons: [`REQUIRED: Same weight class. ${fighter1.weight_class} ≠ ${fighter2.weight_class}. Fighters with different weight classes will NEVER be matched.`] 
        };
      }
      reasons.push(`✓ Same weight class: ${fighter1.weight_class}`);
    } else {
      // Even if not required in criteria, we still enforce it
      if (fighter1.weight_class !== fighter2.weight_class) {
        console.warn(`[Smart Matchmaking] REJECTED: Different weight classes - ${fighter1.name} (${fighter1.weight_class}) vs ${fighter2.name} (${fighter2.weight_class})`);
        return { 
          isFair: false, 
          score: 0, 
          reasons: [`REQUIRED: Same weight class. ${fighter1.weight_class} ≠ ${fighter2.weight_class}`] 
        };
      }
    }

    // STRICT CHECK #2: Tier must match (REQUIRED)
    // FIGHTERS WITH DIFFERENT TIERS WILL NEVER BE MATCHED
    if (criteria.same_tier_required) {
      if (fighter1.tier !== fighter2.tier) {
        console.warn(`[Smart Matchmaking] REJECTED: Different tiers - ${fighter1.name} (${fighter1.tier}) vs ${fighter2.name} (${fighter2.tier})`);
        return { 
          isFair: false, 
          score: 0, 
          reasons: [`REQUIRED: Same tier. ${fighter1.tier} ≠ ${fighter2.tier}. Fighters with different tiers will NEVER be matched.`] 
        };
      }
      score += 10; // Bonus for same tier
      reasons.push(`✓ Same tier: ${fighter1.tier}`);
    } else {
      // Even if not required in criteria, we still enforce it
      if (fighter1.tier !== fighter2.tier) {
        console.warn(`[Smart Matchmaking] REJECTED: Different tiers - ${fighter1.name} (${fighter1.tier}) vs ${fighter2.name} (${fighter2.tier})`);
        return { 
          isFair: false, 
          score: 0, 
          reasons: [`REQUIRED: Same tier. ${fighter1.tier} ≠ ${fighter2.tier}`] 
        };
      }
    }

    // Get rankings
    const fighter1Rank = rankings.find(r => r.fighter_id === fighter1.user_id);
    const fighter2Rank = rankings.find(r => r.fighter_id === fighter2.user_id);

    if (!fighter1Rank || !fighter2Rank) {
      console.warn(`[Smart Matchmaking] REJECTED: Fighter not found in rankings - ${fighter1.name} or ${fighter2.name}`);
      return { isFair: false, score: 0, reasons: ['Fighter not found in rankings'] };
    }

    // STRICT CHECK #3: Rankings must be within max_rank_difference (default: 3)
    const rankDiff = Math.abs(fighter1Rank.rank - fighter2Rank.rank);
    if (rankDiff > criteria.max_rank_difference) {
      console.warn(`[Smart Matchmaking] REJECTED: Rank difference too large - ${fighter1.name} (rank ${fighter1Rank.rank}) vs ${fighter2.name} (rank ${fighter2Rank.rank}), difference: ${rankDiff} (max: ${criteria.max_rank_difference})`);
      return { 
        isFair: false, 
        score: 0, 
        reasons: [`Rank difference too large: ${rankDiff} (max allowed: ${criteria.max_rank_difference})`] 
      };
    }
    
    const rankPenalty = rankDiff * 5; // 5 points per rank difference
    score -= rankPenalty;
    if (rankDiff > 0) {
      reasons.push(`Rank difference: ${rankDiff}`);
    } else {
      reasons.push(`✓ Same rank: ${fighter1Rank.rank}`);
    }

    // STRICT CHECK #4: Points must be within max_points_difference (default: 30)
    const pointsDiff = Math.abs(fighter1.points - fighter2.points);
    if (pointsDiff > criteria.max_points_difference) {
      console.warn(`[Smart Matchmaking] REJECTED: Points difference too large - ${fighter1.name} (${fighter1.points} pts) vs ${fighter2.name} (${fighter2.points} pts), difference: ${pointsDiff} (max: ${criteria.max_points_difference})`);
      return { 
        isFair: false, 
        score: 0, 
        reasons: [`Points difference too large: ${pointsDiff} (max allowed: ${criteria.max_points_difference})`] 
      };
    }
    
    const pointsPenalty = pointsDiff / 2; // 0.5 points per point difference
    score -= pointsPenalty;
    if (pointsDiff > 0) {
      reasons.push(`Points difference: ${pointsDiff}`);
    } else {
      reasons.push(`✓ Same points: ${fighter1.points}`);
    }

    // STRICT CHECK #5: Timezone compatibility (REQUIRED)
    if (criteria.require_timezone_overlap) {
      const timezoneCompatible = this.checkTimezoneOverlap(fighter1.timezone, fighter2.timezone);
      if (!timezoneCompatible) {
        console.warn(`[Smart Matchmaking] REJECTED: Incompatible timezones - ${fighter1.name} (${fighter1.timezone || 'not set'}) vs ${fighter2.name} (${fighter2.timezone || 'not set'})`);
        return { 
          isFair: false, 
          score: 0, 
          reasons: [`REQUIRED: Compatible timezones. ${fighter1.timezone || 'not set'} vs ${fighter2.timezone || 'not set'}. Fighters with incompatible timezones will NEVER be matched.`] 
        };
      }
      score += 10; // Bonus for timezone compatibility
      reasons.push(`✓ Compatible timezones: ${fighter1.timezone || 'UTC'} & ${fighter2.timezone || 'UTC'}`);
    }

    // BONUS: Check if both fighters were recently demoted (prefer matching demoted fighters together)
    const fighter1RecentlyDemoted = await this.wasRecentlyDemoted(fighter1.user_id);
    const fighter2RecentlyDemoted = await this.wasRecentlyDemoted(fighter2.user_id);
    
    if (fighter1RecentlyDemoted && fighter2RecentlyDemoted) {
      score += 15; // Bonus for matching recently demoted fighters together
      reasons.push(`✓ Both fighters recently demoted - fair match at new tier`);
    } else if (fighter1RecentlyDemoted || fighter2RecentlyDemoted) {
      // One fighter demoted, one not - slight penalty but still allow if other criteria met
      score -= 5;
      reasons.push(`⚠️ One fighter recently demoted - may affect match fairness`);
    }

    // Ensure score is within bounds
    score = Math.max(0, Math.min(100, score));

    const isFair = score >= 60; // Minimum 60% for fair match
    
    if (isFair) {
      console.log(`[Smart Matchmaking] ✓ FAIR MATCH: ${fighter1.name} vs ${fighter2.name} - Score: ${Math.round(score)}%`, reasons);
    }

    return {
      isFair,
      score: Math.round(score),
      reasons
    };
  }
  
  // Check if a fighter was recently demoted (within last 30 days)
  private async wasRecentlyDemoted(fighterUserId: string): Promise<boolean> {
    try {
      // Get fighter profile ID
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return false;
      }

      // Check tier_history for recent demotion (last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const { data: tierHistory, error: historyError } = await supabase
        .from('tier_history')
        .select('from_tier, to_tier, created_at')
        .eq('fighter_id', fighter.id)
        .gte('created_at', thirtyDaysAgo.toISOString())
        .order('created_at', { ascending: false })
        .limit(1);

      if (historyError || !tierHistory || tierHistory.length === 0) {
        return false;
      }

      // Check if the most recent tier change was a demotion (to_tier is lower than from_tier)
      const tierOrder = ['Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'];
      const recentChange = tierHistory[0];
      const fromIndex = tierOrder.indexOf(recentChange.from_tier);
      const toIndex = tierOrder.indexOf(recentChange.to_tier);

      // If toIndex < fromIndex, it's a demotion
      return toIndex < fromIndex;
    } catch (error) {
      console.error('Error checking demotion status:', error);
      return false;
    }
  }

  // Check if two fighters already have a scheduled fight
  private async hasScheduledFight(fighter1Id: string, fighter2Id: string): Promise<boolean> {
    const { data, error } = await supabase
      .from('scheduled_fights')
      .select('id')
      .or(`and(fighter1_id.eq.${fighter1Id},fighter2_id.eq.${fighter2Id}),and(fighter1_id.eq.${fighter2Id},fighter2_id.eq.${fighter1Id})`)
      .eq('status', 'Scheduled')
      .limit(1);

    if (error) {
      console.error('Error checking scheduled fights:', error);
      return false;
    }

    return (data?.length || 0) > 0;
  }

  // Check if two fighters have fought recently (avoid repeat within last X matches)
  private async hasRecentFight(fighter1UserId: string, fighter2UserId: string, avoidCount: number): Promise<boolean> {
    try {
      // Get fighter profile IDs from user_ids
      const { data: fighter1, error: fighter1Error } = await supabase
        .from('fighter_profiles')
        .select('id, name')
        .eq('user_id', fighter1UserId)
        .single();

      const { data: fighter2, error: fighter2Error } = await supabase
        .from('fighter_profiles')
        .select('id, name')
        .eq('user_id', fighter2UserId)
        .single();

      if (fighter1Error || fighter2Error || !fighter1 || !fighter2) {
        return false; // If we can't find fighters, allow match
      }

      // Check fight_records for recent fights between these fighters
      // Check fighter1's records against fighter2's name
      const { data: recentFights1, error: error1 } = await supabase
        .from('fight_records')
        .select('id, date, opponent_name')
        .eq('fighter_id', fighter1.id)
        .eq('opponent_name', fighter2.name)
        .order('date', { ascending: false })
        .limit(avoidCount);

      // Check fighter2's records against fighter1's name
      const { data: recentFights2, error: error2 } = await supabase
        .from('fight_records')
        .select('id, date, opponent_name')
        .eq('fighter_id', fighter2.id)
        .eq('opponent_name', fighter1.name)
        .order('date', { ascending: false })
        .limit(avoidCount);

      if (error1 || error2) {
        console.error('Error checking recent fights:', error1 || error2);
        return false; // If error, allow match
      }

      const totalRecentFights = (recentFights1?.length || 0) + (recentFights2?.length || 0);
      return totalRecentFights >= avoidCount;
    } catch (error) {
      console.error('Error in hasRecentFight:', error);
      return false; // If error, allow match
    }
  }

  // Check timezone overlap (within 4 hours difference)
  private checkTimezoneOverlap(timezone1: string, timezone2: string): boolean {
    if (!timezone1 || !timezone2) return true; // If timezone not set, allow match

    // Simple timezone offset mapping (can be enhanced with proper timezone library)
    const timezoneOffsets: { [key: string]: number } = {
      'UTC': 0,
      'GMT': 0,
      'EST': -5,
      'EDT': -4,
      'PST': -8,
      'PDT': -7,
      'CST': -6,
      'CDT': -5,
      'MST': -7,
      'MDT': -6,
      'CET': 1,
      'CEST': 2,
      'JST': 9,
      'AEST': 10,
      'AEDT': 11,
      'BST': 1,
      'IST': 5.5,
    };

    // Try to extract offset from timezone string
    const getOffset = (tz: string): number => {
      // Check exact match first
      if (timezoneOffsets[tz]) {
        return timezoneOffsets[tz];
      }

      // Try to parse timezone strings like "America/New_York" or "UTC+5"
      const tzUpper = tz.toUpperCase();
      
      // Check for UTC offset format (UTC+5, UTC-3, etc.)
      const utcMatch = tzUpper.match(/UTC([+-]?\d+)/);
      if (utcMatch) {
        return parseInt(utcMatch[1], 10);
      }

      // Check for common timezone names
      for (const [key, offset] of Object.entries(timezoneOffsets)) {
        if (tzUpper.includes(key)) {
          return offset;
        }
      }

      return 0; // Default to UTC if unknown
    };

    const offset1 = getOffset(timezone1);
    const offset2 = getOffset(timezone2);
    const diff = Math.abs(offset1 - offset2);

    // Consider compatible if within 4 hours
    return diff <= 4;
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

  // Get mandatory fights for a fighter (auto-matched fights)
  async getMandatoryFights(fighterUserId: string): Promise<any[]> {
    try {
      // Get fighter profile ID
      const { data: fighter, error: fighterError } = await supabase
        .from('fighter_profiles')
        .select('id, user_id')
        .eq('user_id', fighterUserId)
        .single();

      if (fighterError || !fighter) {
        return [];
      }

      // Query scheduled_fights separately to avoid foreign key relationship issues
      const { data: fights, error: fightsError } = await supabase
        .from('scheduled_fights')
        .select('*')
        .or(`fighter1_id.eq.${fighter.id},fighter2_id.eq.${fighter.id}`)
        .eq('status', 'Scheduled')
        .eq('match_type', 'auto_mandatory')
        .order('scheduled_date', { ascending: true });

      if (fightsError) {
        console.error('Error fetching mandatory fights:', fightsError);
        return [];
      }

      if (!fights || fights.length === 0) {
        return [];
      }

      // Get fighter IDs
      const fighter1Ids = Array.from(new Set(fights.map(f => f.fighter1_id).filter(Boolean)));
      const fighter2Ids = Array.from(new Set(fights.map(f => f.fighter2_id).filter(Boolean)));
      const allFighterIds = Array.from(new Set([...fighter1Ids, ...fighter2Ids]));

      // Fetch fighter profiles
      const { data: fighterProfiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, handle, tier, points, weight_class, wins, losses, draws')
        .in('id', allFighterIds);

      if (profilesError) {
        console.error('Error fetching fighter profiles:', profilesError);
        return [];
      }

      // Create a map for quick lookup
      const fighterMap = new Map((fighterProfiles || []).map(f => [f.id, f]));

      // Map to match the format expected by the UI (similar to HomePageService)
      return fights.map(fight => {
        const fighter1Profile = fighterMap.get(fight.fighter1_id);
        const fighter2Profile = fighterMap.get(fight.fighter2_id);
        
        return {
          id: fight.id,
          fighter1_id: fighter1Profile?.user_id,
          fighter2_id: fighter2Profile?.user_id,
          fighter1: fighter1Profile ? {
            id: fighter1Profile.user_id,
            name: fighter1Profile.name || 'Unknown Fighter',
            handle: fighter1Profile.handle || 'unknown',
            tier: fighter1Profile.tier || 'Amateur',
            points: fighter1Profile.points || 0,
            weight_class: fighter1Profile.weight_class || 'Unknown',
            wins: fighter1Profile.wins || 0,
            losses: fighter1Profile.losses || 0,
            draws: fighter1Profile.draws || 0
          } : undefined,
          fighter2: fighter2Profile ? {
            id: fighter2Profile.user_id,
            name: fighter2Profile.name || 'Unknown Fighter',
            handle: fighter2Profile.handle || 'unknown',
            tier: fighter2Profile.tier || 'Amateur',
            points: fighter2Profile.points || 0,
            weight_class: fighter2Profile.weight_class || 'Unknown',
            wins: fighter2Profile.wins || 0,
            losses: fighter2Profile.losses || 0,
            draws: fighter2Profile.draws || 0
          } : undefined,
          scheduled_date: fight.scheduled_date,
          scheduled_time: (fight as any).scheduled_time || new Date(fight.scheduled_date).toLocaleTimeString(),
          timezone: fight.timezone || 'UTC',
          venue: (fight as any).venue || 'TBD',
          weight_class: fight.weight_class || 'Unknown',
          status: fight.status || 'Scheduled',
          match_type: (fight as any).match_type,
          match_score: (fight as any).match_score
        };
      });
    } catch (error) {
      console.error('Error in getMandatoryFights:', error);
      return [];
    }
  }

  // Weekly reset: Clear old mandatory fights (past their 1-week deadline) and create new matches
  // This should be called weekly to reset the Smart Matchmaking system
  // Fights are considered past deadline if created_at + 7 days < now
  async weeklyReset(): Promise<{ cleared: number; newMatches: number }> {
    try {
      // Get all mandatory fights that are past their 1-week deadline (created_at + 7 days < now)
      const now = new Date();
      const oneWeekAgo = new Date(now);
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
      
      const { data: oldFights, error: oldFightsError } = await supabase
        .from('scheduled_fights')
        .select('id, fighter1_id, fighter2_id, created_at')
        .eq('match_type', 'auto_mandatory')
        .eq('status', 'Scheduled')
        .lt('created_at', oneWeekAgo.toISOString());

      if (oldFightsError) {
        console.error('Error fetching old mandatory fights:', oldFightsError);
        throw oldFightsError;
      }

      const clearedCount = oldFights?.length || 0;

      // Cancel/clear old mandatory fights (mark as Cancelled or delete them)
      if (oldFights && oldFights.length > 0) {
        const oldFightIds = oldFights.map(f => f.id);
        
        // Mark as Cancelled instead of deleting to preserve history
        const { error: updateError } = await supabase
          .from('scheduled_fights')
          .update({ status: 'Cancelled' })
          .in('id', oldFightIds);

        if (updateError) {
          console.error('Error clearing old mandatory fights:', updateError);
          throw updateError;
        }
      }

      // Create new mandatory fights for all fighters
      const newMatches = await this.autoMatchFighters();

      return {
        cleared: clearedCount,
        newMatches: newMatches.length
      };
    } catch (error) {
      console.error('Error in weeklyReset:', error);
      throw error;
    }
  }

  // Check if a scheduled fight is past its 1-week deadline
  async isFightPastDeadline(fightId: string): Promise<boolean> {
    try {
      const { data: fight, error } = await supabase
        .from('scheduled_fights')
        .select('scheduled_date, created_at')
        .eq('id', fightId)
        .maybeSingle();

      if (error || !fight) {
        return false;
      }

      // Use created_at if available, otherwise use scheduled_date
      const fightDate = fight.created_at ? new Date(fight.created_at) : new Date(fight.scheduled_date);
      const oneWeekLater = new Date(fightDate);
      oneWeekLater.setDate(oneWeekLater.getDate() + 7);

      return new Date() > oneWeekLater;
    } catch (error) {
      console.error('Error checking fight deadline:', error);
      return false;
    }
  }

  // Manual override: Admin can force pairings for cards/title fights
  async forcePairing(
    fighter1UserId: string,
    fighter2UserId: string,
    options?: {
      weight_class?: string;
      scheduled_date?: string;
      timezone?: string;
      platform?: string;
      is_title_fight?: boolean;
      admin_notes?: string;
    }
  ): Promise<AutoMatchResult> {
    try {
      // Get fighter profiles
      const { data: fighter1, error: fighter1Error } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, weight_class, tier, points, timezone')
        .eq('user_id', fighter1UserId)
        .single();

      const { data: fighter2, error: fighter2Error } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, weight_class, tier, points, timezone')
        .eq('user_id', fighter2UserId)
        .single();

      if (fighter1Error || fighter2Error || !fighter1 || !fighter2) {
        throw new Error('Fighter profiles not found');
      }

      // Get rankings for match score calculation
      const weightClass = options?.weight_class || fighter1.weight_class || fighter2.weight_class;
      const rankings = await getRankingsByWeightClass(weightClass, 1000);
      
      // Calculate match score (even if forced, we still want to know compatibility)
      const matchCriteria: FairMatchCriteria = {
        max_rank_difference: 999, // No limit for forced matches
        max_points_difference: 999, // No limit for forced matches
        same_tier_required: false, // No requirement for forced matches
        same_weight_class_required: false, // No requirement for forced matches
        avoid_recent_opponents_count: 0, // No avoidance for forced matches
        require_timezone_overlap: false,
        require_availability_window: false,
        points_gap_consent_threshold: 50,
      };

      const matchResult = await this.calculateFairMatchScore(fighter1, fighter2, rankings, matchCriteria);
      
      // Create scheduled fight
      const scheduledDate = options?.scheduled_date 
        ? new Date(options.scheduled_date)
        : this.getNextAvailableDate(options?.timezone || fighter1.timezone || 'UTC');

      const scheduledFight = await schedulingService.scheduleFight({
        fighter1_id: fighter1.id,
        fighter2_id: fighter2.id,
        weight_class: weightClass,
        scheduled_date: scheduledDate.toISOString(),
        timezone: options?.timezone || fighter1.timezone || 'UTC',
        platform: options?.platform || 'PC',
        connection_notes: options?.admin_notes || `Admin-forced pairing${options?.is_title_fight ? ' (Title Fight)' : ''}. Match score: ${matchResult.score}%`,
        house_rules: options?.is_title_fight 
          ? 'Title fight rules apply. Must be completed within 1 week.'
          : 'Standard boxing rules apply. Must be completed within 1 week.'
      });

      // Mark as manual mandatory fight
      await supabase
        .from('scheduled_fights')
        .update({
          match_type: options?.is_title_fight ? 'manual' : 'manual',
          auto_matched_at: new Date().toISOString(),
          match_score: matchResult.score
        })
        .eq('id', scheduledFight.id);

      return {
        fight_id: scheduledFight.id,
        fighter1_id: fighter1.id,
        fighter2_id: fighter2.id,
        match_score: matchResult.score,
        reasons: [
          ...matchResult.reasons,
          'Admin-forced pairing',
          options?.is_title_fight ? 'Title fight' : ''
        ].filter(Boolean)
      };
    } catch (error) {
      console.error('Error in forcePairing:', error);
      throw error;
    }
  }
}

export const smartMatchmakingService = new SmartMatchmakingService();

