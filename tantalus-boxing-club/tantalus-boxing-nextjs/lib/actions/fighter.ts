'use server'

import { createClient } from '@/lib/supabase/server'
import { fightRecordSchema, matchmakingSchema } from '@/lib/validations/fighter'
import { logger } from '@/lib/logger'
import { rateLimit, RATE_LIMITS } from '@/lib/rate-limit'
import { headers } from 'next/headers'
import { redirect } from 'next/navigation'

export async function createFightRecord(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  // Rate limiting
  const headersList = headers()
  const ip = headersList.get('x-forwarded-for') || 'unknown'
  
  const rateLimitResult = await rateLimit({
    ...RATE_LIMITS.API,
    identifier: `fight_record:${user.id}`,
  })

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for fight record creation', { userId: user.id, ip })
    return {
      error: 'Too many requests. Please try again later.',
    }
  }

  // Extract and validate form data
  const rawData = {
    opponentName: formData.get('opponentName') as string,
    result: formData.get('result') as string,
    method: formData.get('method') as string,
    round: parseInt(formData.get('round') as string),
    date: formData.get('date') as string,
    weightClass: formData.get('weightClass') as string,
    pointsEarned: parseInt(formData.get('pointsEarned') as string),
    proofUrl: formData.get('proofUrl') as string,
    notes: formData.get('notes') as string,
  }

  // Validate input
  const validatedFields = fightRecordSchema.safeParse(rawData)
  
  if (!validatedFields.success) {
    return {
      error: 'Invalid input',
      details: validatedFields.error.flatten().fieldErrors,
    }
  }

  try {
    // Get fighter profile
    const { data: fighterProfile } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', user.id)
      .single()

    if (!fighterProfile) {
      return {
        error: 'Fighter profile not found',
      }
    }

    // Create fight record
    const { error } = await supabase
      .from('fight_records')
      .insert({
        fighter_id: fighterProfile.id,
        opponent_name: validatedFields.data.opponentName,
        result: validatedFields.data.result,
        method: validatedFields.data.method,
        round: validatedFields.data.round,
        date: validatedFields.data.date,
        weight_class: validatedFields.data.weightClass,
        points_earned: validatedFields.data.pointsEarned,
        proof_url: validatedFields.data.proofUrl || null,
        notes: validatedFields.data.notes || null,
      })

    if (error) {
      logger.error('Fight record creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create fight record',
      }
    }

    // Update fighter stats
    await updateFighterStats(fighterProfile.id, validatedFields.data)

    logger.info('Fight record created successfully', { 
      userId: user.id, 
      fighterId: fighterProfile.id,
      result: validatedFields.data.result 
    })
    
    return {
      success: true,
      message: 'Fight record created successfully',
    }
  } catch (error) {
    logger.error('Fight record creation error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function requestMatchmaking(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  // Rate limiting
  const headersList = headers()
  const ip = headersList.get('x-forwarded-for') || 'unknown'
  
  const rateLimitResult = await rateLimit({
    ...RATE_LIMITS.MATCHMAKING,
    identifier: `matchmaking:${user.id}`,
  })

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for matchmaking request', { userId: user.id, ip })
    return {
      error: 'Too many matchmaking requests. Please try again later.',
    }
  }

  // Extract and validate form data
  const rawData = {
    weightClass: formData.get('weightClass') as string,
    tier: formData.get('tier') as string,
    maxDistance: parseInt(formData.get('maxDistance') as string),
    preferredDate: formData.get('preferredDate') as string,
    notes: formData.get('notes') as string,
  }

  // Validate input
  const validatedFields = matchmakingSchema.safeParse(rawData)
  
  if (!validatedFields.success) {
    return {
      error: 'Invalid input',
      details: validatedFields.error.flatten().fieldErrors,
    }
  }

  try {
    // Get fighter profile
    const { data: fighterProfile } = await supabase
      .from('fighter_profiles')
      .select('id, tier, weight_class')
      .eq('user_id', user.id)
      .single()

    if (!fighterProfile) {
      return {
        error: 'Fighter profile not found',
      }
    }

    // Create matchmaking request
    const { error } = await supabase
      .from('matchmaking_requests')
      .insert({
        fighter_id: fighterProfile.id,
        weight_class: validatedFields.data.weightClass,
        tier: validatedFields.data.tier,
        max_distance: validatedFields.data.maxDistance,
        preferred_date: validatedFields.data.preferredDate || null,
        notes: validatedFields.data.notes || null,
        status: 'pending',
      })

    if (error) {
      logger.error('Matchmaking request creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create matchmaking request',
      }
    }

    logger.info('Matchmaking request created successfully', { 
      userId: user.id, 
      fighterId: fighterProfile.id,
      weightClass: validatedFields.data.weightClass 
    })
    
    return {
      success: true,
      message: 'Matchmaking request submitted successfully',
    }
  } catch (error) {
    logger.error('Matchmaking request error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

async function updateFighterStats(fighterId: string, fightData: any) {
  const supabase = createClient()
  
  try {
    // Get current stats
    const { data: currentStats } = await supabase
      .from('fighter_profiles')
      .select('wins, losses, draws, points, knockouts')
      .eq('id', fighterId)
      .single()

    if (!currentStats) return

    // Calculate new stats
    const newWins = currentStats.wins + (fightData.result === 'Win' ? 1 : 0)
    const newLosses = currentStats.losses + (fightData.result === 'Loss' ? 1 : 0)
    const newDraws = currentStats.draws + (fightData.result === 'Draw' ? 1 : 0)
    const newPoints = currentStats.points + fightData.pointsEarned
    const newKnockouts = currentStats.knockouts + (fightData.method === 'KO' || fightData.method === 'TKO' ? 1 : 0)
    
    const totalFights = newWins + newLosses + newDraws
    const winPercentage = totalFights > 0 ? (newWins / totalFights) * 100 : 0
    const koPercentage = totalFights > 0 ? (newKnockouts / totalFights) * 100 : 0

    // Update fighter profile
    await supabase
      .from('fighter_profiles')
      .update({
        wins: newWins,
        losses: newLosses,
        draws: newDraws,
        points: newPoints,
        knockouts: newKnockouts,
        win_percentage: Math.round(winPercentage * 100) / 100,
        ko_percentage: Math.round(koPercentage * 100) / 100,
        updated_at: new Date().toISOString(),
      })
      .eq('id', fighterId)

    logger.info('Fighter stats updated', { 
      fighterId, 
      newWins, 
      newLosses, 
      newDraws, 
      newPoints 
    })
  } catch (error) {
    logger.error('Failed to update fighter stats', { fighterId, error })
  }
}

export async function getFighterRankings(weightClass?: string, tier?: string) {
  const supabase = createClient()
  
  try {
    let query = supabase
      .from('fighter_profiles')
      .select('*')
      .order('points', { ascending: false })
      .limit(50)

    if (weightClass) {
      query = query.eq('weight_class', weightClass)
    }

    if (tier) {
      query = query.eq('tier', tier)
    }

    const { data, error } = await query

    if (error) {
      logger.error('Failed to fetch fighter rankings', { error: error.message })
      return {
        error: 'Failed to fetch rankings',
      }
    }

    return {
      success: true,
      rankings: data || [],
    }
  } catch (error) {
    logger.error('Fighter rankings error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}