import { supabase, TABLES } from './supabase';
import { filterAdminFighters } from '../utils/filterAdmins';

export interface FighterAnalytics {
  fighter_id: string;
  name: string;
  weight_class: string;
  tier: string;
  rank: number;
  points: number;
  wins: number;
  losses: number;
  draws: number;
  total_matches: number;
  knockouts: number;
  win_percentage: number;
  ko_percentage: number;
  consecutive_losses: number;
  average_points_per_match: number;
  rank_by_weight_class: number;
  rank_by_tier: number;
  rank_overall: number;
}

export interface LeagueAnalytics {
  total_fighters: number;
  active_fighters: number;
  inactive_fighters: number;
  fighters_by_weight_class: { [weightClass: string]: number };
  fighters_by_tier: { [tier: string]: number };
  average_points: number;
  average_points_by_weight_class: { [weightClass: string]: number };
  average_points_by_tier: { [tier: string]: number };
  total_matches: number;
  total_knockouts: number;
  fighters_with_four_consecutive_losses: FighterAnalytics[];
  top_fighters: FighterAnalytics[];
}

export class AnalyticsService {
  // Get fighter analytics for a specific fighter
  static async getFighterAnalytics(fighterId: string): Promise<FighterAnalytics | null> {
    try {
      // Get fighter profile - fighterId could be either id or user_id
      const { data: fighter, error: fighterError } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('*')
        .eq('id', fighterId)
        .single();

      if (fighterError || !fighter) {
        // Try with user_id if id lookup failed
        const { data: fighterByUserId, error: fighterByUserIdError } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('*')
          .eq('user_id', fighterId)
          .single();

        if (fighterByUserIdError || !fighterByUserId) {
          console.error('Error fetching fighter:', fighterError || fighterByUserIdError);
          return null;
        }
        
        // Use the fighter found by user_id
        const fighterProfile = fighterByUserId;
        const userIdForRecords = fighterProfile.user_id;

        // Get fight records - use user_id as fighter_id in fight_records
        const { data: fightRecords, error: recordsError } = await supabase
          .from(TABLES.FIGHT_RECORDS)
          .select('*')
          .eq('fighter_id', userIdForRecords)
          .order('date', { ascending: false })
          .order('created_at', { ascending: false });

        if (recordsError) {
          console.error('Error fetching fight records:', recordsError);
        }

        const records = fightRecords || [];
        const totalMatches = records.length;
        
        // Calculate consecutive losses
        let consecutiveLosses = 0;
        for (const record of records) {
          if (record.result === 'Loss') {
            consecutiveLosses++;
          } else {
            break;
          }
        }

        // Calculate average points per match
        const totalPointsEarned = records.reduce((sum, r) => sum + (r.points_earned || 0), 0);
        const avgPointsPerMatch = totalMatches > 0 ? totalPointsEarned / totalMatches : 0;

        // Get rankings
        let rankByWeightClass = 0;
        let rankByTier = 0;
        let rankOverall = 0;

        try {
          // Calculate ranks from fighter_profiles (exclude admin accounts)
          const { data: allFighters } = await supabase
            .from(TABLES.FIGHTER_PROFILES)
            .select('id, user_id, points, weight_class, tier')
            .order('points', { ascending: false });

          if (allFighters) {
            // Filter out admin accounts
            const filteredFighters = await filterAdminFighters(allFighters);
            const sortedByPoints = [...filteredFighters].sort((a, b) => (b.points || 0) - (a.points || 0));
            // Find rank by comparing the id (primary key) of the fighter profile
            rankOverall = sortedByPoints.findIndex(f => f.id === fighterProfile.id) + 1;
            if (rankOverall === 0) rankOverall = sortedByPoints.length; // If not found, use last position

            const wcFighters = sortedByPoints.filter(f => f.weight_class === fighterProfile.weight_class);
            rankByWeightClass = wcFighters.findIndex(f => f.id === fighterProfile.id) + 1;
            if (rankByWeightClass === 0) rankByWeightClass = wcFighters.length;

            const tierFighters = sortedByPoints.filter(f => f.tier === fighterProfile.tier);
            rankByTier = tierFighters.findIndex(f => f.id === fighterProfile.id) + 1;
            if (rankByTier === 0) rankByTier = tierFighters.length;
          }
        } catch (error) {
          console.warn('Error calculating rankings:', error);
        }

        return {
          fighter_id: fighterProfile.id,
          name: fighterProfile.name || 'Unknown',
          weight_class: fighterProfile.weight_class || 'Unknown',
          tier: fighterProfile.tier || 'Amateur',
          rank: rankOverall,
          points: fighterProfile.points || 0,
          wins: fighterProfile.wins || 0,
          losses: fighterProfile.losses || 0,
          draws: fighterProfile.draws || 0,
          total_matches: totalMatches,
          knockouts: fighterProfile.knockouts || 0,
          win_percentage: fighterProfile.win_percentage || 0,
          ko_percentage: fighterProfile.ko_percentage || 0,
          consecutive_losses: consecutiveLosses,
          average_points_per_match: Math.round(avgPointsPerMatch * 100) / 100,
          rank_by_weight_class: rankByWeightClass || 0,
          rank_by_tier: rankByTier || 0,
          rank_overall: rankOverall || 0,
        };
      }

      // Original code path - fighter found by id
      const fighterProfile = fighter;
      const userIdForRecords = fighterProfile.user_id;

      // Get fight records - use user_id as fighter_id in fight_records
      console.log('Querying fight_records with fighter_id (user_id):', userIdForRecords);
      const { data: fightRecords, error: recordsError } = await supabase
        .from(TABLES.FIGHT_RECORDS)
        .select('*')
        .eq('fighter_id', userIdForRecords)
        .order('date', { ascending: false })
        .order('created_at', { ascending: false });

      if (recordsError) {
        console.error('Error fetching fight records:', recordsError);
      }

      console.log('Found fight records:', fightRecords?.length || 0, 'records');

      const records = fightRecords || [];
      const totalMatches = records.length;
      
      // Calculate consecutive losses
      let consecutiveLosses = 0;
      for (const record of records) {
        if (record.result === 'Loss') {
          consecutiveLosses++;
        } else {
          break;
        }
      }

      // Calculate average points per match
      const totalPointsEarned = records.reduce((sum, r) => sum + (r.points_earned || 0), 0);
      const avgPointsPerMatch = totalMatches > 0 ? totalPointsEarned / totalMatches : 0;

      // Get rankings - use the rankings table if available, otherwise calculate from fighter_profiles
      let rankByWeightClass = 0;
      let rankByTier = 0;
      let rankOverall = 0;

      try {
        // Calculate ranks from fighter_profiles (exclude admin accounts)
        const { data: allFighters } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, user_id, points, weight_class, tier')
          .order('points', { ascending: false });

        if (allFighters && fighter) {
          // Filter out admin accounts
          const filteredFighters = await filterAdminFighters(allFighters);
          const sortedByPoints = [...filteredFighters].sort((a, b) => (b.points || 0) - (a.points || 0));
          // Use fighter.id (which is the primary key found from the query) for comparison
          rankOverall = sortedByPoints.findIndex(f => f.id === fighter.id) + 1;
          if (rankOverall === 0) rankOverall = sortedByPoints.length;

          const wcFighters = sortedByPoints.filter(f => f.weight_class === fighter.weight_class);
          rankByWeightClass = wcFighters.findIndex(f => f.id === fighter.id) + 1;
          if (rankByWeightClass === 0) rankByWeightClass = wcFighters.length;

          const tierFighters = sortedByPoints.filter(f => f.tier === fighter.tier);
          rankByTier = tierFighters.findIndex(f => f.id === fighter.id) + 1;
          if (rankByTier === 0) rankByTier = tierFighters.length;
        }
      } catch (error) {
        console.warn('Error calculating rankings:', error);
      }

      return {
        fighter_id: fighter.id,
        name: fighter.name || 'Unknown',
        weight_class: fighter.weight_class || 'Unknown',
        tier: fighter.tier || 'Amateur',
        rank: rankOverall,
        points: fighter.points || 0,
        wins: fighter.wins || 0,
        losses: fighter.losses || 0,
        draws: fighter.draws || 0,
        total_matches: totalMatches,
        knockouts: fighter.knockouts || 0,
        win_percentage: fighter.win_percentage || 0,
        ko_percentage: fighter.ko_percentage || 0,
        consecutive_losses: consecutiveLosses,
        average_points_per_match: Math.round(avgPointsPerMatch * 100) / 100,
        rank_by_weight_class: rankByWeightClass || 0,
        rank_by_tier: rankByTier || 0,
        rank_overall: rankOverall || 0,
      };
    } catch (error) {
      console.error('Error getting fighter analytics:', error);
      return null;
    }
  }

  // Get league-wide analytics
  static async getLeagueAnalytics(): Promise<LeagueAnalytics> {
    try {
      // Get all fighters (exclude admin accounts)
      const { data: fighters, error: fightersError } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('*');

      if (fightersError) {
        throw fightersError;
      }

      // Filter out admin accounts
      const allFighters = await filterAdminFighters(fighters || []);

      // Calculate basic stats
      const totalFighters = allFighters.length;
      
      // Active fighters: those who have fought in the last 90 days or have a scheduled fight
      const activeFighterIds = new Set<string>();
      const ninetyDaysAgo = new Date();
      ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

      const { data: recentFights } = await supabase
        .from(TABLES.FIGHT_RECORDS)
        .select('fighter_id')
        .gte('date', ninetyDaysAgo.toISOString().split('T')[0]);

      // Map user_ids from fight_records to fighter profile ids
      if (recentFights) {
        const userIds = Array.from(new Set(recentFights.map(f => f.fighter_id)));
        const { data: fightersByUserId } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, user_id')
          .in('user_id', userIds);
        
        fightersByUserId?.forEach(f => activeFighterIds.add(f.id));
      }

      const { data: scheduledFights } = await supabase
        .from(TABLES.SCHEDULED_FIGHTS)
        .select('fighter1_id, fighter2_id')
        .eq('status', 'scheduled');

      // scheduled_fights might use fighter_profile.id, so add them directly
      scheduledFights?.forEach(f => {
        if (f.fighter1_id) activeFighterIds.add(f.fighter1_id);
        if (f.fighter2_id) activeFighterIds.add(f.fighter2_id);
      });

      const activeFighters = allFighters.filter(f => activeFighterIds.has(f.id)).length;
      const inactiveFighters = totalFighters - activeFighters;

      // Count by weight class
      const fightersByWeightClass: { [key: string]: number } = {};
      allFighters.forEach(f => {
        const wc = f.weight_class || 'Unknown';
        fightersByWeightClass[wc] = (fightersByWeightClass[wc] || 0) + 1;
      });

      // Count by tier
      const fightersByTier: { [key: string]: number } = {};
      allFighters.forEach(f => {
        const tier = f.tier || 'Amateur';
        fightersByTier[tier] = (fightersByTier[tier] || 0) + 1;
      });

      // Calculate averages
      const totalPoints = allFighters.reduce((sum, f) => sum + (f.points || 0), 0);
      const averagePoints = totalFighters > 0 ? totalPoints / totalFighters : 0;

      // Average by weight class
      const averagePointsByWeightClass: { [key: string]: number } = {};
      Object.keys(fightersByWeightClass).forEach(wc => {
        const wcFighters = allFighters.filter(f => (f.weight_class || 'Unknown') === wc);
        const wcPoints = wcFighters.reduce((sum, f) => sum + (f.points || 0), 0);
        averagePointsByWeightClass[wc] = wcFighters.length > 0 
          ? Math.round((wcPoints / wcFighters.length) * 100) / 100 
          : 0;
      });

      // Average by tier
      const averagePointsByTier: { [key: string]: number } = {};
      Object.keys(fightersByTier).forEach(tier => {
        const tierFighters = allFighters.filter(f => (f.tier || 'Amateur') === tier);
        const tierPoints = tierFighters.reduce((sum, f) => sum + (f.points || 0), 0);
        averagePointsByTier[tier] = tierFighters.length > 0 
          ? Math.round((tierPoints / tierFighters.length) * 100) / 100 
          : 0;
      });

      // Get total matches and KOs
      const { data: allFightRecords } = await supabase
        .from(TABLES.FIGHT_RECORDS)
        .select('*');

      const totalMatches = allFightRecords?.length || 0;
      const totalKnockouts = allFightRecords?.filter(r => 
        r.method === 'KO' || r.method === 'TKO'
      ).length || 0;

      // Find fighters with 3+ consecutive losses (warning indicator)
      const fightersWithThreePlusLosses: FighterAnalytics[] = [];
      for (const fighter of allFighters) {
        const { data: recentRecords } = await supabase
          .from(TABLES.FIGHT_RECORDS)
          .select('result')
          .eq('fighter_id', fighter.id)
          .order('date', { ascending: false })
          .order('created_at', { ascending: false })
          .limit(5); // Check up to 5 to catch 5+ consecutive losses

        if (recentRecords && recentRecords.length >= 3) {
          // Count consecutive losses from most recent
          let consecutiveLosses = 0;
          for (const record of recentRecords) {
            if (record.result === 'Loss') {
              consecutiveLosses++;
            } else {
              break; // Stop counting if we hit a non-loss
            }
          }
          
          // Include fighters with 3+ consecutive losses
          if (consecutiveLosses >= 3) {
            const analytics = await this.getFighterAnalytics(fighter.id);
            if (analytics) {
              fightersWithThreePlusLosses.push(analytics);
            }
          }
        }
      }

      // Get top fighters
      const sortedFighters = [...allFighters].sort((a, b) => (b.points || 0) - (a.points || 0));
      const topFightersData = await Promise.all(
        sortedFighters.slice(0, 10).map(f => this.getFighterAnalytics(f.id))
      );
      const topFighters = topFightersData.filter(f => f !== null) as FighterAnalytics[];

      return {
        total_fighters: totalFighters,
        active_fighters: activeFighters,
        inactive_fighters: inactiveFighters,
        fighters_by_weight_class: fightersByWeightClass,
        fighters_by_tier: fightersByTier,
        average_points: Math.round(averagePoints * 100) / 100,
        average_points_by_weight_class: averagePointsByWeightClass,
        average_points_by_tier: averagePointsByTier,
        total_matches: totalMatches,
        total_knockouts: totalKnockouts,
        fighters_with_four_consecutive_losses: fightersWithThreePlusLosses, // Note: Field name kept for compatibility, but checks 3+
        top_fighters: topFighters,
      };
    } catch (error) {
      console.error('Error getting league analytics:', error);
      return {
        total_fighters: 0,
        active_fighters: 0,
        inactive_fighters: 0,
        fighters_by_weight_class: {},
        fighters_by_tier: {},
        average_points: 0,
        average_points_by_weight_class: {},
        average_points_by_tier: {},
        total_matches: 0,
        total_knockouts: 0,
        fighters_with_four_consecutive_losses: [],
        top_fighters: [],
      };
    }
  }

  // Get analytics for all fighters (admin use - but still exclude admin accounts)
  static async getAllFightersAnalytics(): Promise<FighterAnalytics[]> {
    try {
      const { data: fighters, error } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, user_id');

      if (error) throw error;

      // Filter out admin accounts
      const filteredFighters = await filterAdminFighters(fighters || []);

      const analytics = await Promise.all(
        filteredFighters.map(f => this.getFighterAnalytics(f.id))
      );

      return analytics.filter(a => a !== null) as FighterAnalytics[];
    } catch (error) {
      console.error('Error getting all fighters analytics:', error);
      return [];
    }
  }
}
