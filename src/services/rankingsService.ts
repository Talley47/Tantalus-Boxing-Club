import { supabase } from './supabase';
import { FighterProfile } from '../types';
import { filterAdminFighters } from '../utils/filterAdmins';

export interface RankingEntry {
  rank: number;
  fighter_id: string;
  name: string;
  handle: string;
  tier: string;
  points: number;
  wins: number;
  losses: number;
  draws: number;
  knockouts: number;
  win_percentage: number;
  ko_percentage: number;
  weight_class: string;
  recent_form: string[]; // Last 5 results: ['W', 'L', 'W', 'D', 'W']
  head_to_head?: { [opponentId: string]: { wins: number; losses: number } };
  avg_opponent_points?: number;
  current_streak?: number;
  consecutive_losses?: number;
}

export interface TierThreshold {
  tier: string;
  min_points: number;
  max_points?: number;
}

export const TIER_THRESHOLDS: TierThreshold[] = [
  { tier: 'Amateur', min_points: 0, max_points: 29 },      // ≤29 points (default start)
  { tier: 'Semi-Pro', min_points: 30, max_points: 69 },      // 30-69 points
  { tier: 'Pro', min_points: 70, max_points: 139 },          // 70-139 points
  { tier: 'Contender', min_points: 140, max_points: 279 },  // 140-279 points
  { tier: 'Elite', min_points: 280 },                        // ≥280 points (eligible for live/media benefits)
];

// Get overall rankings (all fighters, regardless of weight class)
export const getOverallRankings = async (limit: number = 1000): Promise<RankingEntry[]> => {
  try {
    // Query fighter profiles (no JOIN since there's no FK relationship)
    // Increased limit to 1000 to ensure all fighters are included
    const { data: fighters, error } = await supabase
      .from('fighter_profiles')
      .select(`
        user_id,
        name,
        handle,
        tier,
        points,
        wins,
        losses,
        draws,
        knockouts,
        win_percentage,
        ko_percentage,
        weight_class
      `)
      .not('user_id', 'is', null)
      .order('points', { ascending: false })
      .limit(limit);

    if (error) throw error;
    if (!fighters || fighters.length === 0) return [];

    console.log(`[getOverallRankings] Fetched ${fighters.length} fighters from database`);

    // Filter out admin users
    const filteredFighters = await filterAdminFighters(fighters);
    
    console.log(`[getOverallRankings] After admin filter: ${filteredFighters.length} fighters`);
    
    if (filteredFighters.length === 0) return [];

    // Get fight records for tiebreakers
    const fighterIds = filteredFighters.map(f => f.user_id);
    const { data: fightRecords } = await supabase
      .from('fight_records')
      .select('*')
      .in('fighter_id', fighterIds)
      .order('date', { ascending: false });

    // Build rankings with tiebreakers
    const rankings = await calculateRankingsWithTiebreakers(filteredFighters, fightRecords || []);

    return rankings;
  } catch (error) {
    console.error('Error fetching overall rankings:', error);
    return [];
  }
};

// Get rankings by weight class
export const getRankingsByWeightClass = async (
  weightClass: string,
  limit: number = 1000
): Promise<RankingEntry[]> => {
  try {
    // Query fighter profiles (no JOIN since there's no FK relationship)
    // Increased limit to 1000 to ensure all fighters are included
    const { data: fighters, error } = await supabase
      .from('fighter_profiles')
      .select(`
        user_id,
        name,
        handle,
        tier,
        points,
        wins,
        losses,
        draws,
        knockouts,
        win_percentage,
        ko_percentage,
        weight_class
      `)
      .eq('weight_class', weightClass)
      .not('user_id', 'is', null)
      .order('points', { ascending: false })
      .limit(limit);

    if (error) throw error;
    if (!fighters || fighters.length === 0) return [];

    console.log(`[getRankingsByWeightClass] Fetched ${fighters.length} fighters for ${weightClass} from database`);

    // Filter out admin users
    let filteredFighters = await filterAdminFighters(fighters);
    
    console.log(`[getRankingsByWeightClass] After admin filter: ${filteredFighters.length} fighters for ${weightClass}`);
    
    if (filteredFighters.length === 0) return [];

    // Get fight records for tiebreakers
    const fighterIds = filteredFighters.map(f => f.user_id);
    const { data: fightRecords } = await supabase
      .from('fight_records')
      .select('*')
      .in('fighter_id', fighterIds)
      .order('date', { ascending: false });

    // Build rankings with tiebreakers
    const rankings = await calculateRankingsWithTiebreakers(filteredFighters, fightRecords || []);

    return rankings;
  } catch (error) {
    console.error('Error fetching weight class rankings:', error);
    return [];
  }
};

// Calculate rankings with tiebreakers
async function calculateRankingsWithTiebreakers(
  fighters: any[],
  fightRecords: any[]
): Promise<RankingEntry[]> {
  // Group fight records by fighter
  const recordsByFighter = new Map<string, any[]>();
  fightRecords.forEach(record => {
    if (!recordsByFighter.has(record.fighter_id)) {
      recordsByFighter.set(record.fighter_id, []);
    }
    recordsByFighter.get(record.fighter_id)!.push(record);
  });

  // Build ranking entries with tiebreakers
  const rankingEntries: RankingEntry[] = fighters.map(fighter => {
    const records = recordsByFighter.get(fighter.user_id) || [];
    const recentForm = records
      .slice(0, 5)
      .map(r => {
        if (r.result === 'Win') return 'W';
        if (r.result === 'Loss') return 'L';
        return 'D';
      });

    // Calculate head-to-head records
    const headToHead: { [opponentName: string]: { wins: number; losses: number } } = {};
    records.forEach(record => {
      if (!headToHead[record.opponent_name]) {
        headToHead[record.opponent_name] = { wins: 0, losses: 0 };
      }
      if (record.result === 'Win') headToHead[record.opponent_name].wins++;
      if (record.result === 'Loss') headToHead[record.opponent_name].losses++;
    });

    // Calculate average opponent points (simplified - would need opponent data)
    // For now, use a placeholder calculation
    const avgOpponentPoints = records.length > 0
      ? records.reduce((sum, r) => sum + (r.points_earned || 0), 0) / records.length
      : 0;

    // Calculate current streak
    let currentStreak = 0;
    let streakType: 'W' | 'L' | 'D' | null = null;
    for (const record of records.slice(0, 10)) {
      const result = record.result === 'Win' ? 'W' : record.result === 'Loss' ? 'L' : 'D';
      if (streakType === null) {
        streakType = result;
        currentStreak = 1;
      } else if (streakType === result) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate consecutive losses
    let consecutiveLosses = 0;
    for (const record of records.slice(0, 10)) {
      if (record.result === 'Loss') {
        consecutiveLosses++;
      } else {
        break;
      }
    }

    return {
      rank: 0, // Will be assigned after sorting
      fighter_id: fighter.user_id,
      name: fighter.name || 'Unknown',
      handle: fighter.handle || 'unknown',
      tier: fighter.tier || 'Amateur',
      points: fighter.points || 0,
      wins: fighter.wins || 0,
      losses: fighter.losses || 0,
      draws: fighter.draws || 0,
      knockouts: fighter.knockouts || 0,
      win_percentage: fighter.win_percentage || 0,
      ko_percentage: fighter.ko_percentage || 0,
      weight_class: fighter.weight_class || 'Unknown',
      recent_form: recentForm,
      head_to_head: headToHead,
      avg_opponent_points: avgOpponentPoints,
      current_streak: streakType === 'W' ? currentStreak : streakType === 'L' ? -currentStreak : 0,
      consecutive_losses: consecutiveLosses,
    };
  });

  // Sort with tiebreakers
  rankingEntries.sort((a, b) => {
    // Primary: Points (descending)
    if (b.points !== a.points) return b.points - a.points;

    // Tiebreaker 1: Head-to-head (if they've fought)
    const headToHeadResult = compareHeadToHead(a, b);
    if (headToHeadResult !== 0) return headToHeadResult;

    // Tiebreaker 2: KO Percentage (descending)
    if (b.ko_percentage !== a.ko_percentage) {
      return b.ko_percentage - a.ko_percentage;
    }

    // Tiebreaker 3: Average Opponent Points (descending)
    const avgA = a.avg_opponent_points || 0;
    const avgB = b.avg_opponent_points || 0;
    if (avgB !== avgA) return avgB - avgA;

    // Tiebreaker 4: Recent Form (last 5 results)
    const formResult = compareRecentForm(a.recent_form, b.recent_form);
    if (formResult !== 0) return formResult;

    // Final tiebreaker: Win percentage
    return (b.win_percentage || 0) - (a.win_percentage || 0);
  });

  // Assign ranks
  rankingEntries.forEach((entry, index) => {
    entry.rank = index + 1;
  });

  return rankingEntries;
}

// Compare head-to-head records
function compareHeadToHead(a: RankingEntry, b: RankingEntry): number {
  if (!a.head_to_head || !b.head_to_head) return 0;

  // Check if they've fought each other
  const aVsB = a.head_to_head[b.name];
  const bVsA = b.head_to_head[a.name];

  if (!aVsB && !bVsA) return 0;

  const aWins = aVsB?.wins || 0;
  const bWins = bVsA?.wins || 0;

  if (aWins > bWins) return -1;
  if (bWins > aWins) return 1;
  return 0;
}

// Compare recent form (last 5 results)
function compareRecentForm(formA: string[], formB: string[]): number {
  const value = { W: 3, D: 1, L: 0 };
  let scoreA = 0;
  let scoreB = 0;

  for (let i = 0; i < Math.max(formA.length, formB.length); i++) {
    const aResult = formA[i] || '';
    const bResult = formB[i] || '';
    scoreA += value[aResult as keyof typeof value] || 0;
    scoreB += value[bResult as keyof typeof value] || 0;

    // Earlier results are worth more
    const weight = 5 - i;
    scoreA *= weight;
    scoreB *= weight;
  }

  return scoreB - scoreA;
}

// Get tier for given points (matches database function)
export function getTierForPoints(points: number): string {
  if (points >= 280) return 'Elite';      // ≥280 points
  if (points >= 140) return 'Contender';   // 140-279 points
  if (points >= 70) return 'Pro';          // 70-139 points
  if (points >= 30) return 'Semi-Pro';    // 30-69 points
  return 'Amateur';                        // ≤29 points (default start)
}

// Check if fighter should be demoted (5 losses in a row)
export function shouldDemote(consecutiveLosses: number): boolean {
  return consecutiveLosses >= 5;
}

// Check if fighter should be promoted back (5 wins in a row after demotion)
export function shouldPromoteBack(consecutiveWins: number): boolean {
  return consecutiveWins >= 5;
}

// Get weight classes for filtering
export const getAvailableWeightClasses = async (): Promise<string[]> => {
  try {
    const { data, error } = await supabase
      .from('fighter_profiles')
      .select('weight_class')
      .not('weight_class', 'is', null);

    if (error) throw error;

    const weightClasses = new Set<string>();
    data?.forEach(f => {
      if (f.weight_class) weightClasses.add(f.weight_class);
    });

    return Array.from(weightClasses).sort();
  } catch (error) {
    console.error('Error fetching weight classes:', error);
    return [];
  }
};
