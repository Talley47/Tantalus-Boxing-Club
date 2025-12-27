// ============================================================================
// 🎯 BEST PRACTICE: Use Edge Function for Top Fighters (Server-Side)
// ============================================================================
// This replaces the direct Supabase query with a server-side call
// The Edge Function uses SERVICE_ROLE_KEY and bypasses RLS
// ============================================================================

import { Fighter } from './homePageService';

const SUPABASE_URL = process.env.REACT_APP_SUPABASE_URL || '';
const EDGE_FUNCTION_URL = `${SUPABASE_URL}/functions/v1/get-top-fighters`;

export class HomePageService {
  // Get top fighters via Edge Function (BEST PRACTICE)
  static async getTopFighters(limit: number = 30): Promise<Fighter[]> {
    try {
      // Call Edge Function instead of direct Supabase query
      const response = await fetch(`${EDGE_FUNCTION_URL}?limit=${limit}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          // Use anon key for Edge Function authentication
          'apikey': process.env.REACT_APP_SUPABASE_ANON_KEY || '',
        },
      });

      if (!response.ok) {
        throw new Error(`Edge Function failed: ${response.statusText}`);
      }

      const result = await response.json();

      if (!result.success || !result.fighters) {
        console.error('Edge Function returned error:', result);
        return [];
      }

      // Map to Fighter type
      const fighters = result.fighters.map((fighter: any) => ({
        id: fighter.user_id,
        name: fighter.name || 'Unknown Fighter',
        handle: fighter.handle || 'unknown',
        tier: fighter.tier || 'Amateur',
        points: fighter.points || 0,
        weight_class: fighter.weight_class || 'Unknown',
        wins: fighter.wins || 0,
        losses: fighter.losses || 0,
        draws: fighter.draws || 0,
        height_feet: fighter.height_feet,
        height_inches: fighter.height_inches,
        weight: fighter.weight,
        reach: fighter.reach,
        stance: fighter.stance,
        hometown: fighter.hometown,
        birthday: fighter.birthday,
        trainer: fighter.trainer,
        gym: fighter.gym,
        platform: undefined,
        timezone: undefined,
        creative_fighter_image_url: undefined,
        belts: [],
      }));

      return fighters;
    } catch (error) {
      console.error('Error fetching top fighters from Edge Function:', error);
      // Fallback to direct query if Edge Function fails
      return this.getTopFightersFallback(limit);
    }
  }

  // Fallback: Direct Supabase query (for dev/fallback)
  private static async getTopFightersFallback(limit: number = 30): Promise<Fighter[]> {
    // Import supabase client dynamically to avoid circular dependencies
    const { supabase } = await import('./supabase');
    
    try {
      const { data, error } = await supabase
        .from('fighter_profiles')
        .select('user_id, name, handle, tier, points, weight_class, wins, losses, draws, height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym')
        .not('user_id', 'is', null)
        .order('points', { ascending: false })
        .limit(limit);

      if (error) {
        console.error('Fallback query error:', error);
        return [];
      }

      if (!data || data.length === 0) {
        return [];
      }

      return data.map(fighter => ({
        id: fighter.user_id,
        name: fighter.name || 'Unknown Fighter',
        handle: fighter.handle || 'unknown',
        tier: fighter.tier || 'Amateur',
        points: fighter.points || 0,
        weight_class: fighter.weight_class || 'Unknown',
        wins: fighter.wins || 0,
        losses: fighter.losses || 0,
        draws: fighter.draws || 0,
        height_feet: fighter.height_feet,
        height_inches: fighter.height_inches,
        weight: fighter.weight,
        reach: fighter.reach,
        stance: fighter.stance,
        hometown: fighter.hometown,
        birthday: fighter.birthday,
        trainer: fighter.trainer,
        gym: fighter.gym,
        platform: undefined,
        timezone: undefined,
        creative_fighter_image_url: undefined,
        belts: [],
      }));
    } catch (error) {
      console.error('Error in fallback query:', error);
      return [];
    }
  }
}

