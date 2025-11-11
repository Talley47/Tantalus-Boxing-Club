import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})

// Create different rate limiters for different use cases
export const rateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '1 m'),
})

export const authRateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(5, '15 m'),
})

export const uploadRateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(5, '1 m'),
})

export const adminRateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(50, '1 m'),
})

export const RATE_LIMITS = {
  API: {
    windowMs: 60 * 1000, // 1 minute
    max: 100, // 100 requests per minute
  },
  AUTH: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 auth attempts per 15 minutes
  },
  UPLOAD: {
    windowMs: 60 * 1000, // 1 minute
    max: 5, // 5 uploads per minute
  },
  ADMIN: {
    windowMs: 60 * 1000, // 1 minute
    max: 50, // 50 admin actions per minute
  },
  MATCHMAKING: {
    windowMs: 60 * 1000, // 1 minute
    max: 10, // 10 matchmaking requests per minute
  },
  TOURNAMENT: {
    windowMs: 60 * 1000, // 1 minute
    max: 3, // 3 tournament actions per minute
  },
}

// Enhanced rate limiting function with different limits
export async function rateLimit({
  identifier,
  windowMs,
  max,
}: {
  identifier: string
  windowMs: number
  max: number
}) {
  const { success, limit, reset, remaining } = await rateLimit.limit(identifier)
  
  return {
    success,
    limit,
    reset,
    remaining,
    retryAfter: success ? 0 : Math.ceil((reset - Date.now()) / 1000),
  }
}

