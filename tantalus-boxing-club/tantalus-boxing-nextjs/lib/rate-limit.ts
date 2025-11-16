import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

// Check if Redis credentials are available
const redisUrl = process.env.UPSTASH_REDIS_REST_URL
const redisToken = process.env.UPSTASH_REDIS_REST_TOKEN

// Create Redis instance only if credentials are available
let redis: Redis | null = null
let rateLimitingEnabled = false

if (redisUrl && redisToken) {
  try {
    redis = new Redis({
      url: redisUrl,
      token: redisToken,
    })
    rateLimitingEnabled = true
  } catch (error) {
    console.warn('Failed to initialize Redis for rate limiting:', error)
    rateLimitingEnabled = false
  }
} else {
  console.warn(
    'Upstash Redis not configured. Rate limiting is disabled. Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN to enable.'
  )
}

// Fallback rate limiter that always allows requests
const createFallbackLimiter = () => ({
  limit: async (identifier: string) => ({
    success: true,
    limit: 1000,
    remaining: 999,
    reset: Date.now() + 60000,
  }),
})

// Create rate limiters with fallback if Redis is not available
const createRateLimiter = (limiter: Ratelimit['limiter']) => {
  if (rateLimitingEnabled && redis) {
    return new Ratelimit({
      redis,
      limiter,
    })
  }
  return createFallbackLimiter()
}

// Create different rate limiters for different use cases
export const rateLimit = createRateLimiter(Ratelimit.slidingWindow(10, '1 m'))

export const authRateLimit = createRateLimiter(Ratelimit.slidingWindow(5, '15 m'))

export const uploadRateLimit = createRateLimiter(Ratelimit.slidingWindow(5, '1 m'))

export const adminRateLimit = createRateLimiter(Ratelimit.slidingWindow(50, '1 m'))

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
} as const

// Check if rate limiting is enabled
export const isRateLimitingEnabled = () => rateLimitingEnabled

// Enhanced rate limiting function with different limits
export async function rateLimitRequest({
  identifier,
  windowMs,
  max,
}: {
  identifier: string
  windowMs: number
  max: number
}) {
  if (!rateLimitingEnabled) {
    // If rate limiting is disabled, allow the request
    return {
      success: true,
      limit: max,
      reset: Date.now() + windowMs,
      remaining: max - 1,
      retryAfter: 0,
    }
  }

  try {
    const result = await rateLimit.limit(identifier)
    return {
      success: result.success,
      limit: result.limit,
      reset: result.reset,
      remaining: result.remaining,
      retryAfter: result.success
        ? 0
        : Math.ceil((result.reset - Date.now()) / 1000),
    }
  } catch (error) {
    // If rate limiting fails, log error but allow request
    console.error('Rate limiting error:', error)
    return {
      success: true,
      limit: max,
      reset: Date.now() + windowMs,
      remaining: max - 1,
      retryAfter: 0,
    }
  }
}
