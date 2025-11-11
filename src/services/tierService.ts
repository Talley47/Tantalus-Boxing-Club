import { supabase } from './supabase';
import { FighterProfile, Tier, TierHistory } from '../types';
import { filterAdminFighters } from '../utils/filterAdmins';

export interface TierChange {
  fighter_id: string;
  from_tier: string;
  to_tier: string;
  reason: string;
  points_before: number;
  points_after: number;
}

export interface TierStats {
  total_fighters: number;
  tier_distribution: { [tier: string]: number };
  recent_promotions: number;
  recent_demotions: number;
  average_points_per_tier: { [tier: string]: number };
}

class TierService {
  // Get all tiers
  async getTiers(): Promise<Tier[]> {
    const { data, error } = await supabase
      .from('tiers')
      .select('*')
      .order('min_points', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  // Get tier by name
  async getTierByName(tierName: string): Promise<Tier | null> {
    const { data, error } = await supabase
      .from('tiers')
      .select('*')
      .eq('name', tierName)
      .single();

    if (error) return null;
    return data;
  }

  // Get tier for a given point value
  async getTierForPoints(points: number): Promise<Tier | null> {
    const { data, error } = await supabase
      .from('tiers')
      .select('*')
      .lte('min_points', points)
      .or(`max_points.gte.${points},max_points.is.null`)
      .order('min_points', { ascending: false })
      .limit(1)
      .single();

    if (error) return null;
    return data;
  }

  // Check if a fighter should be promoted
  async checkForPromotion(fighterId: string): Promise<TierChange | null> {
    const { data: fighter, error } = await supabase
      .from('fighter_profiles')
      .select('*')
      .eq('id', fighterId)
      .single();

    if (error || !fighter) return null;

    const currentTier = await this.getTierByName(fighter.tier);
    const newTier = await this.getTierForPoints(fighter.points);

    if (!currentTier || !newTier) return null;

    // Check if fighter should be promoted
    if (newTier.min_points > currentTier.min_points) {
      return {
        fighter_id: fighterId,
        from_tier: fighter.tier,
        to_tier: newTier.name,
        reason: 'Points threshold reached',
        points_before: fighter.points,
        points_after: fighter.points
      };
    }

    return null;
  }

  // Check if a fighter should be demoted (5 consecutive losses rule)
  async checkForDemotion(fighterId: string): Promise<TierChange | null> {
    const { data: fighter, error } = await supabase
      .from('fighter_profiles')
      .select('*')
      .eq('id', fighterId)
      .single();

    if (error || !fighter) return null;

    // Get recent fight records
    const { data: recentFights, error: fightsError } = await supabase
      .from('fight_records')
      .select('result')
      .eq('fighter_id', fighterId)
      .order('date', { ascending: false })
      .limit(5);

    if (fightsError || !recentFights || recentFights.length < 5) return null;

    // Check if all 5 recent fights were losses
    const allLosses = recentFights.every(fight => fight.result === 'Loss');
    
    if (allLosses && fighter.tier !== 'Amateur') {
      // Find the next lower tier
      const currentTier = await this.getTierByName(fighter.tier);
      if (!currentTier) return null;

      const { data: lowerTier, error: tierError } = await supabase
        .from('tiers')
        .select('*')
        .lt('min_points', currentTier.min_points)
        .order('min_points', { ascending: false })
        .limit(1)
        .single();

      if (tierError || !lowerTier) return null;

      return {
        fighter_id: fighterId,
        from_tier: fighter.tier,
        to_tier: lowerTier.name,
        reason: '5 consecutive losses',
        points_before: fighter.points,
        points_after: fighter.points
      };
    }

    return null;
  }

  // Process tier changes for a fighter
  async processTierChanges(fighterId: string): Promise<TierChange[]> {
    const changes: TierChange[] = [];

    // Check for promotion
    const promotion = await this.checkForPromotion(fighterId);
    if (promotion) {
      changes.push(promotion);
    }

    // Check for demotion (only if no promotion)
    if (!promotion) {
      const demotion = await this.checkForDemotion(fighterId);
      if (demotion) {
        changes.push(demotion);
      }
    }

    // Apply tier changes
    for (const change of changes) {
      await this.applyTierChange(change);
    }

    return changes;
  }

  // Apply a tier change
  async applyTierChange(change: TierChange): Promise<void> {
    // Update fighter's tier
    const { error: updateError } = await supabase
      .from('fighter_profiles')
      .update({ tier: change.to_tier })
      .eq('id', change.fighter_id);

    if (updateError) throw updateError;

    // Record tier change in history
    const { error: historyError } = await supabase
      .from('tier_history')
      .insert({
        fighter_id: change.fighter_id,
        from_tier: change.from_tier,
        to_tier: change.to_tier,
        reason: change.reason
      });

    if (historyError) throw historyError;

    // Create notification for tier change
    await this.createTierChangeNotification(change);
  }

  // Create notification for tier change
  private async createTierChangeNotification(change: TierChange): Promise<void> {
    const { data: fighter, error: fighterError } = await supabase
      .from('fighter_profiles')
      .select('user_id, name')
      .eq('id', change.fighter_id)
      .single();

    if (fighterError || !fighter) return;

    const isPromotion = change.to_tier !== change.from_tier;
    const title = isPromotion ? 'Tier Promotion!' : 'Tier Demotion';
    const message = isPromotion 
      ? `Congratulations! You've been promoted to ${change.to_tier} tier!`
      : `You've been demoted to ${change.to_tier} tier due to ${change.reason.toLowerCase()}.`;

    await supabase
      .from('notifications')
      .insert({
        user_id: fighter.user_id,
        type: 'Tier',
        title,
        message,
        action_url: '/profile'
      });
  }

  // Get tier history for a fighter
  async getTierHistory(fighterId: string): Promise<TierHistory[]> {
    const { data, error } = await supabase
      .from('tier_history')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  // Get tier statistics
  async getTierStats(): Promise<TierStats> {
    // Get tier distribution (filter out admins)
    const { data: tierData, error: tierError } = await supabase
      .from('fighter_profiles')
      .select('tier, points, user_id');

    if (tierError) throw tierError;
    if (!tierData || tierData.length === 0) {
      return {
        total_fighters: 0,
        tier_distribution: {},
        recent_promotions: 0,
        recent_demotions: 0,
        average_points_per_tier: {}
      };
    }

    // Filter out admin users
    const filteredData = await filterAdminFighters(tierData);
    const totalFighters = filteredData.length;

    const tierDistribution: { [tier: string]: number } = {};
    const averagePointsPerTier: { [tier: string]: number } = {};
    const tierPoints: { [tier: string]: number[] } = {};

    filteredData.forEach(fighter => {
      const tier = fighter.tier;
      tierDistribution[tier] = (tierDistribution[tier] || 0) + 1;
      
      if (!tierPoints[tier]) tierPoints[tier] = [];
      tierPoints[tier].push(fighter.points);
    });

    // Calculate average points per tier
    Object.keys(tierPoints).forEach(tier => {
      const points = tierPoints[tier];
      averagePointsPerTier[tier] = points.reduce((sum, p) => sum + p, 0) / points.length;
    });

    // Get recent promotions and demotions (last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const { data: recentChanges, error: changesError } = await supabase
      .from('tier_history')
      .select('from_tier, to_tier')
      .gte('created_at', thirtyDaysAgo.toISOString());

    if (changesError) throw changesError;

    const recentPromotions = recentChanges?.filter(change => 
      change.from_tier !== change.to_tier
    ).length || 0;

    const recentDemotions = recentChanges?.filter(change => 
      change.from_tier !== change.to_tier
    ).length || 0;

    return {
      total_fighters: totalFighters,
      tier_distribution: tierDistribution,
      recent_promotions: recentPromotions,
      recent_demotions: recentDemotions,
      average_points_per_tier: averagePointsPerTier
    };
  }

  // Get fighters by tier
  async getFightersByTier(tierName: string): Promise<FighterProfile[]> {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select(`
        *,
        rankings!inner(rank, points)
      `)
      .eq('tier', tierName)
      .eq('rankings.weight_class', 'Overall')
      .order('rankings.rank');

    if (error) throw error;
    if (!data || data.length === 0) return [];
    
    // Filter out admin users
    return await filterAdminFighters(data);
  }

  // Get tier progression data for a fighter
  async getTierProgression(fighterId: string): Promise<{
    current_tier: string;
    points_to_next_tier: number;
    points_from_previous_tier: number;
    tier_progress_percentage: number;
  }> {
    const { data: fighter, error: fighterError } = await supabase
      .from('fighter_profiles')
      .select('tier, points')
      .eq('id', fighterId)
      .single();

    if (fighterError || !fighter) {
      throw new Error('Fighter not found');
    }

    const currentTier = await this.getTierByName(fighter.tier);
    if (!currentTier) {
      throw new Error('Current tier not found');
    }

    // Get next tier
    const { data: nextTier, error: nextTierError } = await supabase
      .from('tiers')
      .select('*')
      .gt('min_points', currentTier.min_points)
      .order('min_points', { ascending: true })
      .limit(1)
      .single();

    // Get previous tier
    const { data: prevTier, error: prevTierError } = await supabase
      .from('tiers')
      .select('*')
      .lt('min_points', currentTier.min_points)
      .order('min_points', { ascending: false })
      .limit(1)
      .single();

    const pointsToNext = nextTier ? nextTier.min_points - fighter.points : 0;
    const pointsFromPrev = prevTier ? fighter.points - prevTier.min_points : fighter.points;
    
    let progressPercentage = 0;
    if (nextTier && prevTier) {
      const tierRange = nextTier.min_points - prevTier.min_points;
      const currentProgress = fighter.points - prevTier.min_points;
      progressPercentage = Math.round((currentProgress / tierRange) * 100);
    } else if (nextTier) {
      progressPercentage = Math.round((fighter.points / nextTier.min_points) * 100);
    } else {
      progressPercentage = 100; // Elite tier
    }

    return {
      current_tier: fighter.tier,
      points_to_next_tier: Math.max(0, pointsToNext),
      points_from_previous_tier: pointsFromPrev,
      tier_progress_percentage: Math.min(100, Math.max(0, progressPercentage))
    };
  }

  // Bulk process tier changes for all fighters
  async processAllTierChanges(): Promise<{
    processed: number;
    promotions: number;
    demotions: number;
    errors: string[];
  }> {
    const { data: fighters, error } = await supabase
      .from('fighter_profiles')
      .select('id');

    if (error) throw error;

    let processed = 0;
    let promotions = 0;
    let demotions = 0;
    const errors: string[] = [];

    for (const fighter of fighters || []) {
      try {
        const changes = await this.processTierChanges(fighter.id);
        processed++;
        
        for (const change of changes) {
          if (change.to_tier !== change.from_tier) {
            if (change.reason === 'Points threshold reached') {
              promotions++;
            } else {
              demotions++;
            }
          }
        }
      } catch (error) {
        errors.push(`Fighter ${fighter.id}: ${error}`);
      }
    }

    return {
      processed,
      promotions,
      demotions,
      errors
    };
  }
}

export const tierService = new TierService();
export {};
