import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { logger } from '@/lib/logger'

export async function GET(request: NextRequest) {
  try {
    const startTime = Date.now()
    
    // Check database connection
    const supabase = await createClient()
    const { data, error } = await supabase
      .from('profiles')
      .select('count')
      .limit(1)
    
    const dbStatus = error ? 'error' : 'healthy'
    const dbLatency = Date.now() - startTime
    
    // Check environment variables
    const envStatus = {
      supabaseUrl: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
      supabaseAnonKey: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
      redisUrl: !!process.env.UPSTASH_REDIS_REST_URL,
      redisToken: !!process.env.UPSTASH_REDIS_REST_TOKEN,
    }
    
    const allEnvVarsPresent = Object.values(envStatus).every(Boolean)
    
    // Overall health status
    const isHealthy = dbStatus === 'healthy' && allEnvVarsPresent
    
    const healthData = {
      status: isHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
      environment: process.env.NODE_ENV,
      services: {
        database: {
          status: dbStatus,
          latency: `${dbLatency}ms`,
        },
        environment: {
          status: allEnvVarsPresent ? 'healthy' : 'unhealthy',
          variables: envStatus,
        },
      },
      uptime: process.uptime(),
      memory: process.memoryUsage(),
    }
    
    // Log health check
    logger.info('Health check performed', {
      status: healthData.status,
      dbLatency,
      allEnvVarsPresent,
    })
    
    return NextResponse.json(healthData, {
      status: isHealthy ? 200 : 503,
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    })
    
  } catch (error) {
    logger.error('Health check failed', { error })
    
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: 'Health check failed',
      },
      { status: 503 }
    )
  }
}

