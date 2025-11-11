'use server'

import { createClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'
import { rateLimit, RATE_LIMITS } from '@/lib/rate-limit'
import { headers } from 'next/headers'

export async function createTrainingCamp(formData: FormData) {
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
    identifier: `training_camp:${user.id}`,
  })

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for training camp creation', { userId: user.id, ip })
    return {
      error: 'Too many requests. Please try again later.',
    }
  }

  const name = formData.get('name') as string
  const description = formData.get('description') as string
  const startDate = formData.get('startDate') as string
  const endDate = formData.get('endDate') as string
  const location = formData.get('location') as string
  const maxParticipants = parseInt(formData.get('maxParticipants') as string)

  try {
    const { data, error } = await supabase
      .from('training_camps')
      .insert({
        name,
        description: description || null,
        start_date: startDate,
        end_date: endDate,
        location,
        max_participants: maxParticipants,
        current_participants: 0,
        created_by: user.id,
        status: 'upcoming',
      })
      .select()
      .single()

    if (error) {
      logger.error('Training camp creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create training camp',
      }
    }

    logger.info('Training camp created successfully', { 
      userId: user.id, 
      campId: data.id,
      name 
    })
    
    return {
      success: true,
      message: 'Training camp created successfully',
      camp: data,
    }
  } catch (error) {
    logger.error('Training camp creation error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function joinTrainingCamp(campId: string) {
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
      .from('training_camp_participants')
      .select('id')
      .eq('camp_id', campId)
      .eq('fighter_id', fighterProfile.id)
      .single()

    if (existingParticipation) {
      return {
        error: 'Already joined this training camp',
      }
    }

    // Join training camp
    const { error } = await supabase
      .from('training_camp_participants')
      .insert({
        camp_id: campId,
        fighter_id: fighterProfile.id,
        joined_at: new Date().toISOString(),
      })

    if (error) {
      logger.error('Training camp join failed', { userId: user.id, campId, error: error.message })
      return {
        error: 'Failed to join training camp',
      }
    }

    // Update camp participant count
    await supabase.rpc('increment_training_camp_participants', {
      camp_id: campId
    })

    logger.info('Training camp joined successfully', { 
      userId: user.id, 
      campId,
      fighterId: fighterProfile.id 
    })
    
    return {
      success: true,
      message: 'Successfully joined training camp',
    }
  } catch (error) {
    logger.error('Training camp join error', { userId: user.id, campId, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function createTrainingObjective(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  const campId = formData.get('campId') as string
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const targetDate = formData.get('targetDate') as string

  try {
    const { data, error } = await supabase
      .from('training_objectives')
      .insert({
        camp_id: campId,
        title,
        description: description || null,
        target_date: targetDate,
        status: 'pending',
      })
      .select()
      .single()

    if (error) {
      logger.error('Training objective creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create training objective',
      }
    }

    logger.info('Training objective created successfully', { 
      userId: user.id, 
      objectiveId: data.id,
      title 
    })
    
    return {
      success: true,
      message: 'Training objective created successfully',
      objective: data,
    }
  } catch (error) {
    logger.error('Training objective creation error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function logTraining(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

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

  const campId = formData.get('campId') as string
  const objectiveId = formData.get('objectiveId') as string
  const activity = formData.get('activity') as string
  const durationMinutes = parseInt(formData.get('durationMinutes') as string)
  const notes = formData.get('notes') as string
  const date = formData.get('date') as string

  try {
    const { data, error } = await supabase
      .from('training_logs')
      .insert({
        fighter_id: fighterProfile.id,
        camp_id: campId || null,
        objective_id: objectiveId || null,
        activity,
        duration_minutes: durationMinutes,
        notes: notes || null,
        date,
      })
      .select()
      .single()

    if (error) {
      logger.error('Training log creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to log training',
      }
    }

    logger.info('Training logged successfully', { 
      userId: user.id, 
      logId: data.id,
      activity 
    })
    
    return {
      success: true,
      message: 'Training logged successfully',
      log: data,
    }
  } catch (error) {
    logger.error('Training log error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getTrainingCamps() {
  const supabase = createClient()
  
  try {
    const { data, error } = await supabase
      .from('training_camps')
      .select(`
        *,
        creator:profiles!training_camps_created_by_fkey(full_name)
      `)
      .order('created_at', { ascending: false })

    if (error) {
      logger.error('Failed to fetch training camps', { error: error.message })
      return {
        error: 'Failed to fetch training camps',
      }
    }

    return {
      success: true,
      camps: data || [],
    }
  } catch (error) {
    logger.error('Training camps fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

