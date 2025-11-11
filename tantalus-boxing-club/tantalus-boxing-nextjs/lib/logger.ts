import { createClient } from '@supabase/supabase-js'

// Enhanced logger with structured logging and external services
export const logger = {
  info: (message: string, meta?: any) => {
    const logEntry = {
      level: 'info',
      message,
      timestamp: new Date().toISOString(),
      meta,
      environment: process.env.NODE_ENV,
    }
    console.log(`[INFO] ${message}`, meta ? JSON.stringify(meta, null, 2) : '')
    
    // Send to external logging service in production
    if (process.env.NODE_ENV === 'production') {
      sendToLoggingService(logEntry)
    }
  },
  
  error: (message: string, meta?: any) => {
    const logEntry = {
      level: 'error',
      message,
      timestamp: new Date().toISOString(),
      meta,
      environment: process.env.NODE_ENV,
    }
    console.error(`[ERROR] ${message}`, meta ? JSON.stringify(meta, null, 2) : '')
    
    // Send to external logging service in production
    if (process.env.NODE_ENV === 'production') {
      sendToLoggingService(logEntry)
    }
  },
  
  warn: (message: string, meta?: any) => {
    const logEntry = {
      level: 'warn',
      message,
      timestamp: new Date().toISOString(),
      meta,
      environment: process.env.NODE_ENV,
    }
    console.warn(`[WARN] ${message}`, meta ? JSON.stringify(meta, null, 2) : '')
    
    // Send to external logging service in production
    if (process.env.NODE_ENV === 'production') {
      sendToLoggingService(logEntry)
    }
  },
  
  debug: (message: string, meta?: any) => {
    if (process.env.NODE_ENV === 'development') {
      const logEntry = {
        level: 'debug',
        message,
        timestamp: new Date().toISOString(),
        meta,
        environment: process.env.NODE_ENV,
      }
      console.debug(`[DEBUG] ${message}`, meta ? JSON.stringify(meta, null, 2) : '')
    }
  },
  
  // Security events
  security: (event: string, details: any) => {
    const logEntry = {
      level: 'security',
      message: `Security Event: ${event}`,
      timestamp: new Date().toISOString(),
      meta: details,
      environment: process.env.NODE_ENV,
    }
    console.warn(`[SECURITY] ${event}:`, details)
    
    // Always send security events to external service
    sendToLoggingService(logEntry)
  },
  
  // Performance metrics
  performance: (operation: string, duration: number, meta?: any) => {
    const logEntry = {
      level: 'performance',
      message: `Performance: ${operation}`,
      timestamp: new Date().toISOString(),
      meta: {
        operation,
        duration,
        ...meta,
      },
      environment: process.env.NODE_ENV,
    }
    console.log(`[PERF] ${operation}: ${duration}ms`, meta ? JSON.stringify(meta, null, 2) : '')
    
    // Send performance metrics to external service
    if (process.env.NODE_ENV === 'production') {
      sendToLoggingService(logEntry)
    }
  },
  
  // User actions
  userAction: (userId: string, action: string, details?: any) => {
    const logEntry = {
      level: 'user_action',
      message: `User Action: ${action}`,
      timestamp: new Date().toISOString(),
      meta: {
        userId,
        action,
        ...details,
      },
      environment: process.env.NODE_ENV,
    }
    console.log(`[USER] ${userId} - ${action}`, details ? JSON.stringify(details, null, 2) : '')
    
    // Send user actions to external service
    if (process.env.NODE_ENV === 'production') {
      sendToLoggingService(logEntry)
    }
  },
}

// Send logs to external service (Supabase, PostHog, etc.)
async function sendToLoggingService(logEntry: any) {
  try {
    // Send to Supabase for storage
    if (process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE) {
      const supabase = createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL,
        process.env.SUPABASE_SERVICE_ROLE
      )
      
      await supabase
        .from('application_logs')
        .insert({
          level: logEntry.level,
          message: logEntry.message,
          meta: logEntry.meta,
          environment: logEntry.environment,
          created_at: logEntry.timestamp,
        })
    }
  } catch (error) {
    console.error('Failed to send log to external service:', error)
  }
}

// Performance monitoring
export class PerformanceMonitor {
  private static timers: Map<string, number> = new Map()
  
  static start(operation: string): void {
    this.timers.set(operation, Date.now())
  }
  
  static end(operation: string, meta?: any): number {
    const startTime = this.timers.get(operation)
    if (!startTime) {
      logger.warn(`Performance timer not found for operation: ${operation}`)
      return 0
    }
    
    const duration = Date.now() - startTime
    this.timers.delete(operation)
    
    logger.performance(operation, duration, meta)
    return duration
  }
  
  static async measure<T>(operation: string, fn: () => Promise<T>, meta?: any): Promise<T> {
    this.start(operation)
    try {
      const result = await fn()
      this.end(operation, meta)
      return result
    } catch (error) {
      this.end(operation, { ...meta, error: error instanceof Error ? error.message : 'Unknown error' })
      throw error
    }
  }
}

// Error tracking
export function trackError(error: Error, context?: any) {
  logger.error('Application Error', {
    message: error.message,
    stack: error.stack,
    context,
  })
  
  // Send to Sentry if available
  if (typeof window !== 'undefined' && (window as any).Sentry) {
    (window as any).Sentry.captureException(error, { extra: context })
  }
}

// User analytics
export function trackUserEvent(event: string, properties?: any) {
  logger.userAction('anonymous', event, properties)
  
  // Send to PostHog if available
  if (typeof window !== 'undefined' && (window as any).posthog) {
    (window as any).posthog.capture(event, properties)
  }
}

