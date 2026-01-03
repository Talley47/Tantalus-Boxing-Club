import { supabase } from './supabase';
import { filterAdminFighters } from '../utils/filterAdmins';

// Types for the HomePage data
export interface ChampionshipBelt {
  id: string;
  belt_image_url: string;
  governing_body: string;
}

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
  creative_fighter_image_url?: string;
  belts?: ChampionshipBelt[]; // Championship belts assigned to the fighter
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
  requested_by?: string; // Profile ID of the fighter who requested the fight (for mandatory fights)
  fighter1_profile_id?: string; // Profile ID (primary key) for fighter1
  fighter2_profile_id?: string; // Profile ID (primary key) for fighter2
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
      // DIAGNOSTIC: Check authentication status
      const { data: { user }, error: authError } = await supabase.auth.getUser();
      console.log('🔐 AUTHENTICATION STATUS:', {
        isAuthenticated: !!user,
        userId: user?.id || 'none',
        email: user?.email || 'none',
        authError: authError?.message || 'none'
      });
      
      // DIAGNOSTIC: First check if we can see ANY data at all (without filters)
      const { data: diagnosticData, error: diagnosticError } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name')
        .limit(5);
      
      console.log('🔍 DIAGNOSTIC QUERY RESULT:', {
        canSeeAnyData: !!diagnosticData && diagnosticData.length > 0,
        rowCount: diagnosticData?.length || 0,
        hasError: !!diagnosticError,
        error: diagnosticError,
        sampleRows: diagnosticData?.slice(0, 3) || []
      });
      
      // Try to get all fighter profiles - check if RLS allows public read
      // Note: Using application-level filtering since there's no FK relationship for JOIN
      const { data, error, status, statusText } = await supabase
        .from('fighter_profiles')
        .select('user_id, name, handle, tier, points, weight_class, wins, losses, draws, height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym')
        .not('user_id', 'is', null)
        .order('points', { ascending: false })
        .limit(limit);

      // Log query details for debugging
      if (error) {
        console.error('❌ Error fetching top fighters:', error);
        console.error('Query details:', {
          hasData: !!data,
          dataLength: (data as any)?.length || 0,
          hasError: !!error,
          error: error,
          status: status,
          statusText: statusText,
          errorCode: error.code,
          errorMessage: error.message
        });
        
        // If it's a permission error, provide specific guidance
        if (error.code === '42501' || error.message?.includes('permission') || error.message?.includes('policy')) {
          console.error('🔒 PERMISSION ERROR: RLS policies are blocking access!');
          console.error('💡 SOLUTION: Run database/fix-homepage-authenticated-access.sql in Supabase SQL Editor');
        }
        
        return [];
      }

      // Log when no data is returned (could be RLS or empty database)
      if (!data || data.length === 0) {
        console.error('⚠️ ⚠️ ⚠️ NO FIGHTERS RETURNED FROM QUERY ⚠️ ⚠️ ⚠️');
        console.error('Query Status:', { status, statusText, hasError: !!error });
        console.error('Diagnostic Info:', {
          canSeeAnyRows: !!diagnosticData && diagnosticData.length > 0,
          diagnosticRowCount: diagnosticData?.length || 0,
          diagnosticError: diagnosticError?.message || 'none'
        });
        console.error('');
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.error('🚨 CRITICAL: RLS policies are blocking access to fighter_profiles table');
        console.error('   Query succeeds (HTTP 200) but returns 0 rows because RLS filters everything out.');
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.error('');
        console.error('⚡⚡⚡ THE FIX (3 Steps, 2 Minutes) ⚡⚡⚡');
        console.error('');
        console.error('📖 READ THIS FILE FIRST:');
        console.error('   database/README-FIRST.md');
        console.error('');
        console.error('OR FOLLOW THESE STEPS:');
        console.error('');
        console.error('   1. Open: database/COPY-THIS-AND-RUN.sql');
        console.error('   2. Copy ALL (Ctrl+A, Ctrl+C)');
        console.error('   3. Go to: https://supabase.com/dashboard → Your Project → SQL Editor');
        console.error('   4. Paste (Ctrl+V) → Click "Run"');
        console.error('   5. Hard refresh app (Ctrl+Shift+R)');
        console.error('');
        console.error('✅ SUCCESS = Fighters appear immediately!');
        console.error('');
        console.error('🔍 If still not working:');
        console.error('   Run: database/TEST-IF-FIX-WORKED.sql in Supabase SQL Editor');
        console.error('   It will tell you exactly what\'s wrong.');
        console.error('');
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return [];
      }

      console.log(`✅ Fetched ${data.length} fighter profiles from database`);

      // Filter out admin users from raw data before mapping
      const filteredData = await filterAdminFighters(data);

      // Fetch championship belts for all fighters
      const fighterUserIds = filteredData.map(f => f.user_id).filter(Boolean);
      const beltsByUserId = new Map<string, ChampionshipBelt[]>();
      
      if (fighterUserIds.length > 0) {
        try {
          // Get fighter profile IDs from user IDs
          const { data: fighterProfiles } = await supabase
            .from('fighter_profiles')
            .select('id, user_id')
            .in('user_id', fighterUserIds);

          if (fighterProfiles && fighterProfiles.length > 0) {
            const fighterProfileIds = fighterProfiles.map(fp => fp.id);
            
            // Fetch belts by fighter_id (profile ID)
            const { data: belts } = await supabase
              .from('championship_belts')
              .select('id, fighter_id, belt_image_url, governing_body')
              .in('fighter_id', fighterProfileIds);

            if (belts && belts.length > 0) {
              // Create a map from fighter profile ID to user ID
              const profileIdToUserId = new Map(
                fighterProfiles.map(fp => [fp.id, fp.user_id])
              );

              // Group belts by user_id
              belts.forEach(belt => {
                const userId = profileIdToUserId.get(belt.fighter_id);
                if (userId) {
                  if (!beltsByUserId.has(userId)) {
                    beltsByUserId.set(userId, []);
                  }
                  beltsByUserId.get(userId)!.push({
                    id: belt.id,
                    belt_image_url: belt.belt_image_url,
                    governing_body: belt.governing_body,
                  });
                }
              });
            }
          }
        } catch (error) {
          // If championship_belts table doesn't exist or there's an error, continue without belts
          console.warn('Error fetching championship belts for home page:', error);
        }
      }

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
        height_feet: (fighter as any).height_feet,
        height_inches: (fighter as any).height_inches,
        weight: fighter.weight,
        reach: fighter.reach,
        stance: fighter.stance,
        hometown: fighter.hometown,
        birthday: fighter.birthday,
        trainer: fighter.trainer,
        gym: fighter.gym,
        platform: undefined, // Column doesn't exist in database
        timezone: undefined, // Column doesn't exist in database
        creative_fighter_image_url: undefined, // Column doesn't exist in database
        belts: beltsByUserId.get(fighter.user_id) || []
      }));

      console.log('Mapped fighters (after admin filter):', fighters);
      return fighters;
    } catch (error) {
      console.error('Error in getTopFighters:', error);
      return [];
    }
  }

  // Get scheduled fights (all fights in the club)
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
              match_score: (fight as any).match_score,
              requested_by: (fight as any).requested_by, // Include requested_by field
              fighter1_profile_id: fighter1Profile.id, // Include profile IDs for comparison
              fighter2_profile_id: fighter2Profile.id
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
      // WORKAROUND: Don't filter by is_published in database query - causes timeout
      // Fetch more items and filter client-side instead
      let query = supabase
        .from('news_announcements')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit * 2); // Fetch more items to filter client-side

      const { data, error } = await query;

      if (error) {
        console.error('Error fetching news and announcements:', error);
        // Handle timeout specifically
        if (error.code === '57014') { // Statement timeout
          console.warn('News and announcements query timed out. Returning empty array.');
          return [];
        }
        return [];
      }

      // Diagnostic logging
      console.log('📰 HomePage news query result:', {
        totalFetched: data?.length || 0,
        sampleItems: (data || []).slice(0, 3).map(item => ({
          id: item.id,
          title: item.title,
          is_published: item.is_published,
          type: item.type
        }))
      });

      // Handle empty result set (might be RLS blocking authenticated users)
      const { data: { user } } = await supabase.auth.getUser();
      if ((!data || data.length === 0) && user) {
        console.error('🚫 RLS POLICY ISSUE: No news items returned for authenticated user.');
        console.error('   This means RLS is blocking access to news_announcements table.');
        console.error('   FIX: Run this SQL in Supabase Dashboard → SQL Editor:');
        console.error('   DROP POLICY IF EXISTS "Authenticated read published news" ON public.news_announcements;');
        console.error('   CREATE POLICY "Authenticated read published news"');
        console.error('   ON public.news_announcements FOR SELECT TO authenticated');
        console.error('   USING (is_published IS NOT NULL AND is_published = TRUE);');
        console.error('   Or run: database/🔧-SIMPLE-FIX-NEWS-RLS.sql');
        return [];
      }

      // Client-side filter for published items
      // Handle NULL is_published as unpublished (safety check)
      const filteredData = (data || []).filter(item => {
        const isPublished = item.is_published === true;
        if (!isPublished && data && data.length > 0) {
          console.log('🔍 Filtered out unpublished item:', {
            id: item.id,
            title: item.title,
            is_published: item.is_published
          });
        }
        return isPublished;
      });

      console.log('✅ After filtering:', {
        totalPublished: filteredData.length,
        willReturn: Math.min(filteredData.length, limit)
      });

      return filteredData.slice(0, limit); // Limit after client-side filter
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