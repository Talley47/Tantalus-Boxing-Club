'use server'

import { createClient } from '@/lib/supabase/server'
import { tournamentSchema } from '@/lib/validations/fighter'
import { logger } from '@/lib/logger'
import { rateLimit, RATE_LIMITS } from '@/lib/rate-limit'
import { headers } from 'next/headers'

export async function createTournament(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  // Rate limiting
  const headersList = await headers()
  const ip = headersList.get('x-forwarded-for') || 'unknown'
  
  const rateLimitResult = await rateLimit.limit(`tournament:${user.id}`)

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for tournament creation', { userId: user.id, ip })
    return {
      error: 'Too many requests. Please try again later.',
    }
  }

  // Extract and validate form data
  const rawData = {
    name: formData.get('name') as string,
    description: formData.get('description') as string,
    startDate: formData.get('startDate') as string,
    endDate: formData.get('endDate') as string,
    weightClass: formData.get('weightClass') as string,
    maxParticipants: parseInt(formData.get('maxParticipants') as string),
  }

  // Validate input
  const validatedFields = tournamentSchema.safeParse(rawData)
  
  if (!validatedFields.success) {
    return {
      error: 'Invalid input',
      details: validatedFields.error.flatten().fieldErrors,
    }
  }

  try {
    // Create tournament
    const { data, error } = await supabase
      .from('tournaments')
      .insert({
        name: validatedFields.data.name,
        description: validatedFields.data.description || null,
        start_date: validatedFields.data.startDate,
        end_date: validatedFields.data.endDate,
        weight_class: validatedFields.data.weightClass,
        max_participants: validatedFields.data.maxParticipants,
        current_participants: 0,
        entry_fee: 0, // Not in schema, default to 0
        prize_pool: 0, // Not in schema, default to 0
        status: 'upcoming',
        created_by: user.id,
      })
      .select()
      .single()

    if (error) {
      logger.error('Tournament creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create tournament',
      }
    }

    logger.info('Tournament created successfully', { 
      userId: user.id, 
      tournamentId: data.id,
      name: validatedFields.data.name 
    })
    
    return {
      success: true,
      message: 'Tournament created successfully',
      tournament: data,
    }
  } catch (error) {
    logger.error('Tournament creation error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function joinTournament(tournamentId: string) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
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

    // Check if already joined
    const { data: existingParticipation } = await supabase
      .from('tournament_participants')
      .select('id')
      .eq('tournament_id', tournamentId)
      .eq('fighter_id', fighterProfile.id)
      .single()

    if (existingParticipation) {
      return {
        error: 'Already joined this tournament',
      }
    }

    // Join tournament
    const { error } = await supabase
      .from('tournament_participants')
      .insert({
        tournament_id: tournamentId,
        fighter_id: fighterProfile.id,
        joined_at: new Date().toISOString(),
      })

    if (error) {
      logger.error('Tournament join failed', { userId: user.id, tournamentId, error: error.message })
      return {
        error: 'Failed to join tournament',
      }
    }

    // Update tournament participant count
    await supabase.rpc('increment_tournament_participants', {
      tournament_id: tournamentId
    })

    logger.info('Tournament joined successfully', { 
      userId: user.id, 
      tournamentId,
      fighterId: fighterProfile.id 
    })
    
    return {
      success: true,
      message: 'Successfully joined tournament',
    }
  } catch (error) {
    logger.error('Tournament join error', { userId: user.id, tournamentId, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getTournaments(status?: string, weightClass?: string) {
  const supabase = createClient()
  
  try {
    let query = supabase
      .from('tournaments')
      .select(`
        *,
        creator:profiles!tournaments_created_by_fkey(full_name)
      `)
      .order('created_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    if (weightClass) {
      query = query.eq('weight_class', weightClass)
    }

    const { data, error } = await query

    if (error) {
      logger.error('Failed to fetch tournaments', { error: error.message })
      return {
        error: 'Failed to fetch tournaments',
      }
    }

    return {
      success: true,
      tournaments: data || [],
    }
  } catch (error) {
    logger.error('Tournaments fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getTournamentDetails(tournamentId: string) {
  const supabase = createClient()
  
  try {
    const { data: tournament, error: tournamentError } = await supabase
      .from('tournaments')
      .select(`
        *,
        creator:profiles!tournaments_created_by_fkey(full_name)
      `)
      .eq('id', tournamentId)
      .single()

    if (tournamentError) {
      logger.error('Failed to fetch tournament details', { tournamentId, error: tournamentError.message })
      return {
        error: 'Failed to fetch tournament details',
      }
    }

    const { data: participants, error: participantsError } = await supabase
      .from('tournament_participants')
      .select(`
        *,
        fighter:fighter_profiles!tournament_participants_fighter_id_fkey(name, handle, wins, losses, points)
      `)
      .eq('tournament_id', tournamentId)
      .order('joined_at', { ascending: true })

    if (participantsError) {
      logger.error('Failed to fetch tournament participants', { tournamentId, error: participantsError.message })
      return {
        error: 'Failed to fetch tournament participants',
      }
    }

    return {
      success: true,
      tournament,
      participants: participants || [],
    }
  } catch (error) {
    logger.error('Tournament details error', { tournamentId, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}