import { supabase } from './supabase';

export interface FighterSanction {
  id: string;
  fighter_id: string;
  user_id: string;
  sanction_acronym: string;
  joined_at: string;
}

export interface SanctionFighter {
  id: string;
  user_id: string;
  name: string;
  handle: string;
  points: number;
  tier: string;
  wins: number;
  losses: number;
  draws: number;
  weight_class: string;
  rank?: number; // Calculated rank within the sanction
  demotions?: number; // Number of demotions (can be calculated from fight records)
}

class FighterSanctionService {
  private readonly TABLE_NAME = 'fighter_sanctions';

  /**
   * Join a sanction
   */
  async joinSanction(sanctionAcronym: string, userId: string): Promise<void> {
    try {
      // Validate inputs
      if (!userId) {
        throw new Error('User ID is required');
      }

      if (!sanctionAcronym) {
        throw new Error('Sanction acronym is required');
      }

      // Get fighter profile ID
      const { data: fighterProfile, error: profileError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileError) {
        console.error('Error fetching fighter profile:', profileError);
        throw new Error(`Failed to fetch fighter profile: ${profileError.message}`);
      }

      if (!fighterProfile || !fighterProfile.id) {
        throw new Error('Fighter profile not found. Please complete your fighter profile first.');
      }

      // Check if already joined
      const { data: existing, error: checkError } = await supabase
        .from(this.TABLE_NAME)
        .select('id')
        .eq('fighter_id', fighterProfile.id)
        .eq('sanction_acronym', sanctionAcronym)
        .maybeSingle();

      if (checkError) {
        // If table doesn't exist, provide helpful error
        if (checkError.code === '42P01' || checkError.message?.includes('does not exist')) {
          throw new Error('Sanctions feature not available yet. Please contact admin to set up the database.');
        }
        // If it's just "not found", that's fine - continue
        if (checkError.code !== 'PGRST116') {
          console.error('Error checking existing membership:', checkError);
          throw new Error(`Failed to check membership: ${checkError.message}`);
        }
      }

      if (existing) {
        throw new Error('You have already joined this sanction');
      }

      // Join the sanction
      const { data: insertedData, error: insertError } = await supabase
        .from(this.TABLE_NAME)
        .insert({
          fighter_id: fighterProfile.id,
          user_id: userId,
          sanction_acronym: sanctionAcronym,
        })
        .select()
        .single();

      if (insertError) {
        console.error('Error joining sanction:', insertError);
        
        // Handle specific error codes
        if (insertError.code === '23505') {
          // Unique constraint violation - already joined
          throw new Error('You have already joined this sanction');
        }
        
        if (insertError.code === '42501' || insertError.message?.includes('permission denied') || insertError.message?.includes('policy')) {
          throw new Error('Permission denied. Please ensure you are logged in and have a fighter profile.');
        }
        
        if (insertError.code === '42P01' || insertError.message?.includes('does not exist')) {
          throw new Error('Sanctions feature not available yet. Please contact admin to set up the database.');
        }
        
        if (insertError.code === '23503') {
          // Foreign key violation
          throw new Error('Invalid sanction or fighter profile. Please contact admin.');
        }

        throw new Error(`Failed to join sanction: ${insertError.message || 'Unknown error'}`);
      }

      if (!insertedData) {
        throw new Error('Failed to join sanction: No data returned');
      }
    } catch (error: any) {
      // Re-throw with better error message if it's already a user-friendly error
      if (error.message && !error.message.includes('contact admin')) {
        throw error;
      }
      
      // Handle table doesn't exist
      if (error.code === '42P01' || error.message?.includes('does not exist')) {
        console.warn('Fighter sanctions table does not exist yet. Run create-fighter-sanctions-table.sql');
        throw new Error('Sanctions feature not available yet. Please contact admin to set up the database.');
      }
      
      throw error;
    }
  }

  /**
   * Leave a sanction
   */
  async leaveSanction(sanctionAcronym: string, userId: string): Promise<void> {
    try {
      // Get fighter profile ID
      const { data: fighterProfile, error: profileError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileError) {
        console.error('Error fetching fighter profile:', profileError);
        throw profileError;
      }

      if (!fighterProfile) {
        throw new Error('Fighter profile not found');
      }

      // Leave the sanction
      const { error: deleteError } = await supabase
        .from(this.TABLE_NAME)
        .delete()
        .eq('fighter_id', fighterProfile.id)
        .eq('sanction_acronym', sanctionAcronym);

      if (deleteError) {
        console.error('Error leaving sanction:', deleteError);
        throw deleteError;
      }
    } catch (error: any) {
      if (error.code === '42P01' || error.message?.includes('does not exist')) {
        console.warn('Fighter sanctions table does not exist yet.');
        throw new Error('Sanctions feature not available yet.');
      }
      throw error;
    }
  }

  /**
   * Check if fighter has joined a sanction
   */
  async hasJoinedSanction(sanctionAcronym: string, userId: string): Promise<boolean> {
    try {
      // Get fighter profile ID
      const { data: fighterProfile, error: profileError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileError || !fighterProfile) {
        return false;
      }

      const { data, error } = await supabase
        .from(this.TABLE_NAME)
        .select('id')
        .eq('fighter_id', fighterProfile.id)
        .eq('sanction_acronym', sanctionAcronym)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') {
        console.error('Error checking sanction membership:', error);
        return false;
      }

      return !!data;
    } catch (error: any) {
      if (error.code === '42P01') {
        return false;
      }
      console.error('Error checking sanction membership:', error);
      return false;
    }
  }

  /**
   * Get all fighters who joined a specific sanction, ranked by points, tier, etc.
   */
  async getFightersBySanction(sanctionAcronym: string): Promise<SanctionFighter[]> {
    try {
      // Get all fighter sanctions for this sanction
      const { data: sanctions, error: sanctionsError } = await supabase
        .from(this.TABLE_NAME)
        .select('fighter_id, user_id')
        .eq('sanction_acronym', sanctionAcronym);

      if (sanctionsError) {
        if (sanctionsError.code === '42P01') {
          console.warn('Fighter sanctions table does not exist yet.');
          return [];
        }
        console.error('Error fetching fighter sanctions:', sanctionsError);
        throw sanctionsError;
      }

      if (!sanctions || sanctions.length === 0) {
        return [];
      }

      const fighterIds = sanctions.map(s => s.fighter_id);
      const userIds = sanctions.map(s => s.user_id);

      // Get fighter profiles with their stats
      const { data: fighters, error: fightersError } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, handle, points, tier, wins, losses, draws, weight_class')
        .in('id', fighterIds);

      if (fightersError) {
        console.error('Error fetching fighters:', fightersError);
        throw fightersError;
      }

      if (!fighters || fighters.length === 0) {
        return [];
      }

      // Get fight records to calculate demotions (consecutive losses)
      const { data: fightRecords, error: recordsError } = await supabase
        .from('fight_records')
        .select('fighter_id, result')
        .in('fighter_id', fighterIds)
        .order('date', { ascending: false })
        .order('created_at', { ascending: false });

      // Calculate demotions for each fighter
      const demotionsMap = new Map<string, number>();
      
      if (fightRecords && !recordsError) {
        // Group records by fighter
        const recordsByFighter = new Map<string, Array<{ result: string }>>();
        fightRecords.forEach(record => {
          if (!recordsByFighter.has(record.fighter_id)) {
            recordsByFighter.set(record.fighter_id, []);
          }
          recordsByFighter.get(record.fighter_id)!.push({ result: record.result });
        });

        // Calculate demotions (5 consecutive losses = 1 demotion)
        recordsByFighter.forEach((records, fighterId) => {
          let consecutiveLosses = 0;
          let demotions = 0;
          
          for (const record of records) {
            if (record.result === 'Loss') {
              consecutiveLosses++;
              if (consecutiveLosses >= 5) {
                demotions++;
                consecutiveLosses = 0; // Reset after demotion
              }
            } else {
              consecutiveLosses = 0; // Reset on win or draw
            }
          }
          
          demotionsMap.set(fighterId, demotions);
        });
      }

      // Map to SanctionFighter format and calculate ranks
      let sanctionFighters: SanctionFighter[] = fighters.map(fighter => ({
        id: fighter.id,
        user_id: fighter.user_id,
        name: fighter.name,
        handle: fighter.handle,
        points: fighter.points || 0,
        tier: fighter.tier || 'Amateur',
        wins: fighter.wins || 0,
        losses: fighter.losses || 0,
        draws: fighter.draws || 0,
        weight_class: fighter.weight_class || 'Unknown',
        demotions: demotionsMap.get(fighter.id) || 0,
      }));

      // Sort by: points (desc), tier (desc), demotions (asc), wins (desc)
      const tierOrder: { [key: string]: number } = {
        'Elite': 5,
        'Contender': 4,
        'Pro': 3,
        'Semi-Pro': 2,
        'Amateur': 1,
      };

      sanctionFighters.sort((a, b) => {
        // Primary: Points (descending)
        if (b.points !== a.points) {
          return b.points - a.points;
        }
        // Secondary: Tier (descending)
        const tierDiff = (tierOrder[b.tier] || 0) - (tierOrder[a.tier] || 0);
        if (tierDiff !== 0) {
          return tierDiff;
        }
        // Tertiary: Demotions (ascending - fewer demotions is better)
        const aDemotions = a.demotions || 0;
        const bDemotions = b.demotions || 0;
        if (aDemotions !== bDemotions) {
          return aDemotions - bDemotions;
        }
        // Quaternary: Wins (descending)
        return b.wins - a.wins;
      });

      // Assign ranks
      sanctionFighters.forEach((fighter, index) => {
        fighter.rank = index + 1;
      });

      return sanctionFighters;
    } catch (error: any) {
      if (error.code === '42P01') {
        console.warn('Fighter sanctions table does not exist yet.');
        return [];
      }
      console.error('Error fetching fighters by sanction:', error);
      throw error;
    }
  }

  /**
   * Get all sanctions a fighter has joined
   */
  async getSanctionsByFighter(userId: string): Promise<string[]> {
    try {
      // Get fighter profile ID
      const { data: fighterProfile, error: profileError } = await supabase
        .from('fighter_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileError || !fighterProfile) {
        return [];
      }

      const { data, error } = await supabase
        .from(this.TABLE_NAME)
        .select('sanction_acronym')
        .eq('fighter_id', fighterProfile.id);

      if (error) {
        if (error.code === '42P01') {
          return [];
        }
        console.error('Error fetching fighter sanctions:', error);
        return [];
      }

      return (data || []).map(s => s.sanction_acronym);
    } catch (error: any) {
      if (error.code === '42P01') {
        return [];
      }
      console.error('Error fetching fighter sanctions:', error);
      return [];
    }
  }
}

export const fighterSanctionService = new FighterSanctionService();

