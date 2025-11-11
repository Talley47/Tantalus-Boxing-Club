'use server'

import { createClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'

export async function getFighterAnalytics(fighterId: string) {
  const supabase = createClient()
  
  try {
    // Get fighter profile
    const { data: fighterProfile } = await supabase
      .from('fighter_profiles')
      .select('*')
      .eq('id', fighterId)
      .single()

    if (!fighterProfile) {
      return {
        error: 'Fighter profile not found',
      }
    }

    // Get fight records
    const { data: fightRecords } = await supabase
      .from('fight_records')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('date', { ascending: false })

    // Get training logs
    const { data: trainingLogs } = await supabase
      .from('training_logs')
      .select('*')
      .eq('fighter_id', fighterId)
      .order('date', { ascending: false })

    // Calculate analytics
    const totalFights = fightRecords.length
    const wins = fightRecords.filter(f => f.result === 'Win').length
    const losses = fightRecords.filter(f => f.result === 'Loss').length
    const draws = fightRecords.filter(f => f.result === 'Draw').length
    const winPercentage = totalFights > 0 ? (wins / totalFights) * 100 : 0

    const totalTrainingMinutes = trainingLogs.reduce((sum, log) => sum + log.duration_minutes, 0)
    const averageTrainingPerSession = trainingLogs.length > 0 ? totalTrainingMinutes / trainingLogs.length : 0

    // Recent performance (last 10 fights)
    const recentFights = fightRecords.slice(0, 10)
    const recentWins = recentFights.filter(f => f.result === 'Win').length
    const recentWinPercentage = recentFights.length > 0 ? (recentWins / recentFights.length) * 100 : 0

    // Training frequency (last 30 days)
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    
    const recentTrainingLogs = trainingLogs.filter(log => 
      new Date(log.date) >= thirtyDaysAgo
    )
    const trainingFrequency = recentTrainingLogs.length

    // Weight class distribution
    const weightClassStats = fightRecords.reduce((acc, fight) => {
      acc[fight.weight_class] = (acc[fight.weight_class] || 0) + 1
      return acc
    }, {} as Record<string, number>)

    // Method of victory
    const methodStats = fightRecords
      .filter(f => f.result === 'Win')
      .reduce((acc, fight) => {
        acc[fight.method] = (acc[fight.method] || 0) + 1
        return acc
      }, {} as Record<string, number>)

    return {
      success: true,
      analytics: {
        fighterProfile,
        totalFights,
        wins,
        losses,
        draws,
        winPercentage: Math.round(winPercentage * 100) / 100,
        recentWinPercentage: Math.round(recentWinPercentage * 100) / 100,
        totalTrainingMinutes,
        averageTrainingPerSession: Math.round(averageTrainingPerSession),
        trainingFrequency,
        weightClassStats,
        methodStats,
        fightRecords,
        trainingLogs: recentTrainingLogs,
      }
    }
  } catch (error) {
    logger.error('Analytics fetch error', { fighterId, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getLeagueAnalytics() {
  const supabase = createClient()
  
  try {
    // Get all fighters
    const { data: fighters } = await supabase
      .from('fighter_profiles')
      .select('*')
      .order('points', { ascending: false })

    // Get all fight records
    const { data: fightRecords } = await supabase
      .from('fight_records')
      .select('*')
      .order('date', { ascending: false })

    // Get all tournaments
    const { data: tournaments } = await supabase
      .from('tournaments')
      .select('*')
      .order('created_at', { ascending: false })

    // Calculate league statistics
    const totalFighters = fighters.length
    const totalFights = fightRecords.length
    const totalTournaments = tournaments.length

    // Tier distribution
    const tierDistribution = fighters.reduce((acc, fighter) => {
      acc[fighter.tier] = (acc[fighter.tier] || 0) + 1
      return acc
    }, {} as Record<string, number>)

    // Weight class distribution
    const weightClassDistribution = fighters.reduce((acc, fighter) => {
      acc[fighter.weight_class] = (acc[fighter.weight_class] || 0) + 1
      return acc
    }, {} as Record<string, number>)

    // Recent activity (last 30 days)
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    
    const recentFights = fightRecords.filter(fight => 
      new Date(fight.date) >= thirtyDaysAgo
    )
    const recentTournaments = tournaments.filter(tournament => 
      new Date(tournament.created_at) >= thirtyDaysAgo
    )

    // Top performers
    const topFighters = fighters.slice(0, 10)

    return {
      success: true,
      analytics: {
        totalFighters,
        totalFights,
        totalTournaments,
        tierDistribution,
        weightClassDistribution,
        recentFights: recentFights.length,
        recentTournaments: recentTournaments.length,
        topFighters,
        recentActivity: {
          fights: recentFights,
          tournaments: recentTournaments,
        }
      }
    }
  } catch (error) {
    logger.error('League analytics fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

