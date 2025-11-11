import { supabase, TABLES } from './supabase';
import { getRankingsByWeightClass, getOverallRankings, TIER_THRESHOLDS } from './rankingsService';
import { getAllowedWeightClasses } from '../utils/weightClassUtils';

export interface Tournament {
  id: string;
  name: string;
  format: 'Single Elimination' | 'Double Elimination' | 'Group Stage' | 'Swiss' | 'Round Robin';
  weight_class: string;
  max_participants: number;
  entry_fee: number;
  prize_pool: number;
  start_date: string;
  end_date: string;
  registration_deadline?: string;
  check_in_deadline?: string;
  status: 'Open' | 'In Progress' | 'Completed' | 'Cancelled';
  description?: string;
  min_tier?: string;
  min_points?: number;
  min_rank?: number;
  created_by: string;
  created_at: string;
  current_participants?: number;
  winner_id?: string;
}

export interface TournamentParticipant {
  id: string;
  tournament_id: string;
  fighter_id: string;
  seed: number | null;
  status: 'Registered' | 'Checked In' | 'Active' | 'Eliminated' | 'Withdrawn' | 'Bye';
  check_in_time?: string;
  registered_at: string;
  fighter_name?: string;
  fighter_tier?: string;
  fighter_points?: number;
}

export interface TournamentBracket {
  id: string;
  tournament_id: string;
  round: number;
  match_number: number;
  fighter1_id?: string;
  fighter2_id?: string;
  winner_id?: string;
  scheduled_fight_id?: string;
  scheduled_date?: string;
  deadline_date: string;
  fighter1_check_in?: string;
  fighter2_check_in?: string;
  status: 'Pending' | 'Scheduled' | 'In Progress' | 'Completed' | 'Bye' | 'No Show';
  fighter1_name?: string;
  fighter2_name?: string;
  winner_name?: string;
}

export interface TournamentResult {
  id: string;
  tournament_id: string;
  champion_id?: string;
  runner_up_id?: string;
  third_place_id?: string;
  total_participants: number;
  completion_date?: string;
  final_fight_id?: string;
  champion_name?: string;
  runner_up_name?: string;
  third_place_name?: string;
}

export class TournamentService {
  // Get all tournaments with filters
  static async getTournaments(status?: Tournament['status']): Promise<Tournament[]> {
    try {
      let query = supabase.from(TABLES.TOURNAMENTS).select('*').order('start_date', { ascending: true });

      if (status) {
        query = query.eq('status', status);
      }

      const { data, error } = await query;

      if (error) throw error;

      // Get participant counts
      const tournamentsWithCounts = await Promise.all(
        (data || []).map(async (tournament) => {
          const { count } = await supabase
            .from(TABLES.TOURNAMENT_PARTICIPANTS)
            .select('*', { count: 'exact', head: true })
            .eq('tournament_id', tournament.id);

          return {
            ...tournament,
            current_participants: count || 0,
          };
        })
      );

      return tournamentsWithCounts;
    } catch (error) {
      console.error('Error fetching tournaments:', error);
      throw error;
    }
  }

  // Get tournament by ID with full details
  static async getTournamentById(tournamentId: string): Promise<Tournament | null> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENTS)
        .select('*')
        .eq('id', tournamentId)
        .single();

      if (error) throw error;

      if (!data) return null;

      // Get participant count
      const { count } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('*', { count: 'exact', head: true })
        .eq('tournament_id', tournamentId);

      return {
        ...data,
        current_participants: count || 0,
      };
    } catch (error) {
      console.error('Error fetching tournament:', error);
      return null;
    }
  }

  // Check if fighter is eligible to join tournament
  static async checkEligibility(fighterId: string, tournamentId: string): Promise<{ eligible: boolean; reason?: string }> {
    try {
      const tournament = await this.getTournamentById(tournamentId);
      if (!tournament) {
        return { eligible: false, reason: 'Tournament not found' };
      }

      // Get fighter profile
      const { data: fighter, error: fighterError } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('*')
        .eq('id', fighterId)
        .single();

      if (fighterError || !fighter) {
        return { eligible: false, reason: 'Fighter profile not found' };
      }

      // Check weight class
      const allowedWeightClasses = getAllowedWeightClasses(fighter.weight_class);
      if (!allowedWeightClasses.includes(tournament.weight_class)) {
        return { eligible: false, reason: `Weight class mismatch. Tournament is for ${tournament.weight_class}` };
      }

      // Check tier requirement
      if (tournament.min_tier) {
        const tierHierarchy: Record<string, number> = {
          'Amateur': 1,
          'Semi-Pro': 2,
          'Pro': 3,
          'Contender': 4,
          'Elite': 5,
          'Champion': 6,
        };
        const fighterTierLevel = tierHierarchy[fighter.tier] || 0;
        const requiredTierLevel = tierHierarchy[tournament.min_tier] || 0;

        if (fighterTierLevel < requiredTierLevel) {
          return { eligible: false, reason: `Minimum tier required: ${tournament.min_tier}` };
        }
      }

      // Check points requirement
      if (tournament.min_points && fighter.points < tournament.min_points) {
        return { eligible: false, reason: `Minimum ${tournament.min_points} points required` };
      }

      // Check rank requirement
      if (tournament.min_rank) {
        const rankings = await getRankingsByWeightClass(fighter.weight_class);
        const fighterRank = rankings.findIndex(r => r.fighter_id === fighterId) + 1;
        if (fighterRank > tournament.min_rank) {
          return { eligible: false, reason: `Must be ranked in top ${tournament.min_rank}` };
        }
      }

      // Check if tournament is full
      const { count } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('*', { count: 'exact', head: true })
        .eq('tournament_id', tournamentId)
        .in('status', ['Registered', 'Checked In', 'Active']);

      if ((count || 0) >= tournament.max_participants) {
        return { eligible: false, reason: 'Tournament is full' };
      }

      // Check if already registered
      const { data: existing, error: existingError } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('fighter_id', fighterId)
        .maybeSingle(); // Use maybeSingle() instead of single() to handle "not found" gracefully

      // Handle 406 errors gracefully (RLS or query format issues)
      if (existingError) {
        // PGRST116 means no rows found, which is fine
        // 406 means Not Acceptable (often RLS blocking)
        if (existingError.code === 'PGRST116' || existingError.code === '406') {
          // Not found or blocked - assume not registered
          console.warn('Tournament participant check returned error (assuming not registered):', existingError);
        } else {
          // Other errors should be logged but don't block eligibility check
          console.warn('Error checking tournament participation:', existingError);
        }
      }

      if (existing) {
        return { eligible: false, reason: 'Already registered for this tournament' };
      }

      // Check registration deadline
      if (tournament.registration_deadline) {
        const deadline = new Date(tournament.registration_deadline);
        if (new Date() > deadline) {
          const deadlineStr = deadline.toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          });
          return { 
            eligible: false, 
            reason: `Registration deadline has passed. Deadline was: ${deadlineStr}` 
          };
        }
      }

      return { eligible: true };
    } catch (error) {
      console.error('Error checking eligibility:', error);
      return { eligible: false, reason: 'Error checking eligibility' };
    }
  }

  // Join tournament
  static async joinTournament(fighterId: string, tournamentId: string): Promise<void> {
    try {
      // Check eligibility
      const eligibility = await this.checkEligibility(fighterId, tournamentId);
      if (!eligibility.eligible) {
        throw new Error(eligibility.reason || 'Not eligible to join tournament');
      }

      // Get current participant count for seeding
      const { count } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('*', { count: 'exact', head: true })
        .eq('tournament_id', tournamentId);

      const seed = (count || 0) + 1;

      // Register fighter
      const { error } = await supabase.from(TABLES.TOURNAMENT_PARTICIPANTS).insert({
        tournament_id: tournamentId,
        fighter_id: fighterId,
        seed,
        status: 'Registered',
      });

      if (error) throw error;
    } catch (error) {
      console.error('Error joining tournament:', error);
      throw error;
    }
  }

  // Generate tournament brackets (Single Elimination)
  static async generateBrackets(tournamentId: string): Promise<void> {
    try {
      const tournament = await this.getTournamentById(tournamentId);
      if (!tournament) throw new Error('Tournament not found');

      // Get all checked-in participants
      const { data: participants, error: participantsError } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('*')
        .eq('tournament_id', tournamentId)
        .in('status', ['Checked In', 'Active'])
        .order('seed', { ascending: true });

      if (participantsError) throw participantsError;
      if (!participants || participants.length < 2) {
        throw new Error('Not enough participants to generate brackets');
      }

      // Calculate number of rounds
      const numParticipants = participants.length;
      const numRounds = Math.ceil(Math.log2(numParticipants));

      // Create first round brackets
      const brackets: Omit<TournamentBracket, 'id' | 'fighter1_name' | 'fighter2_name' | 'winner_name'>[] = [];
      const oneWeekFromNow = new Date();
      oneWeekFromNow.setDate(oneWeekFromNow.getDate() + 7);

      for (let i = 0; i < Math.floor(numParticipants / 2); i++) {
        brackets.push({
          tournament_id: tournamentId,
          round: 1,
          match_number: i + 1,
          fighter1_id: participants[i * 2].fighter_id,
          fighter2_id: participants[i * 2 + 1]?.fighter_id,
          deadline_date: oneWeekFromNow.toISOString(),
          status: 'Pending',
        });
      }

      // Add BYE if odd number of participants
      if (numParticipants % 2 === 1) {
        brackets.push({
          tournament_id: tournamentId,
          round: 1,
          match_number: brackets.length + 1,
          fighter1_id: participants[numParticipants - 1].fighter_id,
          fighter2_id: undefined,
          deadline_date: oneWeekFromNow.toISOString(),
          status: 'Bye',
          winner_id: participants[numParticipants - 1].fighter_id,
        });
      }

      // Create brackets for subsequent rounds
      let currentRound = 2;
      let currentRoundMatches = Math.ceil(numParticipants / 4);

      while (currentRoundMatches >= 1) {
        for (let i = 1; i <= currentRoundMatches; i++) {
          brackets.push({
            tournament_id: tournamentId,
            round: currentRound,
            match_number: i,
            deadline_date: oneWeekFromNow.toISOString(),
            status: 'Pending',
          });
        }
        currentRoundMatches = Math.ceil(currentRoundMatches / 2);
        currentRound++;
      }

      // Insert all brackets
      const { error } = await supabase.from(TABLES.TOURNAMENT_BRACKETS).insert(brackets);

      if (error) throw error;

      // Update tournament status
      await supabase
        .from(TABLES.TOURNAMENTS)
        .update({ status: 'In Progress' })
        .eq('id', tournamentId);
    } catch (error) {
      console.error('Error generating brackets:', error);
      throw error;
    }
  }

  // Get tournament brackets
  static async getTournamentBrackets(tournamentId: string): Promise<TournamentBracket[]> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .select('*')
        .eq('tournament_id', tournamentId)
        .order('round', { ascending: true })
        .order('match_number', { ascending: true });

      if (error) throw error;

      // Enrich with fighter names
      const enriched = await Promise.all(
        (data || []).map(async (bracket) => {
          const fighterNames: { [key: string]: string } = {};

          if (bracket.fighter1_id) {
            const { data } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('name')
              .eq('id', bracket.fighter1_id)
              .single();
            fighterNames[bracket.fighter1_id] = data?.name || 'Unknown';
          }

          if (bracket.fighter2_id) {
            const { data } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('name')
              .eq('id', bracket.fighter2_id)
              .single();
            fighterNames[bracket.fighter2_id] = data?.name || 'Unknown';
          }

          if (bracket.winner_id) {
            const { data } = await supabase
              .from(TABLES.FIGHTER_PROFILES)
              .select('name')
              .eq('id', bracket.winner_id)
              .single();
            fighterNames[bracket.winner_id] = data?.name || 'Unknown';
          }

          return {
            ...bracket,
            fighter1_name: bracket.fighter1_id ? fighterNames[bracket.fighter1_id] : undefined,
            fighter2_name: bracket.fighter2_id ? fighterNames[bracket.fighter2_id] : undefined,
            winner_name: bracket.winner_id ? fighterNames[bracket.winner_id] : undefined,
          };
        })
      );

      return enriched;
    } catch (error) {
      console.error('Error fetching brackets:', error);
      throw error;
    }
  }

  // Advance winner to next round
  static async advanceWinner(bracketId: string, winnerId: string): Promise<void> {
    try {
      const { data: bracket, error: bracketError } = await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .select('*')
        .eq('id', bracketId)
        .single();

      if (bracketError || !bracket) throw new Error('Bracket not found');

      // Update bracket with winner
      await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .update({
          winner_id: winnerId,
          status: 'Completed',
        })
        .eq('id', bracketId);

      // Find next round bracket
      const nextRound = bracket.round + 1;
      const nextMatchNumber = Math.ceil(bracket.match_number / 2);

      const { data: nextBracket } = await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .select('*')
        .eq('tournament_id', bracket.tournament_id)
        .eq('round', nextRound)
        .eq('match_number', nextMatchNumber)
        .single();

      if (nextBracket) {
        // Determine which fighter slot (1 or 2) based on match number
        const isOddMatch = bracket.match_number % 2 === 1;
        const updates: any = {};

        if (isOddMatch) {
          updates.fighter1_id = winnerId;
        } else {
          updates.fighter2_id = winnerId;
        }

        // Reset status if both fighters are now set
        if ((updates.fighter1_id && nextBracket.fighter2_id) || (updates.fighter2_id && nextBracket.fighter1_id)) {
          updates.status = 'Pending';
        }

        await supabase.from(TABLES.TOURNAMENT_BRACKETS).update(updates).eq('id', nextBracket.id);
      } else {
        // Tournament completed
        const { data: tournamentResult } = await supabase
          .from(TABLES.TOURNAMENT_RESULTS)
          .select('*')
          .eq('tournament_id', bracket.tournament_id)
          .single();

        if (!tournamentResult) {
          // Create tournament result
          await supabase.from(TABLES.TOURNAMENT_RESULTS).insert({
            tournament_id: bracket.tournament_id,
            champion_id: winnerId,
            completion_date: new Date().toISOString(),
          });
        }

        // Update tournament status
        await supabase
          .from(TABLES.TOURNAMENTS)
          .update({ status: 'Completed', winner_id: winnerId })
          .eq('id', bracket.tournament_id);
      }
    } catch (error) {
      console.error('Error advancing winner:', error);
      throw error;
    }
  }

  // Handle BYE - fighter who checked in gets BYE
  static async handleBye(bracketId: string): Promise<void> {
    try {
      const { data: bracket, error } = await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .select('*')
        .eq('id', bracketId)
        .single();

      if (error || !bracket) throw new Error('Bracket not found');

      // Check deadline
      const deadline = new Date(bracket.deadline_date);
      if (new Date() <= deadline) {
        throw new Error('Fight deadline has not passed yet');
      }

      // Determine winner based on check-in
      let winnerId: string | undefined;

      if (bracket.fighter1_check_in && !bracket.fighter2_check_in && bracket.fighter2_id) {
        winnerId = bracket.fighter1_id;
      } else if (bracket.fighter2_check_in && !bracket.fighter1_check_in && bracket.fighter1_id) {
        winnerId = bracket.fighter2_id;
      } else if (bracket.fighter1_id && !bracket.fighter2_id) {
        // Already a BYE
        winnerId = bracket.fighter1_id;
      }

      if (winnerId) {
        await this.advanceWinner(bracketId, winnerId);
        await supabase
          .from(TABLES.TOURNAMENT_BRACKETS)
          .update({ status: 'Bye' })
          .eq('id', bracketId);
      } else {
        // Both fighters didn't check in - mark as No Show
        await supabase
          .from(TABLES.TOURNAMENT_BRACKETS)
          .update({ status: 'No Show' })
          .eq('id', bracketId);
      }
    } catch (error) {
      console.error('Error handling BYE:', error);
      throw error;
    }
  }

  // Check in for a fight
  static async checkIn(bracketId: string, fighterId: string): Promise<void> {
    try {
      const { data: bracket, error } = await supabase
        .from(TABLES.TOURNAMENT_BRACKETS)
        .select('*')
        .eq('id', bracketId)
        .single();

      if (error || !bracket) throw new Error('Bracket not found');

      const updates: any = {};

      if (bracket.fighter1_id === fighterId) {
        updates.fighter1_check_in = new Date().toISOString();
      } else if (bracket.fighter2_id === fighterId) {
        updates.fighter2_check_in = new Date().toISOString();
      } else {
        throw new Error('Fighter not in this bracket');
      }

      await supabase.from(TABLES.TOURNAMENT_BRACKETS).update(updates).eq('id', bracketId);
    } catch (error) {
      console.error('Error checking in:', error);
      throw error;
    }
  }

  // Get tournament participants
  static async getTournamentParticipants(tournamentId: string): Promise<TournamentParticipant[]> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select(`
          *,
          fighter:fighter_profiles!fighter_id (
            name,
            tier,
            points
          )
        `)
        .eq('tournament_id', tournamentId)
        .order('seed', { ascending: true });

      if (error) throw error;

      return (data || []).map((p: any) => ({
        ...p,
        fighter_name: p.fighter?.name,
        fighter_tier: p.fighter?.tier,
        fighter_points: p.fighter?.points,
      }));
    } catch (error) {
      console.error('Error fetching participants:', error);
      throw error;
    }
  }

  // Get tournament results
  static async getTournamentResults(tournamentId: string): Promise<TournamentResult | null> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENT_RESULTS)
        .select(`
          *,
          champion:fighter_profiles!champion_id (name),
          runner_up:fighter_profiles!runner_up_id (name),
          third_place:fighter_profiles!third_place_id (name)
        `)
        .eq('tournament_id', tournamentId)
        .single();

      if (error) throw error;

      if (!data) return null;

      return {
        ...data,
        champion_name: (data as any).champion?.name,
        runner_up_name: (data as any).runner_up?.name,
        third_place_name: (data as any).third_place?.name,
      };
    } catch (error) {
      console.error('Error fetching tournament results:', error);
      return null;
    }
  }

  // Get all tournament champions
  static async getTournamentChampions(): Promise<any[]> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENT_CHAMPIONS)
        .select(`
          *,
          fighter:fighter_profiles!fighter_id (name, tier, points)
        `)
        .order('won_date', { ascending: false });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching champions:', error);
      return [];
    }
  }

  // Create tournament (Admin only)
  static async createTournament(tournament: Omit<Tournament, 'id' | 'created_at' | 'current_participants'>): Promise<Tournament> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENTS)
        .insert(tournament)
        .select()
        .single();

      if (error) throw error;
      return { ...data, current_participants: 0 };
    } catch (error) {
      console.error('Error creating tournament:', error);
      throw error;
    }
  }

  // Update tournament (Admin only)
  static async updateTournament(tournamentId: string, updates: Partial<Tournament>): Promise<Tournament> {
    try {
      const { data, error } = await supabase
        .from(TABLES.TOURNAMENTS)
        .update(updates)
        .eq('id', tournamentId)
        .select()
        .single();

      if (error) throw error;

      const { count } = await supabase
        .from(TABLES.TOURNAMENT_PARTICIPANTS)
        .select('*', { count: 'exact', head: true })
        .eq('tournament_id', tournamentId);

      return { ...data, current_participants: count || 0 };
    } catch (error) {
      console.error('Error updating tournament:', error);
      throw error;
    }
  }

  // Delete tournament (Admin only)
  static async deleteTournament(tournamentId: string): Promise<void> {
    try {
      const { error } = await supabase.from(TABLES.TOURNAMENTS).delete().eq('id', tournamentId);
      if (error) throw error;
    } catch (error) {
      console.error('Error deleting tournament:', error);
      throw error;
    }
  }
}
