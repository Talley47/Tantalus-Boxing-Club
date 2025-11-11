import { supabase } from './supabase';
import { filterAdminFighters } from '../utils/filterAdmins';

// Types for the HomePage data
export interface Fighter {
  id: string;
  name: string;
  handle: string;
  tier: string;
  points: number;
  weight_class: string;
  wins: number;
  losses: number;
  draws: number;
  // Physical information
  height_feet?: number;
  height_inches?: number;
  weight?: number;
  reach?: number;
  stance?: string;
  hometown?: string;
  birthday?: string;
  trainer?: string;
  gym?: string;
  platform?: string;
  timezone?: string;
}

export interface ScheduledFight {
  id: string;
  fighter1_id?: string;
  fighter2_id?: string;
  fighter1?: Fighter;
  fighter2?: Fighter;
  scheduled_date: string;
  scheduled_time: string;
  timezone: string;
  venue: string;
  weight_class: string;
  status: string;
  match_type?: 'manual' | 'auto_mandatory' | 'callout' | 'training_camp';
  match_score?: number;
}

export interface NewsItem {
  id: string;
  title: string;
  content: string;
  author: string;
  type: 'news' | 'announcement';
  priority: 'high' | 'medium' | 'low';
  created_at: string;
}

export class HomePageService {
  // Get top fighters by points
  static async getTopFighters(limit: number = 30): Promise<Fighter[]> {
    try {
      console.log('Fetching top fighters...');
      
      // Try to get all fighter profiles - check if RLS allows public read
      // Note: Using application-level filtering since there's no FK relationship for JOIN
      const { data, error, status, statusText } = await supabase
        .from('fighter_profiles')
        .select('user_id, name, handle, tier, points, weight_class, wins, losses, draws, height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym, platform, timezone')
        .not('user_id', 'is', null)
        .order('points', { ascending: false })
        .limit(limit);

      // Only log query details in development if there's an error
      if (error && process.env.NODE_ENV === 'development') {
        console.log('Supabase query response:', {
          hasData: !!data,
          dataLength: (data as any)?.length || 0,
          hasError: !!error,
          error: error,
          status: status,
          statusText: statusText
        });
      }

      if (error) {
        console.error('❌ Error fetching top fighters:', error);
        
        // If it's a permission error, provide specific guidance
        if (error.code === '42501' || error.message?.includes('permission') || error.message?.includes('policy')) {
          console.error('🔒 PERMISSION ERROR: RLS policies are blocking access!');
          console.error('💡 SOLUTION: Run database/fix-fighter-profiles-rls-read.sql in Supabase SQL Editor');
        }
        
        return [];
      }

      // Only log if we have fighters (reduce console noise)
      if (data && data.length > 0) {
        console.log(`Found ${data.length} fighters`);
      }
      
      if (!data || data.length === 0) {
        if (!(window as any).__fighterWarningShown) {
          console.info('ℹ️ No fighters found in database. This is normal if no fighter profiles have been created yet.');
          console.info('💡 To test: Register a fighter account or run database/fix-fighter-profiles-rls-read.sql');
          (window as any).__fighterWarningShown = true;
        }
        return [];
      }

      // Filter out admin users from raw data before mapping
      const filteredData = await filterAdminFighters(data);

      let fighters = filteredData.map(fighter => ({
        id: fighter.user_id,
        name: fighter.name || 'Unknown Fighter',
        handle: fighter.handle || 'unknown',
        tier: fighter.tier || 'Amateur',
        points: fighter.points || 0,
        weight_class: fighter.weight_class || 'Unknown',
        wins: fighter.wins || 0,
        losses: fighter.losses || 0,
        draws: fighter.draws || 0,
        // Physical information
        height_feet: fighter.height_feet,
        height_inches: fighter.height_inches,
        weight: fighter.weight,
        reach: fighter.reach,
        stance: fighter.stance,
        hometown: fighter.hometown,
        birthday: fighter.birthday,
        trainer: fighter.trainer,
        gym: fighter.gym,
        platform: (fighter as any).platform,
        timezone: (fighter as any).timezone
      }));

      console.log('Mapped fighters (after admin filter):', fighters);
      return fighters;
    } catch (error) {
      console.error('Error in getTopFighters:', error);
      return [];
    }
  }

  // Get scheduled fights (all fights in the league)
  // By default, only returns Scheduled fights, but can include Pending if needed
  static async getScheduledFights(limit: number = 50, includePending: boolean = false): Promise<ScheduledFight[]> {
    try {
      // Build query - include Pending if requested
      let query = supabase
        .from('scheduled_fights')
        .select('*');
      
      if (includePending) {
        // Get both Scheduled and Pending fights
        query = query.in('status', ['Scheduled', 'Pending']);
      } else {
        // Only show Scheduled fights (for Home Page)
        query = query.eq('status', 'Scheduled');
      }
      
      const { data: fights, error: fightsError } = await query
        .order('scheduled_date', { ascending: true })
        .limit(limit);

      if (fightsError) {
        console.error('Error fetching scheduled fights:', fightsError);
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

      // Filter out fights with admin fighters and map to ScheduledFight format
      const filteredFights: ScheduledFight[] = [];
      
      for (const fight of fights) {
        const fighter1Profile = fighterMap.get(fight.fighter1_id);
        const fighter2Profile = fighterMap.get(fight.fighter2_id);
        
        // Check if both fighters exist and are not admins
        if (fighter1Profile && fighter2Profile) {
          const fightersToCheck = [fighter1Profile, fighter2Profile];
          const filtered = await filterAdminFighters(fightersToCheck);
          
          // If both fighters are still present after filtering, include the fight
          if (filtered.length === 2) {
            filteredFights.push({
              id: fight.id,
              fighter1_id: fighter1Profile.user_id,
              fighter2_id: fighter2Profile.user_id,
              fighter1: {
                id: fighter1Profile.user_id,
                name: fighter1Profile.name || 'Unknown Fighter',
                handle: fighter1Profile.handle || 'unknown',
                tier: fighter1Profile.tier || 'Amateur',
                points: fighter1Profile.points || 0,
                weight_class: fighter1Profile.weight_class || 'Unknown',
                wins: fighter1Profile.wins || 0,
                losses: fighter1Profile.losses || 0,
                draws: fighter1Profile.draws || 0
              },
              fighter2: {
                id: fighter2Profile.user_id,
                name: fighter2Profile.name || 'Unknown Fighter',
                handle: fighter2Profile.handle || 'unknown',
                tier: fighter2Profile.tier || 'Amateur',
                points: fighter2Profile.points || 0,
                weight_class: fighter2Profile.weight_class || 'Unknown',
                wins: fighter2Profile.wins || 0,
                losses: fighter2Profile.losses || 0,
                draws: fighter2Profile.draws || 0
              },
              scheduled_date: fight.scheduled_date,
              scheduled_time: (fight as any).scheduled_time || new Date(fight.scheduled_date).toLocaleTimeString(),
              timezone: fight.timezone || 'UTC',
              venue: (fight as any).venue || 'TBD',
              weight_class: fight.weight_class || 'Unknown',
              status: fight.status || 'scheduled',
              match_type: (fight as any).match_type,
              match_score: (fight as any).match_score
            });
          }
        }
      }

      return filteredFights;
    } catch (error) {
      console.error('Error in getScheduledFights:', error);
      return [];
    }
  }

  // Get news and announcements
  static async getNewsAndAnnouncements(limit: number = 10): Promise<NewsItem[]> {
    try {
      const { data, error } = await supabase
        .from('news_announcements')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) {
        console.error('Error fetching news and announcements:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Error in getNewsAndAnnouncements:', error);
      return [];
    }
  }

  // Real-time subscriptions
  static subscribeToTopFighters(callback: (fighters: Fighter[]) => void) {
    return supabase
      .channel('top-fighters')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'fighter_profiles'
        },
        async () => {
          const fighters = await this.getTopFighters(30);
          callback(fighters);
        }
      )
      .subscribe();
  }

  static subscribeToScheduledFights(callback: (fights: ScheduledFight[]) => void) {
    return supabase
      .channel('scheduled-fights')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'scheduled_fights'
        },
        async () => {
          const fights = await this.getScheduledFights(10);
          callback(fights);
        }
      )
      .subscribe();
  }

  static subscribeToNewsAndAnnouncements(callback: (news: NewsItem[]) => void) {
    return supabase
      .channel('news-announcements')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'news_announcements'
        },
        async () => {
          const news = await this.getNewsAndAnnouncements(10);
          callback(news);
        }
      )
      .subscribe();
  }

}