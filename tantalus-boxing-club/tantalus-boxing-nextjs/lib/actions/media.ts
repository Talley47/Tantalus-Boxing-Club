'use server'

import { createClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'
import { rateLimit, RATE_LIMITS } from '@/lib/rate-limit'
import { headers } from 'next/headers'

export async function uploadMediaAsset(formData: FormData) {
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
    ...RATE_LIMITS.UPLOAD,
    identifier: `media_upload:${user.id}`,
  })

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for media upload', { userId: user.id, ip })
    return {
      error: 'Too many uploads. Please try again later.',
    }
  }

  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const category = formData.get('category') as string
  const file = formData.get('file') as File

  if (!file) {
    return {
      error: 'No file provided',
    }
  }

  try {
    // Upload file to Supabase Storage
    const fileExt = file.name.split('.').pop()
    const fileName = `${user.id}/${Date.now()}.${fileExt}`
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('media-assets')
      .upload(fileName, file)

    if (uploadError) {
      logger.error('Media upload failed', { userId: user.id, error: uploadError.message })
      return {
        error: 'Failed to upload file',
      }
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('media-assets')
      .getPublicUrl(fileName)

    // Save media asset record
    const { data, error } = await supabase
      .from('media_assets')
      .insert({
        user_id: user.id,
        title,
        description: description || null,
        file_url: urlData.publicUrl,
        file_type: file.type.startsWith('video/') ? 'video' : 'image',
        category: category as 'highlight' | 'training' | 'interview' | 'promo',
      })
      .select()
      .single()

    if (error) {
      logger.error('Media asset creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to save media asset',
      }
    }

    logger.info('Media asset uploaded successfully', { 
      userId: user.id, 
      assetId: data.id,
      fileName: file.name 
    })
    
    return {
      success: true,
      message: 'Media asset uploaded successfully',
      asset: data,
    }
  } catch (error) {
    logger.error('Media upload error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getMediaAssets(category?: string) {
  const supabase = createClient()
  
  try {
    let query = supabase
      .from('media_assets')
      .select(`
        *,
        user:profiles!media_assets_user_id_fkey(full_name)
      `)
      .order('created_at', { ascending: false })

    if (category) {
      query = query.eq('category', category)
    }

    const { data, error } = await query

    if (error) {
      logger.error('Failed to fetch media assets', { error: error.message })
      return {
        error: 'Failed to fetch media assets',
      }
    }

    return {
      success: true,
      assets: data || [],
    }
  } catch (error) {
    logger.error('Media assets fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function scheduleInterview(formData: FormData) {
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

  const interviewer = formData.get('interviewer') as string
  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const scheduledDate = formData.get('scheduledDate') as string
  const durationMinutes = parseInt(formData.get('durationMinutes') as string)

  try {
    const { data, error } = await supabase
      .from('interviews')
      .insert({
        fighter_id: fighterProfile.id,
        interviewer,
        title,
        description: description || null,
        scheduled_date: scheduledDate,
        duration_minutes: durationMinutes,
        status: 'scheduled',
      })
      .select()
      .single()

    if (error) {
      logger.error('Interview scheduling failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to schedule interview',
      }
    }

    logger.info('Interview scheduled successfully', { 
      userId: user.id, 
      interviewId: data.id,
      interviewer 
    })
    
    return {
      success: true,
      message: 'Interview scheduled successfully',
      interview: data,
    }
  } catch (error) {
    logger.error('Interview scheduling error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getInterviews() {
  const supabase = createClient()
  
  try {
    const { data, error } = await supabase
      .from('interviews')
      .select(`
        *,
        fighter:fighter_profiles!interviews_fighter_id_fkey(name, handle)
      `)
      .order('scheduled_date', { ascending: true })

    if (error) {
      logger.error('Failed to fetch interviews', { error: error.message })
      return {
        error: 'Failed to fetch interviews',
      }
    }

    return {
      success: true,
      interviews: data || [],
    }
  } catch (error) {
    logger.error('Interviews fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

