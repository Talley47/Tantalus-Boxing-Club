'use server'

import { createClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'
import { rateLimit, RATE_LIMITS } from '@/lib/rate-limit'
import { headers } from 'next/headers'

export async function getUsers(page = 1, limit = 20, search = '') {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  // Check if user is admin (you'll need to implement this check)
  // For now, we'll allow access - implement proper admin check later

  try {
    let query = supabase
      .from('profiles')
      .select(`
        *,
        fighter_profile:fighter_profiles(*)
      `)
      .order('created_at', { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    if (search) {
      query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%`)
    }

    const { data: users, error } = await query

    if (error) {
      logger.error('Failed to fetch users', { error: error.message })
      return {
        error: 'Failed to fetch users',
      }
    }

    // Get total count
    const { count } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })

    return {
      success: true,
      users: users || [],
      total: count || 0,
      page,
      limit,
    }
  } catch (error) {
    logger.error('Users fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function updateUserRole(userId: string, role: string) {
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
    identifier: `admin_action:${user.id}`,
  })

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for admin action', { userId: user.id, ip })
    return {
      error: 'Too many requests. Please try again later.',
    }
  }

  try {
    const { error } = await supabase
      .from('profiles')
      .update({ role })
      .eq('id', userId)

    if (error) {
      logger.error('Failed to update user role', { userId, role, error: error.message })
      return {
        error: 'Failed to update user role',
      }
    }

    logger.info('User role updated successfully', { 
      adminId: user.id, 
      targetUserId: userId, 
      newRole: role 
    })
    
    return {
      success: true,
      message: 'User role updated successfully',
    }
  } catch (error) {
    logger.error('User role update error', { userId, role, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function suspendUser(userId: string, reason: string, duration?: number) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  try {
    const suspensionData = {
      user_id: userId,
      reason,
      suspended_by: user.id,
      suspended_at: new Date().toISOString(),
      status: 'active',
    }

    if (duration) {
      const expiresAt = new Date()
      expiresAt.setDate(expiresAt.getDate() + duration)
      suspensionData.expires_at = expiresAt.toISOString()
    }

    const { error } = await supabase
      .from('user_suspensions')
      .insert(suspensionData)

    if (error) {
      logger.error('Failed to suspend user', { userId, reason, error: error.message })
      return {
        error: 'Failed to suspend user',
      }
    }

    logger.info('User suspended successfully', { 
      adminId: user.id, 
      targetUserId: userId, 
      reason 
    })
    
    return {
      success: true,
      message: 'User suspended successfully',
    }
  } catch (error) {
    logger.error('User suspension error', { userId, reason, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function createDispute(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  const title = formData.get('title') as string
  const description = formData.get('description') as string
  const category = formData.get('category') as string
  const relatedFightId = formData.get('relatedFightId') as string

  try {
    const { data, error } = await supabase
      .from('disputes')
      .insert({
        user_id: user.id,
        title,
        description,
        category: category as 'fight_result' | 'points' | 'behavior' | 'technical' | 'other',
        related_fight_id: relatedFightId || null,
        status: 'pending',
      })
      .select()
      .single()

    if (error) {
      logger.error('Dispute creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create dispute',
      }
    }

    logger.info('Dispute created successfully', { 
      userId: user.id, 
      disputeId: data.id,
      title 
    })
    
    return {
      success: true,
      message: 'Dispute created successfully',
      dispute: data,
    }
  } catch (error) {
    logger.error('Dispute creation error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getDisputes(status?: string) {
  const supabase = createClient()
  
  try {
    let query = supabase
      .from('disputes')
      .select(`
        *,
        user:profiles!disputes_user_id_fkey(full_name, email),
        fight:fight_records!disputes_related_fight_id_fkey(opponent_name, result, date)
      `)
      .order('created_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    const { data, error } = await query

    if (error) {
      logger.error('Failed to fetch disputes', { error: error.message })
      return {
        error: 'Failed to fetch disputes',
      }
    }

    return {
      success: true,
      disputes: data || [],
    }
  } catch (error) {
    logger.error('Disputes fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function resolveDispute(disputeId: string, resolution: string, adminNotes?: string) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  try {
    const { error } = await supabase
      .from('disputes')
      .update({
        status: 'resolved',
        resolution,
        admin_notes: adminNotes || null,
        resolved_by: user.id,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', disputeId)

    if (error) {
      logger.error('Failed to resolve dispute', { disputeId, error: error.message })
      return {
        error: 'Failed to resolve dispute',
      }
    }

    logger.info('Dispute resolved successfully', { 
      adminId: user.id, 
      disputeId,
      resolution 
    })
    
    return {
      success: true,
      message: 'Dispute resolved successfully',
    }
  } catch (error) {
    logger.error('Dispute resolution error', { disputeId, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function getSystemStats() {
  const supabase = createClient()
  
  try {
    // Get total users
    const { count: totalUsers } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })

    // Get total fighters
    const { count: totalFighters } = await supabase
      .from('fighter_profiles')
      .select('*', { count: 'exact', head: true })

    // Get total fights
    const { count: totalFights } = await supabase
      .from('fight_records')
      .select('*', { count: 'exact', head: true })

    // Get total tournaments
    const { count: totalTournaments } = await supabase
      .from('tournaments')
      .select('*', { count: 'exact', head: true })

    // Get pending disputes
    const { count: pendingDisputes } = await supabase
      .from('disputes')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending')

    // Get recent activity (last 7 days)
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

    const { count: recentUsers } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', sevenDaysAgo.toISOString())

    const { count: recentFights } = await supabase
      .from('fight_records')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', sevenDaysAgo.toISOString())

    return {
      success: true,
      stats: {
        totalUsers: totalUsers || 0,
        totalFighters: totalFighters || 0,
        totalFights: totalFights || 0,
        totalTournaments: totalTournaments || 0,
        pendingDisputes: pendingDisputes || 0,
        recentUsers: recentUsers || 0,
        recentFights: recentFights || 0,
      }
    }
  } catch (error) {
    logger.error('System stats fetch error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function updateSystemSettings(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  const maintenanceMode = formData.get('maintenanceMode') === 'true'
  const registrationEnabled = formData.get('registrationEnabled') === 'true'
  const maxFightersPerTournament = parseInt(formData.get('maxFightersPerTournament') as string)
  const pointsPerWin = parseInt(formData.get('pointsPerWin') as string)

  try {
    const { error } = await supabase
      .from('system_settings')
      .upsert({
        id: 'main',
        maintenance_mode: maintenanceMode,
        registration_enabled: registrationEnabled,
        max_fighters_per_tournament: maxFightersPerTournament,
        points_per_win: pointsPerWin,
        updated_by: user.id,
        updated_at: new Date().toISOString(),
      })

    if (error) {
      logger.error('Failed to update system settings', { error: error.message })
      return {
        error: 'Failed to update system settings',
      }
    }

    logger.info('System settings updated successfully', { 
      adminId: user.id,
      maintenanceMode,
      registrationEnabled 
    })
    
    return {
      success: true,
      message: 'System settings updated successfully',
    }
  } catch (error) {
    logger.error('System settings update error', { error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

