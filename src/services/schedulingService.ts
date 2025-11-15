import { supabase, TABLES } from './supabase';
import { ScheduledFight, FightRecord, Dispute, FighterProfile } from '../types';
import { TournamentService } from './tournamentService';

export interface ScheduleFightRequest {
  fighter1_id: string;
  fighter2_id: string;
  weight_class: string;
  scheduled_date: string;
  timezone: string;
  platform: string;
  connection_notes?: string;
  house_rules?: string;
  status?: 'Pending' | 'Scheduled' | 'Completed' | 'Cancelled' | 'Disputed';
}

export interface FightResult {
  fight_id: string;
  fighter_id: string;
  result: 'Win' | 'Loss' | 'Draw';
  method: string;
  round: number;
  notes?: string;
  proof_url?: string;
}

export interface DisputeRequest {
  fight_id: string;
  disputer_id: string;
  reason: string;
  evidence_urls?: string[];
}

export interface ScheduleStats {
  total_scheduled: number;
  completed_fights: number;
  cancelled_fights: number;
  disputed_fights: number;
  completion_rate: number;
  average_fight_duration: number;
}

class SchedulingService {
  // Schedule a new fight
  async scheduleFight(request: ScheduleFightRequest, options?: { isAutoMatched?: boolean; matchType?: string; matchScore?: number }): Promise<ScheduledFight> {
    // If this is an auto-matched fight, use the database function to bypass RLS
    if (options?.isAutoMatched || options?.matchType === 'auto_mandatory') {
      const { data: fightId, error: functionError } = await supabase
        .rpc('create_auto_matched_fight', {
          p_fighter1_id: request.fighter1_id,
          p_fighter2_id: request.fighter2_id,
          p_weight_class: request.weight_class,
          p_scheduled_date: request.scheduled_date,
          p_timezone: request.timezone,
          p_platform: request.platform,
          p_connection_notes: request.connection_notes || '',
          p_house_rules: request.house_rules || '',
          p_match_type: options?.matchType || 'auto_mandatory',
          p_match_score: options?.matchScore || null
        });

      if (functionError) {
        console.error('Error calling create_auto_matched_fight:', functionError);
        // If function doesn't exist or fails, try regular insert (may fail due to RLS)
        // This will show a clear error message to the user
        throw new Error(`Failed to create auto-matched fight. Please run the SQL script: database/fix-auto-matchmaking-rls.sql. Error: ${functionError.message}`);
      }

      // Fetch the created fight
      const { data: fightData, error: fetchError } = await supabase
        .from('scheduled_fights')
        .select('*')
        .eq('id', fightId)
        .single();

      if (fetchError) throw fetchError;
      
      // Use fightData for the rest of the function
      const fightDataResult = fightData;
      
      // Fetch fighter profiles separately
      const { data: fighterProfiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, handle, tier, points, weight_class, wins, losses, draws')
        .in('id', [request.fighter1_id, request.fighter2_id]);

      if (profilesError) {
        console.error('Error fetching fighter profiles:', profilesError);
      }

      // Create a map for quick lookup
      const fighterMap = new Map((fighterProfiles || []).map(f => [f.id, f]));
      const fighter1Profile = fighterMap.get(request.fighter1_id);
      const fighter2Profile = fighterMap.get(request.fighter2_id);

      // Map to ScheduledFight format
      const scheduledFight: ScheduledFight = {
        id: fightDataResult.id,
        fighter1_id: fighter1Profile?.user_id || request.fighter1_id,
        fighter2_id: fighter2Profile?.user_id || request.fighter2_id,
        fighter1: fighter1Profile ? {
          id: fighter1Profile.user_id,
          user_id: fighter1Profile.user_id,
          name: fighter1Profile.name || 'Unknown Fighter',
          handle: fighter1Profile.handle || 'unknown',
          platform: 'PC' as const,
          platform_id: '',
          timezone: fightDataResult.timezone || 'UTC',
          weight: 0,
          reach: 0,
          stance: 'orthodox' as const,
          nationality: '',
          fighting_style: '',
          hometown: '',
          wins: fighter1Profile.wins || 0,
          losses: fighter1Profile.losses || 0,
          draws: fighter1Profile.draws || 0,
          knockouts: 0,
          points: fighter1Profile.points || 0,
          tier: (fighter1Profile.tier || 'Amateur') as any,
          weight_class: fighter1Profile.weight_class || 'Unknown',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_active: new Date().toISOString()
        } as FighterProfile : undefined,
        fighter2: fighter2Profile ? {
          id: fighter2Profile.user_id,
          user_id: fighter2Profile.user_id,
          name: fighter2Profile.name || 'Unknown Fighter',
          handle: fighter2Profile.handle || 'unknown',
          platform: 'PC' as const,
          platform_id: '',
          timezone: fightDataResult.timezone || 'UTC',
          weight: 0,
          reach: 0,
          stance: 'orthodox' as const,
          nationality: '',
          fighting_style: '',
          hometown: '',
          wins: fighter2Profile.wins || 0,
          losses: fighter2Profile.losses || 0,
          draws: fighter2Profile.draws || 0,
          knockouts: 0,
          points: fighter2Profile.points || 0,
          tier: (fighter2Profile.tier || 'Amateur') as any,
          weight_class: fighter2Profile.weight_class || 'Unknown',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_active: new Date().toISOString()
        } as FighterProfile : undefined,
        scheduled_date: fightDataResult.scheduled_date,
        timezone: fightDataResult.timezone || 'UTC',
        platform: fightDataResult.platform || 'PC',
        connection_notes: fightDataResult.connection_notes,
        house_rules: fightDataResult.house_rules,
        weight_class: fightDataResult.weight_class || 'Unknown',
        status: (fightDataResult.status || 'Scheduled') as 'Scheduled' | 'Completed' | 'Cancelled' | 'Disputed',
        match_type: (fightDataResult as any).match_type,
        match_score: (fightDataResult as any).match_score,
        created_at: fightDataResult.created_at || new Date().toISOString()
      };

      // Create notifications for both fighters
      await this.createFightScheduledNotifications(scheduledFight);

      return scheduledFight;
    }

    // Regular insert for manual fights (existing behavior)
    const { data: fightData, error } = await supabase
      .from('scheduled_fights')
      .insert({
        fighter1_id: request.fighter1_id,
        fighter2_id: request.fighter2_id,
        weight_class: request.weight_class,
        scheduled_date: request.scheduled_date,
        timezone: request.timezone,
        platform: request.platform,
        connection_notes: request.connection_notes,
        house_rules: request.house_rules,
        status: request.status || 'Scheduled'
      })
      .select('*')
      .single();

    if (error) throw error;

    // Fetch fighter profiles separately
    const { data: fighterProfiles, error: profilesError } = await supabase
      .from('fighter_profiles')
      .select('id, user_id, name, handle, tier, points, weight_class, wins, losses, draws')
      .in('id', [request.fighter1_id, request.fighter2_id]);

    if (profilesError) {
      console.error('Error fetching fighter profiles:', profilesError);
      // Continue anyway, we'll create notifications without full profile data
    }

    // Create a map for quick lookup
    const fighterMap = new Map((fighterProfiles || []).map(f => [f.id, f]));
    const fighter1Profile = fighterMap.get(request.fighter1_id);
    const fighter2Profile = fighterMap.get(request.fighter2_id);

    // Map to ScheduledFight format
    const scheduledFight: ScheduledFight = {
      id: fightData.id,
      fighter1_id: fighter1Profile?.user_id || request.fighter1_id,
      fighter2_id: fighter2Profile?.user_id || request.fighter2_id,
      fighter1: fighter1Profile ? {
        id: fighter1Profile.user_id,
        user_id: fighter1Profile.user_id,
        name: fighter1Profile.name || 'Unknown Fighter',
        handle: fighter1Profile.handle || 'unknown',
        platform: 'PC' as const,
        platform_id: '',
        timezone: fightData.timezone || 'UTC',
        weight: 0,
        reach: 0,
        stance: 'orthodox' as const,
        nationality: '',
        fighting_style: '',
        hometown: '',
        wins: fighter1Profile.wins || 0,
        losses: fighter1Profile.losses || 0,
        draws: fighter1Profile.draws || 0,
        knockouts: 0,
        points: fighter1Profile.points || 0,
        tier: (fighter1Profile.tier || 'Amateur') as any,
        weight_class: fighter1Profile.weight_class || 'Unknown',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        last_active: new Date().toISOString()
      } as FighterProfile : undefined,
      fighter2: fighter2Profile ? {
        id: fighter2Profile.user_id,
        user_id: fighter2Profile.user_id,
        name: fighter2Profile.name || 'Unknown Fighter',
        handle: fighter2Profile.handle || 'unknown',
        platform: 'PC' as const,
        platform_id: '',
        timezone: fightData.timezone || 'UTC',
        weight: 0,
        reach: 0,
        stance: 'orthodox' as const,
        nationality: '',
        fighting_style: '',
        hometown: '',
        wins: fighter2Profile.wins || 0,
        losses: fighter2Profile.losses || 0,
        draws: fighter2Profile.draws || 0,
        knockouts: 0,
        points: fighter2Profile.points || 0,
        tier: (fighter2Profile.tier || 'Amateur') as any,
        weight_class: fighter2Profile.weight_class || 'Unknown',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        last_active: new Date().toISOString()
      } as FighterProfile : undefined,
      scheduled_date: fightData.scheduled_date,
      timezone: fightData.timezone || 'UTC',
      platform: fightData.platform || 'PC',
      connection_notes: fightData.connection_notes,
      house_rules: fightData.house_rules,
      weight_class: fightData.weight_class || 'Unknown',
      status: (fightData.status || 'Scheduled') as 'Scheduled' | 'Completed' | 'Cancelled' | 'Disputed',
      match_type: (fightData as any).match_type,
      match_score: (fightData as any).match_score,
      created_at: fightData.created_at || new Date().toISOString()
    };

    // Create notifications for both fighters
    await this.createFightScheduledNotifications(scheduledFight);

    return scheduledFight;
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
      .order('scheduled_date', { ascending: true });

    if (error) throw error;
    return data || [];
  }

  // Get upcoming fights (next 7 days)
  async getUpcomingFights(fighterId?: string): Promise<ScheduledFight[]> {
    const now = new Date();
    const nextWeek = new Date();
    nextWeek.setDate(nextWeek.getDate() + 7);

    let query = supabase
      .from('scheduled_fights')
      .select(`
        *,
        fighter1:fighter_profiles!fighter1_id(*),
        fighter2:fighter_profiles!fighter2_id(*)
      `)
      .eq('status', 'Scheduled')
      .gte('scheduled_date', now.toISOString())
      .lte('scheduled_date', nextWeek.toISOString())
      .order('scheduled_date', { ascending: true });

    if (fighterId) {
      query = query.or(`fighter1_id.eq.${fighterId},fighter2_id.eq.${fighterId}`);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  // Submit fight result
  async submitFightResult(result: FightResult): Promise<FightRecord> {
    // Get the scheduled fight details
    const { data: fight, error: fightError } = await supabase
      .from('scheduled_fights')
      .select('*')
      .eq('id', result.fight_id)
      .single();

    if (fightError || !fight) {
      throw new Error('Scheduled fight not found');
    }

    // Determine opponent ID and name
    const isFighter1 = result.fighter_id === fight.fighter1_id;
    const opponentId = isFighter1 ? fight.fighter2_id : fight.fighter1_id;
    const opponentName = isFighter1 
      ? (await this.getFighterName(fight.fighter2_id))
      : (await this.getFighterName(fight.fighter1_id));

    // Calculate points earned for this fighter
    const pointsEarned = this.calculatePoints(result.result, result.method);

    // Determine opponent's result (opposite of this fighter's result)
    let opponentResult: 'Win' | 'Loss' | 'Draw' = 'Loss';
    if (result.result === 'Win') {
      opponentResult = 'Loss';
    } else if (result.result === 'Loss') {
      opponentResult = 'Win';
    } else {
      opponentResult = 'Draw';
    }

    // Calculate opponent's points
    // Note: KO/TKO bonus only applies to winners, not losers
    // If Fighter A wins by KO (+8), Fighter B loses by KO (-3, no bonus)
    // If Fighter A wins by Decision (+5), Fighter B loses by Decision (-3)
    // For draws, both get 0 points regardless of method
    const opponentMethod = result.method; // Keep the same method for record-keeping
    const opponentPointsEarned = this.calculatePoints(opponentResult, opponentMethod);

    // Create fight record for this fighter
    const { data: fightRecord, error: recordError } = await supabase
      .from('fight_records')
      .insert({
        fighter_id: result.fighter_id,
        opponent_name: opponentName,
        result: result.result,
        method: result.method,
        round: result.round,
        date: new Date().toISOString().split('T')[0],
        weight_class: fight.weight_class,
        points_earned: pointsEarned,
        proof_url: result.proof_url,
        notes: result.notes
      })
      .select()
      .single();

    if (recordError) throw recordError;

    // Check if opponent already has a record for this fight
    const { data: existingOpponentRecord } = await supabase
      .from('fight_records')
      .select('id')
      .eq('fighter_id', opponentId)
      .eq('date', new Date().toISOString().split('T')[0])
      .eq('opponent_name', await this.getFighterName(result.fighter_id))
      .maybeSingle();

    // Create opponent's fight record if it doesn't exist
    if (!existingOpponentRecord) {
      const thisFighterName = await this.getFighterName(result.fighter_id);
      
      await supabase
        .from('fight_records')
        .insert({
          fighter_id: opponentId,
          opponent_name: thisFighterName,
          result: opponentResult,
          method: opponentMethod, // Use the method (KO/TKO for losers doesn't add bonus)
          round: result.round,
          date: new Date().toISOString().split('T')[0],
          weight_class: fight.weight_class,
          points_earned: opponentPointsEarned,
          proof_url: result.proof_url, // Same proof URL
          notes: `Auto-created from opponent's submission`
        });
    }

    // Check if both fighters have submitted results
    await this.checkFightCompletion(result.fight_id);

    return fightRecord;
  }

  // Check if both fighters have submitted results
  private async checkFightCompletion(fightId: string): Promise<void> {
    const { data: fight, error: fightError } = await supabase
      .from('scheduled_fights')
      .select('*')
      .eq('id', fightId)
      .single();

    if (fightError || !fight) return;

    // Check if both fighters have submitted results
    const { data: results, error: resultsError } = await supabase
      .from('fight_records')
      .select('fighter_id')
      .eq('date', new Date().toISOString().split('T')[0])
      .or(`fighter_id.eq.${fight.fighter1_id},fighter_id.eq.${fight.fighter2_id}`);

    if (resultsError || !results || results.length < 2) return;

    // Check if results match
    const fighter1Result = results.find(r => r.fighter_id === fight.fighter1_id);
    const fighter2Result = results.find(r => r.fighter_id === fight.fighter2_id);

    if (fighter1Result && fighter2Result) {
      // Results match - auto-complete the fight
      await this.completeFight(fightId);
    } else {
      // Results don't match - create dispute
      await this.createInternalDispute(fightId, fight.fighter1_id, fight.fighter2_id);
    }
  }

  // Complete a fight
  private async completeFight(fightId: string): Promise<void> {
    const { error } = await supabase
      .from('scheduled_fights')
      .update({ status: 'Completed' })
      .eq('id', fightId);

    if (error) throw error;

    // Check if this fight is part of a tournament bracket and auto-advance winner
    await this.handleTournamentFightCompletion(fightId);

    // Create completion notifications
    await this.createFightCompletedNotifications(fightId);
  }

  // Handle tournament fight completion - auto-advance winner
  private async handleTournamentFightCompletion(fightId: string): Promise<void> {
    try {
      // Find tournament bracket linked to this fight
      const { data: bracket, error: bracketError } = await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .select('*')
        .eq('scheduled_fight_id', fightId)
        .single();

      if (bracketError || !bracket) {
        // Not a tournament fight, skip
        return;
      }

      // Get fight details to determine winner
      const { data: fight, error: fightError } = await supabase
        .from('scheduled_fights')
        .select('*')
        .eq('id', fightId)
        .single();

      if (fightError || !fight) return;

      // Get fight results to determine winner
      const { data: results } = await supabase
        .from('fight_records')
        .select('fighter_id, result')
        .in('fighter_id', [fight.fighter1_id, fight.fighter2_id])
        .order('created_at', { ascending: false })
        .limit(2);

      if (!results || results.length < 2) return;

      // Determine winner
      const fighter1Result = results.find(r => r.fighter_id === fight.fighter1_id);
      const fighter2Result = results.find(r => r.fighter_id === fight.fighter2_id);

      if (!fighter1Result || !fighter2Result) return;

      let winnerId: string | undefined;
      if (fighter1Result.result === 'Win') {
        winnerId = fight.fighter1_id;
      } else if (fighter2Result.result === 'Win') {
        winnerId = fight.fighter2_id;
      }

      if (winnerId && bracket.id) {
        // Auto-advance winner to next round
        await TournamentService.advanceWinner(bracket.id, winnerId);
      }
    } catch (error) {
      console.error('Error handling tournament fight completion:', error);
      // Don't throw - tournament advancement is not critical for fight completion
    }
  }

  // Create dispute when results don't match
  private async createInternalDispute(fightId: string, fighter1Id: string, fighter2Id: string): Promise<void> {
    const { error } = await supabase
      .from('disputes')
      .insert({
        fight_id: fightId,
        disputer_id: fighter1Id, // First fighter to submit
        reason: 'Conflicting fight results submitted',
        status: 'Open'
      });

    if (error) throw error;

    // Update fight status
    await supabase
      .from('scheduled_fights')
      .update({ status: 'Disputed' })
      .eq('id', fightId);

    // Create dispute notifications
    await this.createDisputeNotifications(fightId);
  }

  // Create dispute
  public async createDispute(request: DisputeRequest): Promise<Dispute> {
    const { data, error } = await supabase
      .from('disputes')
      .insert({
        fight_id: request.fight_id,
        disputer_id: request.disputer_id,
        reason: request.reason,
        evidence_urls: request.evidence_urls || [],
        status: 'Open'
      })
      .select(`
        *,
        fight:scheduled_fights!fight_id(*)
      `)
      .single();

    if (error) throw error;

    // Update fight status
    await supabase
      .from('scheduled_fights')
      .update({ status: 'Disputed' })
      .eq('id', request.fight_id);

    return data;
  }

  // Get disputes
  async getDisputes(status?: string): Promise<Dispute[]> {
    let query = supabase
      .from('disputes')
      .select(`
        *,
        fight:scheduled_fights!fight_id(*),
        disputer:fighter_profiles!disputer_id(*)
      `)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  // Resolve dispute
  async resolveDispute(disputeId: string, resolution: string, adminNotes?: string): Promise<void> {
    const { error } = await supabase
      .from('disputes')
      .update({
        status: 'Resolved',
        resolution,
        admin_notes: adminNotes,
        resolved_at: new Date().toISOString()
      })
      .eq('id', disputeId);

    if (error) throw error;

    // Update fight status back to completed
    const { data: dispute, error: disputeError } = await supabase
      .from('disputes')
      .select('fight_id')
      .eq('id', disputeId)
      .single();

    if (!disputeError && dispute) {
      await supabase
        .from('scheduled_fights')
        .update({ status: 'Completed' })
        .eq('id', dispute.fight_id);
    }
  }

  // Cancel a scheduled fight
  async cancelFight(fightId: string, reason?: string): Promise<void> {
    const { error } = await supabase
      .from('scheduled_fights')
      .update({ 
        status: 'Cancelled',
        connection_notes: reason ? `Cancelled: ${reason}` : 'Cancelled'
      })
      .eq('id', fightId);

    if (error) throw error;

    // Create cancellation notifications
    await this.createFightCancelledNotifications(fightId);
  }

  // Get scheduling statistics
  async getScheduleStats(): Promise<ScheduleStats> {
    const { data: fights, error } = await supabase
      .from('scheduled_fights')
      .select('status, scheduled_date, created_at');

    if (error) throw error;

    const stats = {
      total_scheduled: fights.length,
      completed_fights: fights.filter(f => f.status === 'Completed').length,
      cancelled_fights: fights.filter(f => f.status === 'Cancelled').length,
      disputed_fights: fights.filter(f => f.status === 'Disputed').length,
      completion_rate: 0,
      average_fight_duration: 0
    };

    // Calculate completion rate
    if (stats.total_scheduled > 0) {
      stats.completion_rate = (stats.completed_fights / stats.total_scheduled) * 100;
    }

    // Calculate average fight duration (simplified)
    const completedFights = fights.filter(f => f.status === 'Completed');
    if (completedFights.length > 0) {
      const totalDuration = completedFights.reduce((sum, fight) => {
        const scheduled = new Date(fight.scheduled_date);
        const created = new Date(fight.created_at);
        return sum + (scheduled.getTime() - created.getTime());
      }, 0);
      
      stats.average_fight_duration = totalDuration / completedFights.length / (1000 * 60 * 60 * 24); // Days
    }

    return stats;
  }

  // Helper methods
  private calculatePoints(result: string, method: string): number {
    let points = 0;
    
    if (result === 'Win') points = 5;
    else if (result === 'Loss') points = -3; // CORRECTED: Loss = -3 points (not -2)
    else if (result === 'Draw') points = 0;
    
    // KO/TKO bonus (+3) only applies to winners
    if (result === 'Win' && (method === 'KO' || method === 'TKO')) {
      points += 3;
    }
    
    return points;
  }

  private async getFighterName(fighterId: string): Promise<string> {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select('name')
      .eq('id', fighterId)
      .maybeSingle();

    if (error || !data) return 'Unknown Fighter';
    return data.name || 'Unknown Fighter';
  }

  // Notification methods
  private async createFightScheduledNotifications(fight: ScheduledFight): Promise<void> {
    // Get user IDs from fighter1 and fighter2 objects if available, otherwise use fighter1_id/fighter2_id
    const fighterUserIds: string[] = [];
    
    // Try to get user_id from fighter objects first (they should have user_id)
    if (fight.fighter1?.id) {
      fighterUserIds.push(fight.fighter1.id);
    } else if (fight.fighter1_id) {
      fighterUserIds.push(fight.fighter1_id);
    }
    
    if (fight.fighter2?.id) {
      fighterUserIds.push(fight.fighter2.id);
    } else if (fight.fighter2_id) {
      fighterUserIds.push(fight.fighter2_id);
    }
    
    // If we still don't have user_ids (they might be profile IDs), query fighter_profiles
    // But only if we have fewer than 2 user_ids
    if (fighterUserIds.length < 2) {
      // Check if the IDs look like UUIDs (profile IDs) - if so, query fighter_profiles
      const profileIds = [fight.fighter1_id, fight.fighter2_id].filter(Boolean);
      if (profileIds.length > 0) {
        const { data: fighters, error } = await supabase
          .from('fighter_profiles')
          .select('user_id, name')
          .in('id', profileIds)
          .limit(2);

        if (!error && fighters && fighters.length > 0) {
          // Replace or add user_ids from the query
          const queriedUserIds = fighters.map(f => f.user_id).filter(Boolean);
          fighterUserIds.length = 0; // Clear and replace
          fighterUserIds.push(...queriedUserIds);
        }
      }
    }
    
    // Create notifications for both fighters
    for (const userId of fighterUserIds) {
      if (userId) {
        await supabase
          .from('notifications')
          .insert({
            user_id: userId,
            type: 'Match',
            title: 'Fight Scheduled!',
            message: `Your fight has been scheduled. Check your calendar for details.`,
            action_url: '/schedule'
          });
      }
    }
  }

  private async createFightCompletedNotifications(fightId: string): Promise<void> {
    const { data: fight, error } = await supabase
      .from('scheduled_fights')
      .select('fighter1_id, fighter2_id')
      .eq('id', fightId)
      .single();

    if (error || !fight) return;

    const fighters = [fight.fighter1_id, fight.fighter2_id];
    
    for (const fighterId of fighters) {
      const { data: fighter, error } = await supabase
        .from('fighter_profiles')
        .select('user_id, name')
        .eq('id', fighterId)
        .single();

      if (!error && fighter) {
        await supabase
          .from('notifications')
          .insert({
            user_id: fighter.user_id,
            type: 'Match',
            title: 'Fight Completed!',
            message: `Your fight has been completed. Check your updated record.`,
            action_url: '/profile'
          });
      }
    }
  }

  private async createDisputeNotifications(fightId: string): Promise<void> {
    const { data: fight, error } = await supabase
      .from('scheduled_fights')
      .select('fighter1_id, fighter2_id')
      .eq('id', fightId)
      .single();

    if (error || !fight) return;

    const fighters = [fight.fighter1_id, fight.fighter2_id];
    
    for (const fighterId of fighters) {
      const { data: fighter, error } = await supabase
        .from('fighter_profiles')
        .select('user_id, name')
        .eq('id', fighterId)
        .single();

      if (!error && fighter) {
        await supabase
          .from('notifications')
          .insert({
            user_id: fighter.user_id,
            type: 'Dispute',
            title: 'Fight Dispute Created',
            message: `A dispute has been created for your fight. Please provide additional information.`,
            action_url: '/disputes'
          });
      }
    }
  }

  private async createFightCancelledNotifications(fightId: string): Promise<void> {
    const { data: fight, error } = await supabase
      .from('scheduled_fights')
      .select('fighter1_id, fighter2_id')
      .eq('id', fightId)
      .single();

    if (error || !fight) return;

    const fighters = [fight.fighter1_id, fight.fighter2_id];
    
    for (const fighterId of fighters) {
      const { data: fighter, error } = await supabase
        .from('fighter_profiles')
        .select('user_id, name')
        .eq('id', fighterId)
        .single();

      if (!error && fighter) {
        await supabase
          .from('notifications')
          .insert({
            user_id: fighter.user_id,
            type: 'Match',
            title: 'Fight Cancelled',
            message: `Your scheduled fight has been cancelled.`,
            action_url: '/schedule'
          });
      }
    }
  }
}

export const schedulingService = new SchedulingService();
export {};
