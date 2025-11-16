'use client'

import { PostHog } from 'posthog-js'

// Initialize PostHog (only if key is provided)
let posthog: PostHog | null = null

if (typeof window !== 'undefined' && process.env.NEXT_PUBLIC_POSTHOG_KEY) {
  try {
    // PostHog initialization - make it optional
    posthog = new PostHog()
    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY, {
      api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://app.posthog.com',
      person_profiles: 'identified_only',
      capture_pageview: false,
      capture_pageleave: true,
    })
  } catch (error) {
    console.warn('Failed to initialize PostHog:', error)
    posthog = null
  }
}

// Helper function to safely call PostHog
const safeCapture = (event: string, properties?: any) => {
  if (posthog) {
    try {
      posthog.capture(event, properties)
    } catch (error) {
      console.warn('PostHog capture failed:', error)
    }
  }
}

const safeIdentify = (userId: string, properties?: any) => {
  if (posthog) {
    try {
      posthog.identify(userId, properties)
    } catch (error) {
      console.warn('PostHog identify failed:', error)
    }
  }
}

// Analytics events
export const analytics = {
  // User events
  userRegistered: (userId: string, properties?: any) => {
    safeIdentify(userId, properties)
    safeCapture('user_registered', {
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  userLoggedIn: (userId: string, properties?: any) => {
    safeIdentify(userId, properties)
    safeCapture('user_logged_in', {
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  userLoggedOut: (userId: string) => {
    safeCapture('user_logged_out', {
      userId,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Fighter events
  fighterProfileCreated: (userId: string, fighterData: any) => {
    safeCapture('fighter_profile_created', {
      userId,
      fighterName: fighterData.name,
      weightClass: fighterData.weight_class,
      tier: fighterData.tier,
      timestamp: new Date().toISOString(),
    })
  },
  
  fightRecordAdded: (userId: string, fightData: any) => {
    safeCapture('fight_record_added', {
      userId,
      result: fightData.result,
      method: fightData.method,
      weightClass: fightData.weight_class,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Matchmaking events
  matchmakingRequestCreated: (userId: string, requestData: any) => {
    safeCapture('matchmaking_request_created', {
      userId,
      preferredWeightClass: requestData.preferred_weight_class,
      preferredTier: requestData.preferred_tier,
      timestamp: new Date().toISOString(),
    })
  },
  
  matchFound: (userId: string, matchData: any) => {
    safeCapture('match_found', {
      userId,
      opponentId: matchData.opponent_id,
      weightClass: matchData.weight_class,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Tournament events
  tournamentCreated: (userId: string, tournamentData: any) => {
    safeCapture('tournament_created', {
      userId,
      tournamentName: tournamentData.name,
      weightClass: tournamentData.weight_class,
      maxParticipants: tournamentData.max_participants,
      timestamp: new Date().toISOString(),
    })
  },
  
  tournamentJoined: (userId: string, tournamentId: string) => {
    safeCapture('tournament_joined', {
      userId,
      tournamentId,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Media events
  mediaUploaded: (userId: string, mediaData: any) => {
    safeCapture('media_uploaded', {
      userId,
      category: mediaData.category,
      fileType: mediaData.file_type,
      fileSize: mediaData.file_size,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Training events
  trainingCampJoined: (userId: string, campId: string) => {
    safeCapture('training_camp_joined', {
      userId,
      campId,
      timestamp: new Date().toISOString(),
    })
  },
  
  trainingLogged: (userId: string, trainingData: any) => {
    safeCapture('training_logged', {
      userId,
      activity: trainingData.activity,
      duration: trainingData.duration_minutes,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Admin events
  adminAction: (adminId: string, action: string, targetId?: string) => {
    safeCapture('admin_action', {
      adminId,
      action,
      targetId,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Dispute events
  disputeCreated: (userId: string, disputeData: any) => {
    safeCapture('dispute_created', {
      userId,
      category: disputeData.category,
      timestamp: new Date().toISOString(),
    })
  },
  
  disputeResolved: (adminId: string, disputeId: string, resolution: string) => {
    safeCapture('dispute_resolved', {
      adminId,
      disputeId,
      resolution,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Page views
  pageView: (page: string, properties?: any) => {
    safeCapture('$pageview', {
      page,
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Feature usage
  featureUsed: (userId: string, feature: string, properties?: any) => {
    safeCapture('feature_used', {
      userId,
      feature,
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Performance metrics
  performanceMetric: (metric: string, value: number, properties?: any) => {
    safeCapture('performance_metric', {
      metric,
      value,
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
}
