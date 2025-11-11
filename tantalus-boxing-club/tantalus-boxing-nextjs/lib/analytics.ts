'use client'

import { PostHog } from 'posthog-js'

// Initialize PostHog
export const posthog = new PostHog(
  process.env.NEXT_PUBLIC_POSTHOG_KEY!,
  {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://app.posthog.com',
    person_profiles: 'identified_only',
    capture_pageview: false,
    capture_pageleave: true,
  }
)

// Analytics events
export const analytics = {
  // User events
  userRegistered: (userId: string, properties?: any) => {
    posthog.identify(userId, properties)
    posthog.capture('user_registered', {
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  userLoggedIn: (userId: string, properties?: any) => {
    posthog.identify(userId, properties)
    posthog.capture('user_logged_in', {
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  userLoggedOut: (userId: string) => {
    posthog.capture('user_logged_out', {
      userId,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Fighter events
  fighterProfileCreated: (userId: string, fighterData: any) => {
    posthog.capture('fighter_profile_created', {
      userId,
      fighterName: fighterData.name,
      weightClass: fighterData.weight_class,
      tier: fighterData.tier,
      timestamp: new Date().toISOString(),
    })
  },
  
  fightRecordAdded: (userId: string, fightData: any) => {
    posthog.capture('fight_record_added', {
      userId,
      result: fightData.result,
      method: fightData.method,
      weightClass: fightData.weight_class,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Matchmaking events
  matchmakingRequestCreated: (userId: string, requestData: any) => {
    posthog.capture('matchmaking_request_created', {
      userId,
      preferredWeightClass: requestData.preferred_weight_class,
      preferredTier: requestData.preferred_tier,
      timestamp: new Date().toISOString(),
    })
  },
  
  matchFound: (userId: string, matchData: any) => {
    posthog.capture('match_found', {
      userId,
      opponentId: matchData.opponent_id,
      weightClass: matchData.weight_class,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Tournament events
  tournamentCreated: (userId: string, tournamentData: any) => {
    posthog.capture('tournament_created', {
      userId,
      tournamentName: tournamentData.name,
      weightClass: tournamentData.weight_class,
      maxParticipants: tournamentData.max_participants,
      timestamp: new Date().toISOString(),
    })
  },
  
  tournamentJoined: (userId: string, tournamentId: string) => {
    posthog.capture('tournament_joined', {
      userId,
      tournamentId,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Media events
  mediaUploaded: (userId: string, mediaData: any) => {
    posthog.capture('media_uploaded', {
      userId,
      category: mediaData.category,
      fileType: mediaData.file_type,
      fileSize: mediaData.file_size,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Training events
  trainingCampJoined: (userId: string, campId: string) => {
    posthog.capture('training_camp_joined', {
      userId,
      campId,
      timestamp: new Date().toISOString(),
    })
  },
  
  trainingLogged: (userId: string, trainingData: any) => {
    posthog.capture('training_logged', {
      userId,
      activity: trainingData.activity,
      duration: trainingData.duration_minutes,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Admin events
  adminAction: (adminId: string, action: string, targetId?: string) => {
    posthog.capture('admin_action', {
      adminId,
      action,
      targetId,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Dispute events
  disputeCreated: (userId: string, disputeData: any) => {
    posthog.capture('dispute_created', {
      userId,
      category: disputeData.category,
      timestamp: new Date().toISOString(),
    })
  },
  
  disputeResolved: (adminId: string, disputeId: string, resolution: string) => {
    posthog.capture('dispute_resolved', {
      adminId,
      disputeId,
      resolution,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Page views
  pageView: (page: string, properties?: any) => {
    posthog.capture('$pageview', {
      page,
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Feature usage
  featureUsed: (userId: string, feature: string, properties?: any) => {
    posthog.capture('feature_used', {
      userId,
      feature,
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
  
  // Performance metrics
  performanceMetric: (metric: string, value: number, properties?: any) => {
    posthog.capture('performance_metric', {
      metric,
      value,
      ...properties,
      timestamp: new Date().toISOString(),
    })
  },
}

// Initialize PostHog on page load
if (typeof window !== 'undefined') {
  posthog.init()
}

