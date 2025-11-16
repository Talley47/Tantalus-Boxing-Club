'use server'

import { createClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'
import { authRateLimit } from '@/lib/rate-limit'
import { headers } from 'next/headers'
import { loginSchema, registerSchema, fighterProfileSchema } from '@/lib/validations/auth'
import { z } from 'zod'

export async function signIn(formData: FormData) {
  const supabase = createClient()
  
  // Validate input
  const rawData = {
    email: formData.get('email') as string,
    password: formData.get('password') as string,
  }

  const validationResult = loginSchema.safeParse(rawData)
  if (!validationResult.success) {
    return {
      error: validationResult.error.errors[0].message,
    }
  }

  const { email, password } = validationResult.data

  // Rate limiting
  const headersList = headers()
  const ip = headersList.get('x-forwarded-for') || 'unknown'
  
  const rateLimitResult = await authRateLimit.limit(`auth:${ip}`)

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for auth', { ip })
    return {
      error: 'Too many login attempts. Please try again later.',
    }
  }

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    logger.error('Sign in failed', { email, error: error.message })
    return {
      error: 'Invalid credentials',
    }
  }

  logger.info('User signed in successfully', { email })
  
  return {
    success: true,
    message: 'Signed in successfully',
  }
}

export async function signUp(formData: FormData) {
  const supabase = createClient()
  
  // Validate registration data
  const rawData = {
    fullName: formData.get('fullName') as string,
    email: formData.get('email') as string,
    password: formData.get('password') as string,
    confirmPassword: formData.get('confirmPassword') as string,
  }

  const validationResult = registerSchema.safeParse(rawData)
  if (!validationResult.success) {
    return {
      error: validationResult.error.errors[0].message,
    }
  }

  const { fullName, email, password } = validationResult.data

  // Rate limiting
  const headersList = headers()
  const ip = headersList.get('x-forwarded-for') || 'unknown'
  
  const rateLimitResult = await authRateLimit.limit(`auth:${ip}`)

  if (!rateLimitResult.success) {
    logger.warn('Rate limit exceeded for auth', { ip })
    return {
      error: 'Too many registration attempts. Please try again later.',
    }
  }

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
        role: 'fighter' // Add role to user metadata
      },
    },
  })

  if (error) {
    logger.error('Sign up failed', { email, error: error.message })
    return {
      error: 'Failed to create account',
    }
  }

  logger.info('User signed up successfully', { email, userId: data.user?.id })
  
  return {
    success: true,
    message: 'Account created successfully',
    user: data.user,
  }
}

export async function createFighterProfile(formData: FormData) {
  const supabase = createClient()
  
  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return {
      error: 'Not authenticated',
    }
  }

  // Validate fighter profile data
  const rawData = {
    name: formData.get('name') as string,
    handle: formData.get('handle') as string,
    birthday: formData.get('birthday') as string,
    hometown: formData.get('hometown') as string,
    stance: formData.get('stance') as string,
    heightFeet: parseInt(formData.get('heightFeet') as string),
    heightInches: parseInt(formData.get('heightInches') as string),
    reach: parseInt(formData.get('reach') as string),
    weight: parseInt(formData.get('weight') as string),
    weightClass: formData.get('weightClass') as string,
    trainer: formData.get('trainer') as string || undefined,
    gym: formData.get('gym') as string || undefined,
  }

  const validationResult = fighterProfileSchema.safeParse(rawData)
  if (!validationResult.success) {
    return {
      error: validationResult.error.errors[0].message,
    }
  }

  const profileData = validationResult.data

  try {
    // Check if fighter profile already exists
    const { data: existingProfile } = await supabase
      .from('fighter_profiles')
      .select('id')
      .eq('user_id', user.id)
      .single()

    if (existingProfile) {
      return {
        error: 'Fighter profile already exists',
      }
    }

    // Create fighter profile
    const { data, error } = await supabase
      .from('fighter_profiles')
      .insert({
        user_id: user.id,
        name: profileData.name,
        handle: profileData.handle,
        birthday: profileData.birthday,
        hometown: profileData.hometown,
        stance: profileData.stance,
        height_feet: profileData.heightFeet,
        height_inches: profileData.heightInches,
        reach: profileData.reach,
        weight: profileData.weight,
        weight_class: profileData.weightClass,
        trainer: profileData.trainer,
        gym: profileData.gym,
        tier: 'amateur',
        points: 0,
        wins: 0,
        losses: 0,
        draws: 0,
      })
      .select()
      .single()

    if (error) {
      logger.error('Fighter profile creation failed', { userId: user.id, error: error.message })
      return {
        error: 'Failed to create fighter profile',
      }
    }

    logger.info('Fighter profile created successfully', { 
      userId: user.id, 
      profileId: data.id,
      name: profileData.name 
    })
    
    return {
      success: true,
      message: 'Fighter profile created successfully',
      profile: data,
    }
  } catch (error) {
    logger.error('Fighter profile creation error', { userId: user.id, error })
    return {
      error: 'An unexpected error occurred',
    }
  }
}

export async function signOut() {
  const supabase = createClient()
  
  const { error } = await supabase.auth.signOut()

  if (error) {
    logger.error('Sign out failed', { error: error.message })
    return {
      error: 'Failed to sign out',
    }
  }

  logger.info('User signed out successfully')
  
  return {
    success: true,
    message: 'Signed out successfully',
  }
}

